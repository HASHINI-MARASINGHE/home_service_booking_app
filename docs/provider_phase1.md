# Provider Phase 1 implementation report

Implemented on the existing `Hashini` branch. No branch creation/switch, merge, commit, push, reset, or deletion of existing work was performed.

## 1. Files modified

| File | Purpose |
| --- | --- |
| `lib/screens/provider/provider_home_screen.dart` | Replaces the temporary provider screen with the provider-only theme, dashboard entry, persistent Leads/My Jobs/Earnings/Profile navigation, shared booking stream, detail/payment navigation, back handling and success destinations. |

## 2. Files created

| File | Purpose |
| --- | --- |
| `lib/models/booking.dart` | Booking fields, Timestamp conversion, status enum, allowed transitions, expiry checks and earnings calculations. |
| `lib/models/provider_profile.dart` | Provider-only fields and validation; excludes rating/verification from editable fields. |
| `lib/services/provider_booking_service.dart` | UID-scoped realtime bookings, request/confirmed/history/earnings projections and transactional accept/decline/complete. |
| `lib/services/provider_profile_service.dart` | Reads the signed-in provider's profile and merges editable fields with a server update timestamp. |
| `lib/screens/provider/provider_theme.dart` | Centralized reference palette, typography, buttons, navigation and input styling. |
| `lib/widgets/provider/provider_widgets.dart` | Cards, booking tiles, status badges, detail rows, empty/error states and date/currency formatting. |
| `lib/screens/provider/provider_dashboard_screen.dart` | Greeting, Firestore-derived counts, monthly earnings, next scheduled job and recent requests. |
| `lib/screens/provider/provider_jobs_screen.dart` | Requests, Confirmed and History sections with status filtering. |
| `lib/screens/provider/provider_job_details_screen.dart` | Reference-inspired request/details interface, real expiry countdown, booking details and estimated amount. |
| `lib/screens/provider/provider_job_actions.dart` | Accept, decline/complete confirmation, duplicate-tap protection, error/success feedback and transition callbacks. |
| `lib/screens/provider/provider_payment_screen.dart` | Labor, fee, total, customer, schedule and payment information; confirmed-job completion. |
| `lib/screens/provider/provider_earnings_screen.dart` | Monthly/all-time earned amounts, completed count and recent eligible payouts. |
| `lib/screens/provider/provider_profile_screen.dart` | Identity display, professional profile, real edit/save form and existing LogoutButton. |
| `test/provider_workflow_test.dart` | Status-transition matrix, expiry, timestamps, payout eligibility, invalid money and protected profile fields. |
| `test/provider_screens_test.dart` | Empty dashboard, status-filtered lists and 320px phone layout checks. |
| `test/provider_actions_test.dart` | Realtime acceptance race, decline cancellation/confirmation and completion confirmation. |
| `tool/provider_emulator.dart` | Optional debug-only entry point connecting Auth and Firestore to local emulators. Production startup is unchanged. |
| `tool/provider_rules_test.mjs` | Local-only REST security checks; creates explicit emulator test fixtures, never production demo records. |
| `docs/provider_phase1.rules` | Exact recommended additional Firestore helpers/matches, supplied for manual merging. Not deployed. |
| `docs/provider_phase1.md` | This schema, implementation, testing and assignment handoff. |

Unchanged: authentication files, AppUser, CustomerHomeScreen, main.dart, firebase_options.dart, existing Firebase configuration, pubspec dependencies, Android configuration and the existing starter counter test.

## 3. Collections and exact field contract

No earnings collection is introduced. The provider consumes and updates the same booking document that the future customer flow will create.

### users/{uid} — existing, unchanged

| Field | Type | Meaning |
| --- | --- | --- |
| uid | string | Firebase Auth UID |
| name | string | Account name |
| email | string | Account email |
| role | string | Existing `customer` or `provider` routing role |

Provider identity is passed from the already-loaded AppUser. Name/email are not copied into providerProfiles.

### bookings/{bookingId}

The document ID is `Booking.id`; it is not duplicated in the document. All money is LKR. Use Firestore timestamps, not date strings.

| Field | Type | Contract |
| --- | --- | --- |
| customerId | string | Owning customer's Firebase UID |
| providerId | string | Assigned provider's Firebase UID; required for query/authorization |
| serviceId | string or null | Optional service reference |
| serviceName | string | Job/service display name |
| customerName | string | Booking-time customer display name |
| scheduledAt | timestamp or null | Appointment date/time |
| address | string | Job location |
| estimatedPrice | number or null | Customer-approved estimate |
| laborCharge | nonnegative number or null | Phase 1 provider payout amount, excluding the platform fee |
| serviceFee | nonnegative number or null | Platform fee |
| totalAmount | nonnegative number or null | Final customer charge |
| paymentMethod | string or null | Display value, e.g. `cash`, `card`; no payment processing is implied |
| paymentStatus | string or null | Only exact `paid` qualifies for earnings; `unpaid`, `pending`, `refunded`, missing or other values do not |
| status | string | `pending`, `confirmed`, `declined`, `completed`, `cancelled` |
| createdAt | timestamp or null | Booking creation time; recommended for ordering |
| acceptedAt | timestamp or null | Server timestamp written by Accept |
| declinedAt | timestamp or null | Server timestamp written by Confirm Decline |
| completedAt | timestamp or null | Server timestamp written by Mark Complete |
| expiresAt | timestamp or null | Optional genuine request deadline; enables countdown and acceptance restriction |
| payoutNote | string or null | Optional actual fee/travel explanation supplied by booking data |

Missing descriptive values show explicit fallbacks. Unknown statuses are parsed as `BookingStatus.unknown` and receive no workflow actions. Invalid negative/nonfinite monetary data is not used as earnings. Optional fields can be omitted or null. No runtime seed/demo booking is created.

Contract to agree with the customer/backend team: laborCharge represents net provider labor payout; totalAmount includes serviceFee. Travel is described only when supplied in payoutNote. If your business uses different fee accounting, adjust this contract and earnings calculation together.

### providerProfiles/{uid}

| Field | Type | Contract |
| --- | --- | --- |
| providerId | string | Same UID as document ID |
| phone | string | Optional phone; empty allowed, max 40 characters |
| profession | string | Required when saving; 1–100 characters |
| experience | integer | Years, 0–80 |
| about | string | Empty allowed; max 2,000 characters |
| services | list of strings | Up to 20 nonempty services, each at most 100 characters |
| pricing | number or null | Starting price in LKR; 0–10,000,000 |
| availability | boolean | Available for new jobs |
| updatedAt | timestamp | Server timestamp on each save |
| verificationStatus | string, backend-managed | Missing displays `unverified`; client cannot edit |
| rating | number or null, backend-managed | Missing displays “No ratings yet”; expected scale 0–5; client cannot edit |

Opening a profile does not create a document. First Save creates one; later Saves merge only editable fields, preserving backend rating and verification. Availability is informational in Phase 1; customer-side matching/enforcement comes later.

## 4. Statuses and navigation

Provider login still uses the existing AuthWrapper role routing. It now opens Leads/dashboard, never a fabricated job.

- Requests: current UID + pending.
- Confirmed: current UID + confirmed; sorted by scheduled time.
- History: current UID + completed/declined/cancelled.
- Cancelled is readable history; Phase 1 adds no cancellation action.
- Detail/payment screens stay inside the provider shell, retaining bottom navigation.
- Back returns from payment to details, then to the previous provider section.
- Switching bottom destinations closes the selected details view.

Today's Jobs counts confirmed/completed bookings scheduled on the current device-local calendar date. Upcoming Job is the earliest confirmed booking scheduled after now. Monthly summaries refresh every minute as well as on Firestore updates.

## 5. Exact Accept flow

1. Provider opens an actual pending booking.
2. Accept disables during processing.
3. Service derives UID from FirebaseAuth, then starts a Firestore transaction.
4. Transaction rereads the existing booking and checks existence, providerId, pending status and optional expiry.
5. Update ONLY `status: confirmed` and `acceptedAt: serverTimestamp()`.
6. Firestore stream removes the booking from Requests and includes it in Confirmed.
7. Show “Job accepted.” and navigate to My Jobs → Confirmed.
8. A stable action-widget key preserves feedback/navigation if the stream updates before the transaction Future resolves.

No second booking is created. Repeated/conflicting responses fail validation. The recommended security rules enforce the same restrictions, using server time for expiry.

## 6. Exact Decline flow

1. Show “Decline this job request?” with Cancel and Confirm Decline.
2. Cancel makes no Firestore call.
3. On confirmation, a transaction verifies assignment and pending status.
4. Update ONLY `status: declined` and `declinedAt: serverTimestamp()`.
5. Show “Job request declined.” and navigate to My Jobs → History.
6. The original document remains. Realtime status filtering removes it from Requests.

## 7. Exact Complete Job flow

1. Open a confirmed booking → Job completion / payment.
2. Review job, customer, schedule, labor charge, fee, total and payment information.
3. Tap Mark Job Complete and confirm the work is finished.
4. Transaction rereads the booking and requires the current provider and confirmed status.
5. Update ONLY `status: completed` and `completedAt: serverTimestamp()`.
6. Navigate to History and show “Job marked complete.”
7. Earnings recalculate from the stream, subject to the eligibility rules below.

Completion does not charge a customer or mark payment paid. Providers cannot modify price, assignment or payment fields through these actions.

## 8. Earnings calculation

Eligible booking = completed + paymentStatus exactly paid + a completedAt date + a valid known payout.

Payout = laborCharge when supplied; otherwise totalAmount minus serviceFee when BOTH are supplied and totalAmount >= serviceFee. An estimate is never treated as settled earnings.

Monthly earnings sum eligible payouts whose completedAt falls in the current device-local month/year. All-time earnings sum all eligible payouts. Completed job count includes all completed jobs, including unpaid ones. Recent earnings sort by completion date descending.

A completed unpaid job appears in History but contributes zero until a trusted payment process records paid. Later payment updates recalculate earnings automatically; the accounting month remains the completion month. Refunds/non-paid values remove eligibility. This is a booking-derived foundation, not a financial ledger or payment gateway.

## 9. Indexes and scale

Current booking query: `bookings.where('providerId', isEqualTo: currentUid)`. All status filtering and sorting happen locally.

No custom composite index is needed with Firestore's default providerId single-field index enabled. Profile reads use the UID document path. If automatic single-field indexing has been disabled for providerId, re-enable it.

For later pagination/server-side filtering, composite indexes such as providerId + status + scheduledAt or providerId + status + completedAt will likely be required; follow the exact missing-index link generated by that future query. Phase 1 streams the provider's full booking history, so pagination and aggregate summaries are a later scale improvement.

## 10. Manual security-rule changes

The repository contains no deployed Firestore rules source, so the current Console rules could not be inspected. Nothing has been deployed.

Open `docs/provider_phase1.rules`. Copy its helper functions plus the providerProfiles and bookings match blocks INSIDE the existing `match /databases/{database}/documents` block in Firebase Console → Firestore Database → Rules. Preserve your existing users rules and other unrelated collection rules. Keep one outer rules_version/service/databases wrapper.

**Do not paste this file over the entire deployed ruleset**: it intentionally omits users rules to avoid guessing/replacing yours. If bookings/providerProfiles rules already exist in Console, reconcile those matches; overlapping allow rules are additive, so a broader existing allow can defeat the restrictions.

The supplied rules:

- Require authentication and the existing users/{uid}.role == provider for provider operations.
- Allow providers to read only assigned bookings and their own profile.
- Allow owning customers to read their existing bookings.
- Permit only pending→confirmed, pending→declined and confirmed→completed.
- Restrict changed booking fields to status and the matching server timestamp.
- Enforce expiresAt against request.time for acceptance.
- Deny client booking creation/deletion in this phase; a trusted backend/Console can create integration fixtures. Customer booking creation rules must be added with that later workflow.
- Deny provider changes to prices, customerId, providerId, payment status, rating and verification.
- Validate editable profile types/lengths and restrict writes to the owner.
- Deny profile deletion.

Client UID checks are defensive UI/service behavior, not a substitute for deploying these rules.

Implementation references: [Firestore field restrictions](https://firebase.google.com/docs/firestore/security/rules-fields), [transactions](https://firebase.google.com/docs/firestore/manage-data/transactions), [Firestore emulator](https://firebase.google.com/docs/emulator-suite/connect_firestore).

## 11. Validation results

- `flutter analyze`: passed, no issues found.
- `flutter test --no-pub test/provider_workflow_test.dart test/provider_screens_test.dart test/provider_actions_test.dart`: all 13 tests passed.
- `git diff --check`: passed (only a repository line-ending notice for the modified Dart file).
- Branch verified as `Hashini`; only the existing provider home is modified, with 20 new provider/support files.
- Local security test execution: NOT completed. Firebase CLI's emulator download stalled; a direct checksum-planned retry downloaded 25,658,424 of 136,707,194 bytes before its 120-second timeout. The Firestore emulator never started, so the recommended rules and REST checks remain unverified in an emulator. The commands/script are supplied for rerunning once the download succeeds.
- No pixel-perfect screenshot comparison or end-to-end app/Firebase emulator session is claimed. Dart action tests use a test service; model and UI behavior were tested independently of a live backend.

The existing `test/widget_test.dart` is still the old counter-app test from before this phase and is not included in the provider test command. It was not modified because it is unrelated to this provider implementation. The full legacy suite is not claimed green.

No live Firebase writes, deployed rules changes, Android build or full on-device visual acceptance test were performed.

## 12. Exact local emulator instructions

Prerequisites: Flutter, Node.js, Firebase CLI and Java installed; available ports 8080, 9099, 4000. The optional entry point uses the existing project ID/options but redirects Auth and Firestore locally before MyApp starts.

From this repository in PowerShell, create a TEMPORARY emulator configuration, leaving the project's firebase.json unchanged:

```powershell
$providerEmulatorDir = Join-Path $env:TEMP 'home-service-provider-phase1'
New-Item -ItemType Directory -Force -Path $providerEmulatorDir | Out-Null
$providerRules = Get-Content -Raw -LiteralPath '.\docs\provider_phase1.rules'
$localUsersRule = 'match /users/{uid} { allow read, create, update: if request.auth != null && request.auth.uid == uid; }'
$providerRules = $providerRules.Replace(
  'match /databases/{database}/documents {',
  'match /databases/{database}/documents {' + [Environment]::NewLine + $localUsersRule
)
[IO.File]::WriteAllText((Join-Path $providerEmulatorDir 'firestore.rules'), $providerRules)
$localConfig = '{"firestore":{"rules":"firestore.rules"},"emulators":{"auth":{"port":9099},"firestore":{"port":8080},"ui":{"enabled":true,"port":4000},"singleProjectMode":true}}'
[IO.File]::WriteAllText((Join-Path $providerEmulatorDir 'firebase.json'), $localConfig)
firebase emulators:start --only 'auth,firestore' --project home-service-booking-app-89796 --config (Join-Path $providerEmulatorDir 'firebase.json')
```

The inserted users rule is a **local-test-only** owner-access baseline so the existing registration flow can run. It is not a recommendation to replace the deployed users rules.

In a second PowerShell terminal at the repository root:

```powershell
flutter devices
flutter run -d <android-device-id> -t tool/provider_emulator.dart --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

Replace the device placeholder with the Android emulator ID from flutter devices. For a desktop/browser client on the same computer, use 127.0.0.1 instead. For a physical phone, use the development machine's reachable LAN address and configure emulator listening/firewall deliberately. The entry point is debug-only. Do not run normal main.dart for these emulator checks: normal main.dart uses live Firebase.

Open http://127.0.0.1:4000. Register a provider in the app, then find the UID in emulator Authentication. Confirm the empty Leads dashboard shows 0 / 0 / LKR 0 and both empty sections. Edit/save Profile and verify providerProfiles/{uid} appears in emulator Firestore. Sign out/in and restart the app to check the existing session flow.

Create an explicit test booking in emulator Firestore (not production), using this field/type example:

| Field | Example |
| --- | --- |
| providerId | The registered provider UID (string) |
| customerId | A registered test customer UID (string) |
| serviceId | test-service (string) |
| serviceName | Your chosen test service (string) |
| customerName | Test Customer (string) |
| address | Your chosen test address (string) |
| scheduledAt | Tomorrow (Firestore timestamp) |
| createdAt | Now (Firestore timestamp) |
| expiresAt | 30 minutes from now (optional Firestore timestamp) |
| estimatedPrice | 2500 (number) |
| laborCharge | 2000 (number) |
| serviceFee | 500 (number) |
| totalAmount | 2500 (number) |
| paymentMethod | cash (string) |
| paymentStatus | unpaid (string) |
| status | pending (string) |
| payoutNote | Optional test fee/travel note (string) |

The app does not create these test records automatically. The following manual scenarios exercise the actual app/services:

1. Keep Leads open while creating the document. Confirm the new request/count appears without refresh.
2. Open it and verify the exact Firestore service, address, schedule, amount and deadline.
3. Accept. Confirm the SAME document becomes confirmed with acceptedAt, and My Jobs opens Confirmed.
4. Open details → Job completion / payment → Mark Job Complete. Confirm completedAt, History membership and zero earnings while unpaid.
5. In emulator Console as the trusted operator, change paymentStatus to paid. Earnings should become LKR 2,000 for a current-month completion.
6. Create a second pending document. Tap Decline then Cancel: status must remain pending. Repeat and Confirm Decline: status becomes declined and History opens.
7. Create a cancelled document; it should be in History only.
8. Use a second provider UID to verify it cannot see the first provider's jobs.
9. Change a request to declined/cancelled while its details are open; it should update and remove Accept. Try competing responses in two sessions.
10. Set expiresAt in the past; Accept is disabled, and server rules reject acceptance even with a modified client clock.
11. Test network interruption and a permission denial; check feedback/retry and no duplicate records.
12. Sign in with a customer account to check that existing customer routing remains unchanged.

Automated Dart checks:

```powershell
flutter analyze
flutter test --no-pub test/provider_workflow_test.dart test/provider_screens_test.dart test/provider_actions_test.dart
```

With Auth and Firestore emulators running, execute the local REST security tests:

```powershell
node tool/provider_rules_test.mjs
```

This script explicitly creates emulator-only accounts/profiles/bookings and tests provider-scoped reads, denied unscoped reads, ownership, all workflow transitions, competing responses, expiry, protected amounts/payment fields, deletion denial and protected profile fields. It makes no requests to production endpoints. Emulator data can be discarded by stopping the emulators; the scripts do not delete existing project files.

## 13. Figma alignment and deliberate differences

The provider screens use the supplied navy/teal/blue-grey palette, light background, white rounded cards, subtle borders/shadows, light teal icon tiles, orange warning area, green Accept and red Decline. The provider Theme overrides the existing purple theme locally; customer/auth screens are unchanged.

The new request includes the same job-details and teal estimated-amount structure. Additional screens extend that visual style. Layouts scroll and adapt rather than reproducing a fixed Figma canvas or drawing fake device status bars.

Differences: navigation starts at a real dashboard; countdown exists only with expiresAt; no false automatic-reassignment or instant-payout claims; actual optional fee/travel data replaces unconditional example text; accessible darker green/red are used; warnings and actions wrap/scroll on small screens; useful back controls, error states and confirmations are added. The reference's example service/address/price are never hard-coded into runtime UI. Pixel-perfect/on-device review remains for the next refinement phase.

## 14. Assignment CRUD/data-operation mapping

| Interface | Genuine operation |
| --- | --- |
| Leads/dashboard | READ current provider bookings; derive counts, next job and earnings |
| Requests / request details | READ pending booking; UPDATE same document via Accept/Decline |
| Confirmed jobs | READ confirmed bookings |
| Completion/payment | READ payment fields; UPDATE status and completedAt only |
| History | READ retained completed, declined and cancelled bookings |
| Earnings | READ/derive eligible completed paid bookings; no artificial earnings records |
| Provider profile | READ providerProfiles; CREATE on first explicit Save; UPDATE on later Saves |
| Logout | Existing Firebase Authentication signOut; no Firestore deletion |

There is intentionally no Delete operation: booking deletion would destroy history, and deleting provider profiles was not requested. This is genuine create/read/update coverage, not a claim of complete CRUD when deletion is absent.

## 15. Next phase

Customer booking creation and corresponding create/update security rules; trusted payment confirmation/gateway and payout settlement; cancellation policy; automatic expiry/reassignment backend; push notifications; professional verification and ratings backend; service catalog and richer pricing/availability; pagination/server-side summaries; visual/device refinement; account-name/email editing; full same-account mode switching.

## 16. Same-account customer/provider modes

The existing AppUser has one role and AuthWrapper selects one destination, so that routing/authorization design WILL need a later migration. Keep one Firebase Auth UID and users identity, add capabilities/roles (e.g. customer plus provider onboarding status), and store the selected UI mode separately. The providerProfiles/{uid} document can remain the provider extension; bookings continue to identify participants by UID.

This phase does not alter roles or add a switch. Provider services derive identity from FirebaseAuth rather than assuming a second account. At migration time update AuthWrapper, onboarding, and the rules' providerSignedIn helper together; also review self-booking and profile discoverability policies. The separate provider shell/profile collection make that migration possible without duplicating authentication accounts.
