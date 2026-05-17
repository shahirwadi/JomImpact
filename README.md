# JomImpact

JomImpact is a Flutter volunteering platform built with an MVVM structure.

## Roles

- `volunteer`: browse events, view organizers, apply to join, manage profile
- `organizer`: register an organizer account, wait for admin approval, publish and manage events after approval
- `admin`: review organizer registration requests and approve or reject them

## Storage Choice

This app no longer depends on Firebase Storage for images.

- Event and profile images are uploaded to `Cloudinary` using its free tier
- Only the returned image URL is stored in Firestore

## Cloudinary Setup

Create a local file at `env/dev.json` using `env/dev.example.json` as the shape:

```json
{
  "CLOUDINARY_CLOUD_NAME": "your-cloud-name",
  "CLOUDINARY_UPLOAD_PRESET": "your-unsigned-upload-preset"
}
```

Then run the app with the included PowerShell helper:

```powershell
.\scripts\run_dev.ps1
```

Or run Flutter directly with `--dart-define-from-file`:

```bash
flutter run --dart-define-from-file=env/dev.json
```

If Cloudinary is not configured, image uploads will show a clear in-app error and users can still paste direct image URLs manually.

## Admin Bootstrap

Admin accounts are not self-registered from the app UI. The easiest local setup is the included seed script.

1. Download a Firebase service account key from:
   Firebase Console -> Project Settings -> Service accounts -> Generate new private key
2. Save it as `scripts/serviceAccountKey.json`
3. Install the seed script dependency:

```bash
cd scripts
npm install
```

4. Run the seed:

```bash
npm run seed:demo
```

That seeds these accounts:

- `admin@demo.com / demo123`
- `organizer@demo.com / demo123`
- `pending.organizer@demo.com / demo123`
- `volunteer@demo.com / demo123`

It also creates one published demo event for the approved organizer.

If you prefer to create the first admin manually, create the user in Firebase Authentication and then add the Firestore document below:

```json
{
  "id": "admin-user-id",
  "name": "Admin",
  "email": "admin@demo.com",
  "role": "admin",
  "skills": [],
  "organizerApprovalStatus": "notRequired",
  "createdAt": "2026-04-20T00:00:00.000Z"
}
```

After that, the admin can approve organizer registrations directly from the app.
