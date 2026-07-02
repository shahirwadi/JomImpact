const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const Stripe = require("stripe");

initializeApp();

const db = getFirestore();
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const region = "asia-southeast1";

function stripeClient() {
  return new Stripe(stripeSecretKey.value());
}

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in before paying.");
  }
  return request.auth.uid;
}

function requiredText(data, field, maxLength = 500) {
  const value = typeof data[field] === "string" ? data[field].trim() : "";
  if (!value || value.length > maxLength) {
    throw new HttpsError("invalid-argument", `Invalid ${field}.`);
  }
  return value;
}

exports.createStripePaymentIntent = onCall(
  {region, secrets: [stripeSecretKey]},
  async (request) => {
    const buyerId = requireAuth(request);
    const itemId = requiredText(request.data || {}, "itemId", 160);
    const itemSnapshot = await db.collection("marketplaceItems").doc(itemId).get();
    if (!itemSnapshot.exists) {
      throw new HttpsError("not-found", "This listing no longer exists.");
    }

    const item = itemSnapshot.data();
    const quantity = Number.isInteger(item.quantity) ? item.quantity : 1;
    if (item.status !== "approved" || item.isAvailable === false || quantity < 1) {
      throw new HttpsError("failed-precondition", "This item is out of stock.");
    }

    const amount = Math.round(Number(item.price) * 100);
    if (!Number.isSafeInteger(amount) || amount < 50) {
      throw new HttpsError("failed-precondition", "This listing has an invalid price.");
    }

    const intent = await stripeClient().paymentIntents.create({
      amount,
      currency: "myr",
      automatic_payment_methods: {enabled: true},
      metadata: {
        app: "jomimpact",
        buyerId,
        itemId,
      },
    });

    return {
      clientSecret: intent.client_secret,
      paymentIntentId: intent.id,
    };
  },
);

exports.finalizeStripeOrder = onCall(
  {region, secrets: [stripeSecretKey]},
  async (request) => {
    const buyerId = requireAuth(request);
    const data = request.data || {};
    const paymentIntentId = requiredText(data, "paymentIntentId", 255);
    const stripe = stripeClient();
    const intent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (intent.status !== "succeeded" || intent.metadata.buyerId !== buyerId) {
      throw new HttpsError("failed-precondition", "Stripe payment is not confirmed.");
    }

    const itemId = intent.metadata.itemId;
    if (!itemId) {
      throw new HttpsError("failed-precondition", "Payment is missing its listing reference.");
    }

    const buyerSnapshot = await db.collection("users").doc(buyerId).get();
    if (!buyerSnapshot.exists) {
      throw new HttpsError("not-found", "Buyer profile was not found.");
    }
    const buyer = buyerSnapshot.data();
    const now = new Date().toISOString();
    const orderRef = db.collection("marketplacePurchases").doc(paymentIntentId);
    const itemRef = db.collection("marketplaceItems").doc(itemId);
    const orderInput = {
      recipientName: requiredText(data, "recipientName", 160),
      phone: requiredText(data, "phone", 60),
      addressLine1: requiredText(data, "addressLine1", 300),
      addressLine2: typeof data.addressLine2 === "string" ? data.addressLine2.trim() : null,
      city: requiredText(data, "city", 160),
      state: requiredText(data, "state", 160),
      postcode: requiredText(data, "postcode", 30),
      country: "Malaysia",
      deliveryInstructions: typeof data.deliveryInstructions === "string"
        ? data.deliveryInstructions.trim()
        : null,
    };

    try {
      return await db.runTransaction(async (transaction) => {
        const existing = await transaction.get(orderRef);
        if (existing.exists) return existing.data();

        const itemSnapshot = await transaction.get(itemRef);
        if (!itemSnapshot.exists) throw new Error("listing_unavailable");
        const item = itemSnapshot.data();
        const quantity = Number.isInteger(item.quantity) ? item.quantity : 1;
        const expectedAmount = Math.round(Number(item.price) * 100);
        if (
          item.status !== "approved" ||
          item.isAvailable === false ||
          quantity < 1 ||
          expectedAmount !== intent.amount_received
        ) {
          throw new Error("listing_unavailable");
        }

        const remaining = quantity - 1;
        const order = {
          id: paymentIntentId,
          itemId,
          itemTitle: item.title,
          organizerId: item.organizerId,
          buyerId,
          buyerName: buyer.name || "JomImpact buyer",
          buyerEmail: buyer.email || request.auth.token.email || "",
          ...orderInput,
          price: Number(item.price),
          status: "confirmed",
          paymentStatus: "paid",
          stripePaymentIntentId: paymentIntentId,
          createdAt: now,
          updatedAt: now,
        };

        transaction.update(itemRef, {
          quantity: remaining,
          isAvailable: remaining > 0,
        });
        transaction.create(orderRef, order);
        return order;
      });
    } catch (error) {
      if (error && error.message === "listing_unavailable") {
        await stripe.refunds.create(
          {payment_intent: paymentIntentId},
          {idempotencyKey: `jomimpact-unavailable-${paymentIntentId}`},
        );
        throw new HttpsError(
          "aborted",
          "The item became unavailable. Your Stripe payment was refunded.",
        );
      }
      throw error;
    }
  },
);
