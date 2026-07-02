const {cert, getApps, initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");
const Stripe = require("stripe");

class ClientError extends Error {
  constructor(message, status = 400) { super(message); this.status = status; }
}

function app() {
  if (getApps().length) return getApps()[0];
  const value = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!value) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is missing.");
  return initializeApp({credential: cert(JSON.parse(value))});
}

function text(data, field, max = 500) {
  const value = typeof data[field] === "string" ? data[field].trim() : "";
  if (!value || value.length > max) throw new ClientError(`Invalid ${field}.`);
  return value;
}

async function userFor(req) {
  const header = req.headers.authorization || "";
  if (!header.startsWith("Bearer ")) throw new ClientError("Sign in before paying.", 401);
  return getAuth(app()).verifyIdToken(header.slice(7));
}

async function createIntent(db, stripe, uid, data) {
  const itemId = text(data, "itemId", 160);
  const snap = await db.collection("marketplaceItems").doc(itemId).get();
  if (!snap.exists) throw new ClientError("This listing no longer exists.", 404);
  const item = snap.data();
  const quantity = Number.isInteger(item.quantity) ? item.quantity : 1;
  if (item.status !== "approved" || item.isAvailable === false || quantity < 1) {
    throw new ClientError("This item is out of stock.", 409);
  }
  const amount = Math.round(Number(item.price) * 100);
  if (!Number.isSafeInteger(amount) || amount < 50) {
    throw new ClientError("This listing has an invalid price.", 409);
  }
  const intent = await stripe.paymentIntents.create({
    amount, currency: "myr", automatic_payment_methods: {enabled: true},
    metadata: {app: "jomimpact", buyerId: uid, itemId},
  });
  return {clientSecret: intent.client_secret, paymentIntentId: intent.id};
}

async function finalize(db, stripe, user, data) {
  const paymentIntentId = text(data, "paymentIntentId", 255);
  const intent = await stripe.paymentIntents.retrieve(paymentIntentId);
  if (intent.status !== "succeeded" || intent.metadata.buyerId !== user.uid) {
    throw new ClientError("Stripe payment is not confirmed.", 409);
  }
  const itemId = intent.metadata.itemId;
  const buyerSnap = await db.collection("users").doc(user.uid).get();
  if (!itemId || !buyerSnap.exists) throw new ClientError("Payment details were not found.", 404);
  const buyer = buyerSnap.data();
  const itemRef = db.collection("marketplaceItems").doc(itemId);
  const orderRef = db.collection("marketplacePurchases").doc(paymentIntentId);
  const now = new Date().toISOString();
  const shipping = {
    recipientName: text(data, "recipientName", 160),
    phone: text(data, "phone", 60),
    addressLine1: text(data, "addressLine1", 300),
    addressLine2: typeof data.addressLine2 === "string" ? data.addressLine2.trim() : null,
    city: text(data, "city", 160), state: text(data, "state", 160),
    postcode: text(data, "postcode", 30), country: "Malaysia",
    deliveryInstructions: typeof data.deliveryInstructions === "string"
      ? data.deliveryInstructions.trim() : null,
  };
  try {
    return await db.runTransaction(async (tx) => {
      const existing = await tx.get(orderRef);
      if (existing.exists) return existing.data();
      const snap = await tx.get(itemRef);
      if (!snap.exists) throw new Error("unavailable");
      const item = snap.data();
      const quantity = Number.isInteger(item.quantity) ? item.quantity : 1;
      if (item.status !== "approved" || item.isAvailable === false || quantity < 1 ||
          Math.round(Number(item.price) * 100) !== intent.amount_received) {
        throw new Error("unavailable");
      }
      const remaining = quantity - 1;
      const order = {
        id: paymentIntentId, itemId, itemTitle: item.title,
        organizerId: item.organizerId, buyerId: user.uid,
        buyerName: buyer.name || "JomImpact buyer", buyerEmail: buyer.email || user.email || "",
        ...shipping, price: Number(item.price), status: "confirmed", paymentStatus: "paid",
        stripePaymentIntentId: paymentIntentId, createdAt: now, updatedAt: now,
      };
      tx.update(itemRef, {quantity: remaining, isAvailable: remaining > 0});
      tx.create(orderRef, order);
      return order;
    });
  } catch (error) {
    if (error.message === "unavailable") {
      await stripe.refunds.create(
        {payment_intent: paymentIntentId},
        {idempotencyKey: `jomimpact-unavailable-${paymentIntentId}`},
      );
      throw new ClientError("The item became unavailable. Your payment was refunded.", 409);
    }
    throw error;
  }
}

module.exports = async (req, res) => {
  if (req.method !== "POST") return res.status(405).json({error: "Method not allowed."});
  try {
    const user = await userFor(req);
    if (!process.env.STRIPE_SECRET_KEY) throw new Error("STRIPE_SECRET_KEY is missing.");
    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const db = getFirestore(app());
    const data = req.body || {};
    const result = data.action === "createPaymentIntent"
      ? await createIntent(db, stripe, user.uid, data)
      : data.action === "finalizeOrder"
        ? await finalize(db, stripe, user, data)
        : (() => { throw new ClientError("Invalid action."); })();
    return res.status(200).json(result);
  } catch (error) {
    console.error(error);
    return res.status(error.status || 500).json({
      error: error.status ? error.message : "Payment server error.",
    });
  }
};
