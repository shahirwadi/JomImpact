# Stripe test-mode setup

The app uses Stripe PaymentSheet and Firebase callable functions. Prices are
read from Firestore on the server. Orders and stock changes happen only after
Stripe reports a successful PaymentIntent.

## Required account setup

1. Enable the Firebase Blaze plan for project `jomimpactdb`; Cloud Functions
   deployments require billing to be enabled.
2. In the Stripe Dashboard, enable **Test mode** and open **Developers > API
   keys**.
3. Add the test publishable key (`pk_test_...`) to `env/dev.json` as
   `STRIPE_PUBLISHABLE_KEY`. Never put the secret key in this file.
4. From the project root, store the test secret key interactively:

   ```powershell
   firebase functions:secrets:set STRIPE_SECRET_KEY --project jomimpactdb
   ```

5. Deploy the backend and updated Firestore rules:

   ```powershell
   firebase deploy --only functions,firestore:rules --project jomimpactdb
   ```

6. Rebuild and run the Android app:

   ```powershell
   flutter run -d emulator-5554 --dart-define-from-file=env/dev.json
   ```

Use Stripe's standard test card `4242 4242 4242 4242`, any future expiry,
and any three-digit CVC. No real money is moved in test mode.
