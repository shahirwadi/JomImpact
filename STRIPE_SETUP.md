# Stripe test-mode setup without Firebase Blaze

Stripe payments need a trusted server because the secret key must never be
placed in the Flutter app. JomImpact uses a small Vercel API for this, while
Firebase Authentication and Firestore can remain on the free Spark plan.

## 1. Prepare Firebase credentials

In Firebase Console, open **Project settings > Service accounts**, generate a
new private key, and keep the downloaded JSON outside this repository. This
credential gives server access to Firestore and must remain private.

## 2. Deploy the free Vercel backend

1. Create/import a Vercel project and set its root directory to `backend`.
2. Add these Vercel environment variables:
   - `STRIPE_SECRET_KEY`: the Stripe test secret key (`sk_test_...`).
   - `FIREBASE_SERVICE_ACCOUNT_JSON`: the complete Firebase service-account
     JSON, entered as one environment-variable value.
3. Deploy. The payment endpoint will be:
   `https://YOUR-PROJECT.vercel.app/api`.

Vercel's free Hobby limits apply. No Firebase Cloud Functions are deployed and
the Firebase Blaze plan is not required.

## 3. Configure and run Flutter

Add these entries to the existing `env/dev.json`:

```json
{
  "STRIPE_PUBLISHABLE_KEY": "pk_test_replace_me",
  "STRIPE_BACKEND_URL": "https://YOUR-PROJECT.vercel.app/api"
}
```

Keep the existing Cloudinary values in that file. Then deploy only the
Firestore rules and run the app:

```powershell
firebase deploy --only firestore:rules --project jomimpactdb
flutter run -d emulator-5554 --dart-define-from-file=env/dev.json
```

Use Stripe's test card `4242 4242 4242 4242`, any future expiry, and any
three-digit CVC. Test mode does not move real money.
