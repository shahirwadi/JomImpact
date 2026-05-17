# JomImpact Firebase Setup Guide

Use this for the current app structure with `volunteer`, `organizer`, and `admin` roles.

## 1. Firebase Project

1. Open [Firebase Console](https://console.firebase.google.com)
2. Create or choose your project
3. Make sure Email/Password auth is enabled
4. Make sure Firestore is enabled

Your repo already contains generated Firebase config for project `jomimpactdb` in [lib/firebase_options.dart](C:/Users/Shahir/OneDrive/Documents/JomImpact%20App/JomImpact%20latest/jomimpact/lib/firebase_options.dart).

## 2. Firestore Rules

Deploy the current Firestore rules:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

These rules now support:

- `admin` reviewing organizer requests
- `organizer` requiring approval before event publishing
- volunteers applying to events

## 3. Cloudinary Instead of Firebase Storage

Firebase Storage is no longer used for app image uploads.

Create `env/dev.json` with:

```json
{
  "CLOUDINARY_CLOUD_NAME": "your-cloud-name",
  "CLOUDINARY_UPLOAD_PRESET": "your-unsigned-upload-preset"
}
```

Then run:

```powershell
.\scripts\run_dev.ps1
```

Cloudinary setup checklist:

1. Create a free Cloudinary account
2. Copy your cloud name
3. Create an unsigned upload preset
4. Put both values into `env/dev.json`

## 4. Seed Demo Users and Admin

The repo now includes a seeding script at [scripts/seed_demo_accounts.mjs](C:/Users/Shahir/OneDrive/Documents/JomImpact%20App/JomImpact%20latest/jomimpact/scripts/seed_demo_accounts.mjs).

### Prepare

1. In Firebase Console, open:
   Project Settings -> Service accounts
2. Generate a private key
3. Save it as `scripts/serviceAccountKey.json`

### Install seed dependency

```bash
cd scripts
npm install
```

### Run seed

```bash
npm run seed:demo
```

### Seeded accounts

- `admin@demo.com / demo123`
- `organizer@demo.com / demo123`
- `pending.organizer@demo.com / demo123`
- `volunteer@demo.com / demo123`

The script also creates one published demo event for the approved organizer.

## 5. Run the App

From the project root:

```powershell
flutter pub get
.\scripts\run_dev.ps1
```

Or without Cloudinary:

```powershell
.\scripts\run_dev.ps1 -NoCloudinary
```

## 6. Quick Login Paths

Once the seed is done:

- use `admin@demo.com` to review organizer requests
- use `organizer@demo.com` to access organizer screens immediately
- use `pending.organizer@demo.com` to test the approval waiting screen
- use `volunteer@demo.com` to browse and apply to events

## 7. Troubleshooting

- `Missing env/dev.json`: create the file from `env/dev.example.json`
- `Missing scripts/serviceAccountKey.json`: download a Firebase service account key first
- `PERMISSION_DENIED`: deploy Firestore rules again
- Cloudinary upload error: confirm cloud name and unsigned upload preset
- Login works but screen looks unchanged: check the Firestore user `role` and `organizerApprovalStatus`
