# Customer booking management

Covers My Addresses (with empty state), Add/Edit/Delete Address, Booking
History (with empty state), Booking Details, Edit Booking Details,
Reschedule, Cancel, Booking Cancelled/refund tracking and the Receipt.

## 1. Backend decision

The project already used Firebase Authentication, Cloud Firestore and Cloud
Storage. These features use that same backend; there is no second
(Express/PostgreSQL) server. Here is how each backend requirement is met:

| Requirement | Firebase implementation |
| --- | --- |
| Password hashing (bcrypt) | Firebase Auth stores salted scrypt hashes; the app never sees passwords |
| JWT access token | Firebase ID token (a signed JWT), refreshed automatically by the SDK |
| Token persistence / auto-login | Firebase Auth SDK session persistence; `AuthWrapper` listens to `authStateChanges()` on launch |
| Authenticated API requests | Every Firestore/Storage call carries the ID token |
| Protected endpoints, ownership checks | `firestore.rules` / `storage.rules`; identity comes from `request.auth.uid`, never from the request body |
| 401 handling | An expired or disabled session emits `null` from `authStateChanges()` and the app returns to Login; `AppError` maps `unauthenticated`/`permission-denied` to friendly messages |
| Server-side validation and status transitions | Security rules validate field types/lengths, allowed fields per action, fee/refund maths, slot locking and status changes |
| Transactions | Firestore transactions; rules use `getAfter()`/`existsAfter()` to check every write in a commit together |

### Spec endpoint → implementation

| Spec endpoint | Implementation (`lib/services`) |
| --- | --- |
| `POST /api/auth/login`, register, logout | `AuthService.login / register / logout / sendPasswordReset` |
| `GET /api/addresses` | `AddressService.watchAddresses()` (live stream of `users/{uid}/addresses`) |
| `POST /api/addresses` | `AddressService.create()`; the first address, or one marked default, clears other defaults in the same batch |
| `GET /api/addresses/:id` | `AddressService.getAddress()` |
| `PUT /api/addresses/:id` | `AddressService.update()` / `setDefault()` |
| `DELETE /api/addresses/:id` | `AddressService.delete()`; blocked while a pro is on the way; scheduled bookings keep an address snapshot and are flagged `addressNeedsUpdate` |
| `GET /api/bookings?status=…` | `CustomerBookingService.watchBookings()`, split into Upcoming / Past by status |
| `GET /api/bookings/:id` | `CustomerBookingService.watchBooking()` (live) + `getProfessional()` |
| `PUT /api/bookings/:id` | `CustomerBookingService.updateDetails()` (uploads photos to Storage, then runs a transaction) |
| `GET /api/bookings/:id/available-slots` | `CustomerBookingService.availableSlots()` |
| `POST /api/bookings/:id/reschedule` | `CustomerBookingService.reschedule()` (transaction) |
| `POST /api/bookings/:id/cancel` | `CustomerBookingService.cancel()` (transaction creates the refund) |
| `GET /api/bookings/:id/refund` | `CustomerBookingService.watchRefund()` (live) |
| `GET /api/bookings/:id/receipt` | `CustomerBookingService.getReceipt()` + `ReceiptPdfService` (on-device PDF) |
| (extra) review / dispute | `submitReview()` / `reportProblem()` |

## 2. Data model (Firestore)

| Collection | Written by | Notes |
| --- | --- | --- |
| `users/{uid}` | Owner | Existing. Role is fixed after registration |
| `users/{uid}/addresses/{id}` | Owner | `type` (home/office/parents/other), `label`, `houseNumber`, `street`, `city`, `postalCode`, `province`, `landmark`, `accessNotes`, `latitude`, `longitude`, `isDefault`, timestamps |
| `bookings/{id}` | Booking backend (create), provider (status), customer (edit/reschedule/cancel) | Existing provider fields plus `reference`, `providerName`, `serviceDetail`, `serviceTier`, `addressId`, `addressLabel`, `addressArea`, `addressNeedsUpdate`, `accessNotes`, `contactPhone`, `jobNotes`, `photoUrls`, `lineItems[]`, `slotDate`, `startTime`, `endTime`, `endAt`, `slotLockId`, `cardLast4`, cancellation fields |
| `slotLocks/{providerId_date_HHmm}` | Customer (in the reschedule transaction) | One document per provider slot. Rules allow create only and deny overwrite, so **double booking is impossible** |
| `professionals/{providerId}` | Backend | Public profile: name, photo, specialty, rating, completed jobs, verified, phone, licence, `workingSlots`, `workingDays` |
| `services/{id}` | Backend | Catalog: name, description, price, duration, category |
| `refunds/{bookingId}` | Customer (only inside the cancelling transaction), then backend | `amount`, `cancellationFee`, `percentage`, `method`, `cardLast4`, `refundReference`, `status` (initiated → processing → refunded) |
| `receipts/{bookingId}` | Backend | Issued at job sign-off; line items, totals, provider licence, payment note, verification code |
| `reviews/{bookingId}`, `disputes/{id}` | Customer | Create-only |

Booking statuses: `pending` (shown as Requested) → `confirmed` → `onTheWay`
→ `inProgress` → `completed`; or `cancelled` / `declined`. The timeline on
Booking Details reads `status` from Firestore.

Payment statuses: `unpaid` (cash on completion), `escrow` (card captured),
`paid`, `refund_pending`, `refunded`.

## 3. Business rules

Defined in `lib/models/booking_policy.dart` and enforced again by
`firestore.rules`:

- Times are Colombo wall-clock (UTC+05:30). `scheduledAt` must equal
  `slotDate` + `startTime` in Colombo time.
- Customers can edit address, notes, phone and photos (max 5) while the
  booking is `pending` or `confirmed`. Price, provider, service and status
  cannot be changed.
- Rescheduling and free cancellation close **2 hours** before the start time.
  The new slot must also be at least 2 hours away.
- Cancelling within 2 hours keeps a 20% fee (rounded down). Captured payments
  (`escrow`/`paid`) get `total − fee` back through a refund record created in
  the same transaction. Unpaid bookings create no refund.
- Slot availability comes from the professional's `workingSlots` and
  `workingDays` minus existing `slotLocks`. Past slots and slots inside the
  2-hour window show as unavailable.

## 4. Development backend

- `tool/seed/seed.mjs`: idempotent seed (accounts, professionals, services,
  addresses, bookings, slot locks, receipt and refund). Needs `--emulator` or
  `--production`.
- `tool/seed/backend_worker.mjs`: mock payment provider and receipt issuer.
  It moves refunds `initiated → processing → refunded`
  (`REFUND_SETTLE_SECONDS`, default 120) and issues receipts for completed
  bookings (`escrow → paid`). In production this belongs in Cloud Functions
  connected to the real gateway; the Firestore contract stays the same.

## 5. Verification

- `flutter test`: policy and model unit tests; widget tests for every screen,
  covering empty, loading and error states, the cancel, reschedule and delete
  flows, and 320 × 640 overflow checks.
- `node tool/customer_rules_test.mjs`: 49 allow/deny checks against the
  emulator, including double booking, forged times, inflated refunds, other
  users' data, unscoped queries, receipt forgery and a provider-flow
  regression check.
- `integration_test/customer_flows_test.dart`: real Firebase SDK in Chrome
  against the seeded emulators. Covers login → history → details → edit →
  reschedule (lock swap) → cancel (refund record) → add/delete address, and
  confirms another customer's booking is denied.

## 6. Known limitations

- Booking **creation** (service catalog → checkout) is not part of these
  screens; bookings come from the seed or a trusted backend, and client
  creation is denied by the rules.
- `onTheWay`/`inProgress` are set by a dispatch backend. The provider app
  still moves `confirmed → completed` directly and does not set these
  statuses yet.
- Payments and refunds go through the mock worker; no real gateway is
  connected.
- Rules cannot validate that a rescheduled time matches the professional's
  working template (they do enforce lock uniqueness and the 2-hour window).
- The map on Add Address is a styled preview. GPS fills the fields through
  reverse geocoding; there is no interactive map (that would need a Maps API
  key).
- Chat opens the phone's SMS app; there is no in-app messaging.
- The Inter typeface from the designs isn't bundled; the platform font is
  used.
