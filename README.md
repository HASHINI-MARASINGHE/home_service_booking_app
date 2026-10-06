# HomeCare – Home Service Booking App

Flutter app for booking home services in Sri Lanka, with customer and
provider roles. The backend is **Firebase**: Authentication, Cloud Firestore
(with security rules acting as the server-side API guard) and Cloud Storage.

Customer features: saved addresses (add, edit, delete, set default, GPS),
booking history, booking details with live status, edit booking details
(address, access notes, phone, issue photos), reschedule with live slot
availability, cancellation with refund tracking, and digital receipts
(PDF download/share, rating, dispute reporting).

Design and data contract: [docs/customer_booking_management.md](docs/customer_booking_management.md).
Provider workflow: [docs/provider_phase1.md](docs/provider_phase1.md).

## Test accounts

Created by the seed script (`tool/seed/seed.mjs`). Password for every account:
**`HomeCare@123`**

| Email | Role | What you will see |
| --- | --- | --- |
| `customer@homecare.test` | Customer | 3 saved addresses; upcoming, pending, completed (with receipt) and cancelled (with refund) bookings |
| `newcustomer@homecare.test` | Customer | Empty states (no bookings, no saved addresses) |
| `other@homecare.test` | Customer | Holds one of Nuwan's slots (shows as "Booked" when rescheduling) |
| `nuwan@homecare.test` | Provider | Assigned AC jobs |
| `kasun@homecare.test` | Provider | Assigned plumbing/cleaning jobs |
| `admin` (sign in with **Admin sign in** on the login screen) | Admin | Password **`HomeCare@Admin2026`**. Reviews provider verifications |

Seeded providers are already verified (Provider IDs `HCP-1001` and `HCP-1002`).

## Provider verification and the admin side

Providers cannot take jobs until an admin verifies them.

1. **Sign up as a provider** (Create account > Provider): details, then ID/passport
   (front + back for a National ID, plus the number), a live selfie, a CV and at least one
   course certificate (extra work experience is optional), then the login (email + password).
   Nothing is created until the last step, then the documents are uploaded together with the account.
2. Until verified the provider only has **Profile** and **Notifications**.
   The profile shows "Verification pending".
3. An **admin** signs in with **Admin sign in** and sees **Providers** (pending / verified / rejected)
   and their own **Profile**. Opening a provider shows every detail and document. **Verify provider**
   gives them a Provider ID (`HCP-1001`, `HCP-1002`, ...), publishes the public profile customers see,
   and sends a notification. **Send back** needs a reason; the provider fixes and resubmits.
4. Once verified, the provider's profile shows the **Provider ID** and a verified badge, and the jobs unlock.

Admin accounts cannot be created from the app. Create one with
`node tool/seed/create_admin.mjs --emulator|--production --username admin --password '...' --name '...'`
(`--production` needs a service-account key like the seed). Change the demo password before going live.
Deploy rule file: `firebase deploy --only firestore:rules`.

## Prerequisites

- Flutter 3.47+ (Dart 3.13+)
- Node.js 20+ (seed data, mock payment worker, rule tests)
- Firebase CLI (`npm i -g firebase-tools`) and **Java 21+** for the emulators

## Run locally with the Firebase emulators (recommended)

```bash
# 1. Start Auth + Firestore emulators (loads firestore.rules from firebase.json)
firebase emulators:start --only auth,firestore

# 2. Seed demo data (second terminal)
cd tool/seed
npm install
node seed.mjs --emulator

# 3. Optional: mock payment/receipt backend (advances refunds, issues receipts)
node backend_worker.mjs --emulator --watch

# 4. Run the app against the emulators (repo root)
flutter run -t tool/provider_emulator.dart \
  --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2   # Android emulator
#   use 127.0.0.1 for Chrome/desktop, or your PC's LAN IP for a phone
```

If port 8080 is already used (for example by Tomcat), change the Firestore
port in `firebase.json` and pass it to the seed and the app:
`FIRESTORE_EMULATOR_HOST=127.0.0.1:8085 node seed.mjs --emulator` and
`--dart-define=FIRESTORE_EMULATOR_PORT=8085`.

## Image uploads

All images across the app are uploaded to **Cloudinary** using an unsigned upload preset:
- **Always use `ImageUploadService.uploadImage`** (`lib/services/image_upload_service.dart`).
- Pass the appropriate folder constant from `UploadFolders`:
  - `UploadFolders.booking(bookingId)` for booking issue photos
  - `UploadFolders.providerDocs(uid)` for provider documents / verification scans
  - `UploadFolders.profile(uid)` for user profile photos
  - `UploadFolders.misc` for any other temporary or general images
- **Never use Firebase Storage**: Firebase Storage has been completely removed from the project.
- **Never add or commit Cloudinary secrets**: Uploads use an unsigned preset (`homecare_unsigned` on cloud `dclo5pyll`). No API key or API secret should ever be added to the app.
- **Viewing uploaded images**: Log in to the Cloudinary Console and open the **Media Library** under account `dclo5pyll` to see all uploaded files organized by folder (`bookings/`, `provider_docs/`, `profiles/`). Note that client-side unsigned uploads cannot be deleted from the client; removal simply stops referencing the URL in Firestore.

## Run against the real Firebase project

```bash
flutter pub get
flutter run                                  # uses lib/firebase_options.dart

# Deploy the security rules once (required for the customer flows):
firebase deploy --only firestore:rules

# Seed (needs a service-account key with Firestore/Auth admin access):
GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json node tool/seed/seed.mjs --production
```

> `firestore.rules` is the complete ruleset (users, provider workflow and
> customer flows). Review it against anything already deployed in the console
> before deploying.

## Tests

```bash
flutter analyze
flutter test                                   # unit + widget tests

# Security rules (Firestore emulator running):
node tool/customer_rules_test.mjs

# End-to-end in Chrome against the seeded emulators:
chromedriver --port=4444
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/customer_flows_test.dart -d web-server
```

The end-to-end test changes the seeded data; run `node seed.mjs --emulator`
again to reset it.

