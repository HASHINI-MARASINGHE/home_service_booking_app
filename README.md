# HomeCare — Home Service Booking App

A Flutter app for booking home services in Sri Lanka: a customer finds a
verified plumber, electrician or cleaner, agrees a price before the work
starts, tracks the job and keeps a receipt. A provider receives confirmed
jobs, quotes a price and gets paid. An admin verifies providers and settles
disputes.

Built for **IT3060 Human Computer Interaction**, Milestone 03, group WD_09.

- **Three roles in one app:** customer, service provider, admin.
- **Languages:** English, Sinhala and Tamil, switchable at any time, plus three
  text sizes for readability.
- **Backend:** Firebase Authentication and Cloud Firestore. The Firestore
  security rules act as the server-side API guard: every price, status change
  and permission is re-checked on the server, so a modified client cannot skip
  a step. Images go to **Cloudinary**, not Firebase Storage.

## What the app does

**Customer**
- Browse and search verified providers by category, and open a provider profile.
- Book a service: pick a date and a free time slot, choose a saved address, and
  send the request. Slots are locked in a transaction, so two customers can
  never take the same one.
- **Price quotes:** a booking starts with no price. The provider sends a quote,
  and the customer accepts or declines it. Accepting confirms the job and locks
  the amount. A revised price needs the customer's approval again.
- Track live status: Requested, Confirmed, On the way, In progress, Done.
- Manage a booking: edit details (address, access notes, phone, issue photos),
  reschedule against live availability, or cancel with the refund rules applied.
- Saved addresses: add, edit, delete, set a default, pick from GPS.
- After the job: a digital receipt (download or share as PDF), a star rating and
  review (which can be edited or deleted), and a dispute with photos if
  something went wrong.
- Settings: language, text size, notifications, privacy and security.

**Service provider**
- Leads dashboard, and jobs split into Requests, Confirmed and History.
- **Send a quote** for a request, then accept or decline it; **revise the price**
  of a confirmed job with a reason.
- Mark a job complete. This is blocked until the customer has approved a price.
- Earnings for the month and overall.
- Profile with services, starting price and availability, plus notifications.
- Cannot take any job until an admin has verified their identity.

**Admin**
- Review provider verifications: see every document, then verify (which issues a
  Provider ID such as `HCP-1001` and publishes the public profile) or send back
  with a reason.
- Monitor ratings and reviews per provider and per service.
- Review and resolve disputes, including refund decisions.

## Tech stack

| Layer | Choice |
| --- | --- |
| Mobile frontend | Flutter (Dart), one codebase, builds a real APK |
| Authentication | Firebase Authentication (email and password, three roles) |
| Database | Cloud Firestore, realtime, offline-tolerant |
| Server-side rules | `firestore.rules` — validates every write |
| Image storage | Cloudinary (unsigned upload preset) |
| PDF receipts | `pdf` + `printing` packages, generated on the device |
| Design and source control | Figma, GitHub |

Design and data contract: [docs/customer_booking_management.md](docs/customer_booking_management.md).
Provider workflow: [docs/provider_phase1.md](docs/provider_phase1.md).

## Install the app (no build needed)

1. Download `app-release.apk` from the repository's **Releases** page.
2. Copy it to an Android phone (Android 6.0 or newer).
3. Open the file and allow "install from unknown sources" when prompted.
4. The app needs an internet connection, because it talks to Firebase.

Sign in with one of the test accounts below.

## Run from source

```bash
flutter pub get
flutter run                 # a device or emulator must be connected
```

`lib/firebase_options.dart` already points at the project's Firebase, so no
extra configuration is needed to run it.

## Build the APK yourself

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

The build is signed with the debug key, which is fine for installing and
demonstrating. A Play Store upload would need a release key.

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
flutter analyze                 # static analysis: expect "No issues found!"
flutter test                    # 302 unit and widget tests
```

Security rules run against a local Firestore emulator. They replay the exact
writes the app makes, plus the writes a modified client might try:

```bash
firebase emulators:exec --only firestore --project demo-homecare   "node tool/quote_rules_test.mjs && node tool/customer_rules_test.mjs"
```

- `tool/quote_rules_test.mjs` — 58 checks on the quote and price-approval flow
- `tool/customer_rules_test.mjs` — 216 checks on bookings, addresses, reviews,
  receipts, refunds and disputes
- `tool/provider_rules_test.mjs` — provider workflow (needs the Auth emulator
  too: add `--only auth,firestore`)

End-to-end in Chrome against the seeded emulators:

```bash
chromedriver --port=4444
flutter drive --driver=test_driver/integration_test.dart   --target=integration_test/customer_flows_test.dart -d web-server
```

The end-to-end test changes the seeded data; run `node seed.mjs --emulator`
again to reset it.

## Project layout

```
lib/
  models/        booking, quote, address, review, dispute, receipt …
  services/      every Firestore read and write (the only data layer)
  screens/       auth, onboarding, customer, provider, admin
  widgets/       shared UI (buttons, cards, status chips, logo)
  theme/         colours, text styles, spacing (the HomeCare style guide)
  l10n/          English, Sinhala and Tamil strings
firestore.rules  server-side rules: the real API guard
test/            unit and widget tests
tool/            seed data, rule tests, icon generation
docs/            design and data contracts
```

## Updating the app icon

The logo lives at `design/app_icon/homecare_icon_circle_1024.png`. After
changing it, rebuild every size (needs Python with Pillow and numpy):

```bash
python tool/generate_app_icons.py design/app_icon/homecare_icon_circle_1024.png
```
