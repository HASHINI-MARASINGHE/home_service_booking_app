// Security-rule tests for the customer booking-management flows.
// Runs against a local Firestore emulator only (no external dependencies):
//
//   firebase emulators:start --only firestore      (or the emulator jar)
//   node tool/customer_rules_test.mjs
//
// Loads ./firestore.rules into an isolated demo project, then replays the
// exact writes the Flutter services make (as REST commits) for allowed and
// malicious cases.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const host = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const project = 'demo-homecare-rules-' + Date.now();
const root = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
const prefix = `projects/${project}/databases/(default)/documents/`;
let checks = 0;

// ------------------------------------------------------------------ helpers
function token(uid) {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b64({alg: 'none', typ: 'JWT'})}.${b64({
    iss: `https://securetoken.google.com/${project}`,
    aud: project,
    auth_time: now,
    user_id: uid,
    sub: uid,
    iat: now,
    exp: now + 3600,
    firebase: {sign_in_provider: 'password', identities: {}},
  })}.`;
}

// Dart writes money as doubles (5500.0); wrap a number to send it that way.
class Double {
  constructor(n) {
    this.n = n;
  }
}
const dbl = (n) => new Double(n);

function value(v) {
  if (v instanceof Double) return {doubleValue: v.n};
  if (v === null || v === undefined) return {nullValue: null};
  if (v instanceof Date) return {timestampValue: v.toISOString()};
  if (Array.isArray(v)) return {arrayValue: {values: v.map(value)}};
  if (typeof v === 'boolean') return {booleanValue: v};
  if (typeof v === 'number') {
    return Number.isInteger(v) ? {integerValue: String(v)} : {doubleValue: v};
  }
  if (typeof v === 'object') return {mapValue: {fields: fields(v)}};
  return {stringValue: v};
}
const fields = (data) =>
  Object.fromEntries(Object.entries(data).map(([k, v]) => [k, value(v)]));

async function call(url, method, auth, body) {
  return fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(auth ? {Authorization: 'Bearer ' + auth} : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

async function seed(path, data) {
  const res = await call(`${root}/${path}`, 'PATCH', 'owner', {fields: fields(data)});
  assert.equal(res.status, 200, await res.text());
}

// Write builders mirroring the Firestore client SDK.
const set = (path, data, stamps = []) => ({
  update: {name: prefix + path, fields: fields(data)},
  ...(stamps.length && {
    updateTransforms: stamps.map((f) => ({fieldPath: f, setToServerValue: 'REQUEST_TIME'})),
  }),
});
const patch = (path, data, stamps = []) => ({
  update: {name: prefix + path, fields: fields(data)},
  updateMask: {fieldPaths: Object.keys(data)},
  currentDocument: {exists: true},
  ...(stamps.length && {
    updateTransforms: stamps.map((f) => ({fieldPath: f, setToServerValue: 'REQUEST_TIME'})),
  }),
});
const del = (path) => ({delete: prefix + path});

const commit = (uid, writes) =>
  call(`${root}:commit`, 'POST', uid && token(uid), {writes});
const get = (uid, path) => call(`${root}/${path}`, 'GET', uid && token(uid));

async function expectAllowed(promise, label) {
  const res = await promise;
  assert.equal(res.status, 200, `${label} should be ALLOWED: ${await res.text()}`);
  console.log('PASS  allow  ' + label);
  checks++;
}
// A permitted read of a missing document returns 404 rather than 403.
async function expectReadableMissing(promise, label) {
  const res = await promise;
  assert.equal(res.status, 404, `${label} should be ALLOWED (404): ${await res.text()}`);
  console.log('PASS  allow  ' + label);
  checks++;
}
async function expectDenied(promise, label) {
  const res = await promise;
  const body = await res.text();
  assert.ok(
    res.status === 403 || res.status === 400,
    `${label} should be DENIED but got ${res.status}: ${body}`,
  );
  assert.match(body, /PERMISSION_DENIED|permission/i, label + ': ' + body);
  console.log('PASS  deny   ' + label);
  checks++;
}

// Colombo slot helpers (UTC+05:30), identical to BookingPolicy.
const offset = 330 * 60000;
const colomboDate = (days) =>
  new Date(Date.now() + offset + days * 86400000).toISOString().slice(0, 10);
const instant = (date, hhmm) => {
  const [y, m, d] = date.split('-').map(Number);
  const [h, mi] = hhmm.split(':').map(Number);
  return new Date(Date.UTC(y, m - 1, d, h, mi) - offset);
};
const lock = (pro, date, start) => `${pro}_${date}_${start.replace(':', '')}`;

// ------------------------------------------------------------------ setup
const rules = readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');
const loaded = await call(
  `http://${host}/emulator/v1/projects/${project}:securityRules`,
  'PUT',
  'owner',
  {rules: {files: [{name: 'firestore.rules', content: rules}]}},
);
assert.equal(loaded.status, 200, 'Rules failed to load: ' + (await loaded.text()));

const A = 'customer-a';
const B = 'customer-b';
const P = 'provider-p';
await seed(`users/${A}`, {uid: A, name: 'A', email: 'a@x.test', role: 'customer'});
await seed(`users/${B}`, {uid: B, name: 'B', email: 'b@x.test', role: 'customer'});
await seed(`users/${P}`, {uid: P, name: 'P', email: 'p@x.test', role: 'provider'});
// P is an admin-verified provider (only verified providers can act on jobs).
await seed(`providerVerifications/${P}`, {providerId: P, status: 'verified', providerCode: 'HCP-1000'});

const D = colomboDate(3);
const L1 = lock(P, D, '10:30');
const L2 = lock(P, D, '15:30');
const base = {
  customerId: A,
  providerId: P,
  serviceName: 'AC Deep Clean',
  customerName: 'A',
  address: 'No. 42 Galle Road, Colombo 03',
  status: 'confirmed',
  totalAmount: 5500,
  serviceFee: 200,
  laborCharge: 5300,
  paymentMethod: 'card',
  cardLast4: '8821',
  paymentStatus: 'escrow',
  accessNotes: '',
  jobNotes: '',
  photoUrls: [],
};
await seed('bookings/b1', {
  ...base,
  slotDate: D,
  startTime: '10:30',
  endTime: '12:00',
  scheduledAt: instant(D, '10:30'),
  endAt: instant(D, '12:00'),
  slotLockId: L1,
});
await seed(`slotLocks/${L1}`, {providerId: P, date: D, startTime: '10:30', endTime: '12:00', bookingId: 'b1'});
await seed('bookings/b2', {
  ...base,
  customerId: B,
  slotDate: D,
  startTime: '15:30',
  endTime: '17:00',
  scheduledAt: instant(D, '15:30'),
  endAt: instant(D, '17:00'),
  slotLockId: L2,
});
await seed(`slotLocks/${L2}`, {providerId: P, date: D, startTime: '15:30', endTime: '17:00', bookingId: 'b2'});
// Starts in one hour: inside the 2-hour window, unpaid cash job.
await seed('bookings/late', {
  ...base,
  status: 'pending',
  paymentMethod: 'cash',
  paymentStatus: 'unpaid',
  cardLast4: null,
  totalAmount: 3300,
  scheduledAt: new Date(Date.now() + 3600000),
});
await seed('bookings/done', {...base, status: 'completed', paymentStatus: 'paid'});
await seed('receipts/done', {customerId: A, providerId: P, receiptNumber: 'INV-1', totalAmount: 5500});
await seed('bookings/req', {...base, status: 'pending', paymentStatus: 'unpaid'});
// A second completed job, owned by customer B, for the rating-total tests.
await seed('bookings/done2', {...base, customerId: B, customerName: 'B', status: 'completed', paymentStatus: 'paid'});

// ---------------------------------------------------------------- addresses
const address = {
  type: 'home', label: 'Home', houseNumber: 'No. 42', street: 'Galle Road',
  city: 'Colombo 03', postalCode: '00300', province: 'Western Province',
  landmark: '', accessNotes: '', latitude: 6.9, longitude: 79.8, isDefault: true,
};
await expectAllowed(
  commit(A, [set(`users/${A}/addresses/home`, address, ['createdAt', 'updatedAt'])]),
  'customer creates own address',
);
await expectDenied(get(B, `users/${A}/addresses/home`), 'other customer reads address');
await expectDenied(
  commit(B, [set(`users/${A}/addresses/evil`, address, ['createdAt', 'updatedAt'])]),
  'other customer writes into address book',
);
await expectDenied(
  commit(A, [set(`users/${A}/addresses/bad`, {...address, street: ''}, ['createdAt', 'updatedAt'])]),
  'address without street',
);
await expectDenied(
  commit(A, [set(`users/${A}/addresses/bad2`, {...address, isAdmin: true}, ['createdAt', 'updatedAt'])]),
  'address with unknown field',
);
await expectAllowed(
  commit(A, [patch(`users/${A}/addresses/home`, {isDefault: false}, ['updatedAt'])]),
  'customer toggles default flag',
);
await expectAllowed(commit(A, [del(`users/${A}/addresses/home`)]), 'customer deletes address');

// ----------------------------------------------------------------- bookings
await expectAllowed(get(A, 'bookings/b1'), 'customer reads own booking');
const query = (uid, field, equals) =>
  call(`${root}:runQuery`, 'POST', uid && token(uid), {
    structuredQuery: {
      from: [{collectionId: 'bookings'}],
      where: {fieldFilter: {field: {fieldPath: field}, op: 'EQUAL', value: {stringValue: equals}}},
    },
  });
await expectAllowed(query(A, 'customerId', A), 'Booking History query (own customerId)');
await expectDenied(query(B, 'customerId', A), "query another customer's bookings");
await expectDenied(query(A, 'status', 'confirmed'), 'unscoped bookings query');
await expectAllowed(query(P, 'providerId', P), 'provider jobs query (own providerId)');
await expectDenied(get(B, 'bookings/b1'), "customer reads another's booking");
await expectDenied(get(null, 'bookings/b1'), 'unauthenticated read');
await expectAllowed(
  commit(A, [patch('bookings/b1', {accessNotes: 'Ring 2B', jobNotes: 'Rattling', contactPhone: '+94771234567'}, ['updatedAt'])]),
  'customer edits notes/phone',
);
await expectDenied(
  commit(A, [patch('bookings/b1', {totalAmount: 1}, ['updatedAt'])]),
  'customer changes price',
);
await expectDenied(
  commit(A, [patch('bookings/b1', {status: 'completed'}, ['updatedAt'])]),
  'customer marks job complete',
);
await expectDenied(
  commit(A, [patch('bookings/b1', {photoUrls: ['1', '2', '3', '4', '5', '6']}, ['updatedAt'])]),
  'more than 5 photos',
);
await expectDenied(
  commit(B, [patch('bookings/b1', {accessNotes: 'hijack'}, ['updatedAt'])]),
  "customer edits another's booking",
);

// --------------------------------------------------------------- reschedule
const L3 = lock(P, D, '13:30');
const move = (start, end, lockId, scheduledAt = instant(D, start)) =>
  patch('bookings/b1', {
    slotDate: D, startTime: start, endTime: end, scheduledAt,
    endAt: instant(D, end), slotLockId: lockId,
  }, ['rescheduledAt', 'updatedAt']);
const lockDoc = (start, end) => ({providerId: P, date: D, startTime: start, endTime: end, bookingId: 'b1'});

await expectDenied(
  commit(A, [set(`slotLocks/${L2}`, lockDoc('15:30', '17:00')), del(`slotLocks/${L1}`), move('15:30', '17:00', L2)]),
  'double-book a slot held by another booking',
);
await expectDenied(
  commit(A, [set(`slotLocks/${L3}`, lockDoc('13:30', '15:00')), del(`slotLocks/${L1}`),
    move('13:30', '15:00', L3, instant(D, '14:30'))]),
  'reschedule with forged scheduledAt',
);
await expectDenied(
  commit(A, [set(`slotLocks/${L3}`, lockDoc('13:30', '15:00')), move('13:30', '15:00', L3)]),
  'reschedule without releasing old lock',
);
await expectDenied(commit(B, [del(`slotLocks/${L1}`)]), "delete another customer's slot lock");
await expectAllowed(
  commit(A, [set(`slotLocks/${L3}`, lockDoc('13:30', '15:00')), del(`slotLocks/${L1}`), move('13:30', '15:00', L3)]),
  'reschedule to a free slot (lock + release + update)',
);
const today = colomboDate(0);
const soon = new Date(Date.now() + 30 * 60000 + offset);
const soonHHMM = soon.toISOString().slice(11, 16);
if (soon.toISOString().slice(0, 10) === today && soonHHMM < '22:00') {
  const endHHMM = String(Number(soonHHMM.slice(0, 2)) + 1).padStart(2, '0') + soonHHMM.slice(2);
  const L4 = lock(P, today, soonHHMM);
  await expectDenied(
    commit(A, [
      set(`slotLocks/${L4}`, {providerId: P, date: today, startTime: soonHHMM, endTime: endHHMM, bookingId: 'b1'}),
      del(`slotLocks/${L3}`),
      patch('bookings/b1', {
        slotDate: today, startTime: soonHHMM, endTime: endHHMM,
        scheduledAt: instant(today, soonHHMM), endAt: instant(today, endHHMM), slotLockId: L4,
      }, ['rescheduledAt', 'updatedAt']),
    ]),
    'reschedule into a slot less than 2 hours away',
  );
}

// ------------------------------------------------------- cancel and refund
const cancel = (data) =>
  patch('bookings/b1', {
    status: 'cancelled', cancellationReason: 'Changed my plans',
    cancellationFee: dbl(0), refundAmount: dbl(5500), paymentStatus: 'refund_pending',
    slotLockId: null, ...data,
  }, ['cancelledAt', 'updatedAt']);
const refund = (data) =>
  set('refunds/b1', {
    bookingId: 'b1', customerId: A, amount: dbl(5500), cancellationFee: dbl(0),
    percentage: 100, method: 'card', cardLast4: '8821',
    refundReference: 'REF-123456', reason: 'Changed my plans',
    status: 'initiated', ...data,
  }, ['createdAt']);

await expectDenied(
  commit(A, [cancel({refundAmount: 9999}), del(`slotLocks/${L3}`), refund({amount: 9999})]),
  'cancel with inflated refund',
);
await expectDenied(
  commit(A, [cancel({}), del(`slotLocks/${L3}`)]),
  'cancel prepaid booking without refund record',
);
await expectDenied(
  commit(A, [cancel({}), refund({})]),
  'cancel without releasing the slot',
);
await expectDenied(
  commit(A, [cancel({}), del(`slotLocks/${L3}`), refund({status: 'refunded'})]),
  'customer marks own refund as refunded',
);
await expectReadableMissing(get(A, 'refunds/b1'), 'customer watches refund before it exists');
await expectAllowed(
  commit(A, [cancel({}), del(`slotLocks/${L3}`), refund({})]),
  'free cancellation with full refund',
);
await expectDenied(
  commit(A, [cancel({})]),
  'cancel an already cancelled booking',
);
await expectDenied(
  commit(A, [patch('refunds/b1', {status: 'refunded'})]),
  'customer advances refund status',
);
await expectAllowed(get(A, 'refunds/b1'), 'customer reads own refund');
await expectDenied(get(B, 'refunds/b1'), "customer reads another's refund");
await expectDenied(
  commit(A, [set('refunds/late', {bookingId: 'late', customerId: A, amount: 1, cancellationFee: 0, percentage: 100,
    method: 'cash', cardLast4: null, refundReference: 'REF-000001', reason: 'Other', status: 'initiated'}, ['createdAt'])]),
  'refund for a booking that is not being cancelled',
);
const lateCancel = (fee) =>
  patch('bookings/late', {
    status: 'cancelled', cancellationReason: 'Other', cancellationFee: fee,
    refundAmount: 0, paymentStatus: 'unpaid', slotLockId: null,
  }, ['cancelledAt', 'updatedAt']);
await expectDenied(commit(A, [lateCancel(0)]), 'late cancellation without the 20% fee');
await expectAllowed(commit(A, [lateCancel(dbl(660))]), 'late cancellation with 20% fee (unpaid, no refund)');

// --------------------------------------------- receipts, reviews, disputes
await expectAllowed(get(A, 'receipts/done'), 'customer reads own receipt');
await expectDenied(get(B, 'receipts/done'), "customer reads another's receipt");
await expectDenied(
  commit(A, [set('receipts/b2', {customerId: A, totalAmount: 1})]),
  'customer forges a receipt',
);
const review = (id, extra = {}) =>
  set(`reviews/${id}`, {bookingId: id, customerId: A, providerId: P, customerName: 'A',
    serviceName: 'AC Deep Clean', rating: 5, tags: ['On Time', 'Clean Work'], comment: 'Great',
    recommend: true, ...extra}, ['createdAt']);
// The provider's running rating total, written in the same commit as a review.
const stats = (id, sum, count, extra = {}) =>
  set('ratingStats/' + P, {providerId: P, ratingSum: sum, ratingCount: count, lastReviewId: id, ...extra}, ['updatedAt']);
const reviewNote = (id, extra = {}) =>
  set(`notifications/review_${id}`, {recipientId: P, senderId: A, type: 'review', bookingId: id,
    title: 'New review from A', body: '5 stars for AC Deep Clean', rating: 5, read: false, ...extra}, ['createdAt']);
await expectDenied(commit(A, [review('req'), stats('req', 5, 1)]), 'review before job completion');
await expectDenied(commit(A, [review('done', {tags: ['Free pizza']}), stats('done', 5, 1)]), 'review with a made-up highlight tag');
await expectDenied(commit(A, [review('done', {rating: 6}), stats('done', 6, 1)]), 'review with 6 stars');
await expectDenied(commit(A, [reviewNote('done')]), 'review notification without its review');
await expectDenied(
  commit(A, [review('done'), stats('done', 5, 1), reviewNote('done', {recipientId: B})]),
  'review notification addressed to someone other than the job provider',
);
await expectDenied(
  commit(A, [review('done'), stats('done', 5, 1), reviewNote('done', {rating: 1})]),
  'review notification that misstates the rating',
);
await expectDenied(commit(A, [review('done'), reviewNote('done')]), 'review that skips the provider rating total');
await expectDenied(commit(A, [review('done'), stats('done', 50, 1), reviewNote('done')]), 'review that inflates the rating total');
await expectDenied(commit(A, [review('done'), stats('done', 5, 2), reviewNote('done')]), 'review that inflates the review count');
await expectDenied(commit(A, [stats('done', 5, 1)]), 'rating total written without a review');
await expectDenied(commit(A, [review('done'), stats('req', 5, 1), reviewNote('done')]), 'rating total pointing at a different review');
await expectAllowed(commit(A, [review('done'), stats('done', 5, 1), reviewNote('done')]), 'review a completed job + update rating total + notify the provider');
await expectAllowed(get(B, 'ratingStats/' + P), 'any signed-in user reads a provider overall rating');
await expectAllowed(get(P, 'ratingStats/' + P), 'provider reads own overall rating');
await expectDenied(commit(A, [patch('ratingStats/' + P, {ratingSum: 999})]), 'customer edits a rating total directly');
await expectDenied(commit(B, [stats('done', 10, 2)]), 're-counting an already counted review');
await expectDenied(
  commit(B, [set('reviews/done2', {bookingId: 'done2', customerId: B, providerId: P, customerName: 'B', serviceName: 'AC Deep Clean',
    rating: 3, tags: [], comment: 'ok', recommend: false}, ['createdAt']), stats('done2', 10, 2)]),
  'second review that adds the wrong number of stars',
);
await expectAllowed(
  commit(B, [set('reviews/done2', {bookingId: 'done2', customerId: B, providerId: P, customerName: 'B', serviceName: 'AC Deep Clean',
    rating: 3, tags: [], comment: 'ok', recommend: false}, ['createdAt']), stats('done2', 8, 2)]),
  'a second customer review moves the total by exactly its stars (5 + 3 = 8 over 2)',
);
await expectDenied(commit(A, [review('done')]), 'overwrite an existing review');
await expectAllowed(get(A, 'reviews/done'), 'customer reads own review');
await expectAllowed(get(P, 'reviews/done'), 'provider reads the review of their job');
await expectDenied(get(B, 'reviews/done'), "another customer reads someone else's review");
await expectAllowed(get(P, 'notifications/review_done'), 'provider reads own notification');
await expectDenied(get(A, 'notifications/review_done'), 'sender reads a notification addressed to the provider');
await expectDenied(get(B, 'notifications/review_done'), "another user reads someone else's notification");
await expectDenied(
  commit(A, [patch('notifications/review_done', {read: true})]),
  'customer edits the provider notification',
);
await expectDenied(
  commit(P, [patch('notifications/review_done', {title: 'Hacked'})]),
  'provider rewrites a notification title',
);
await expectAllowed(
  commit(P, [patch('notifications/review_done', {read: true})]),
  'provider marks own notification read',
);
await expectDenied(commit(P, [del('notifications/review_done')]), 'provider deletes a notification');

// ----------------------- edit / delete a review (state: A=5 on done, B=3 on done2 -> sum 8, count 2)
const editReview = (id, rating, extra = {}) =>
  patch(`reviews/${id}`, {rating, tags: [], comment: 'Changed my mind', recommend: false, ...extra}, ['updatedAt']);
const editNote = (id, rating, extra = {}) =>
  patch(`notifications/review_${id}`, {title: 'Review updated by A', body: `${rating} stars for AC Deep Clean`,
    rating, read: false, ...extra}, ['createdAt']);
await expectDenied(commit(A, [editReview('done', 2), editNote('done', 2)]), 'edit a review without moving the provider rating total');
await expectDenied(
  commit(A, [editReview('done', 2), stats('done', 8, 2), editNote('done', 2)]),
  'edit a review but leave the rating total unchanged',
);
await expectDenied(
  commit(A, [editReview('done', 2), stats('done', 9, 2), editNote('done', 2)]),
  'edit a review with a wrong rating total',
);
await expectDenied(
  commit(A, [editReview('done', 2), stats('done', 5, 3), editNote('done', 2)]),
  'edit a review that also bumps the review count',
);
await expectDenied(
  commit(P, [editReview('done', 5), stats('done', 8, 2)]),
  "provider edits a customer's review",
);
await expectDenied(
  commit(B, [editReview('done', 1), stats('done', 4, 2)]),
  "another customer edits someone else's review",
);
await expectDenied(
  commit(A, [editReview('done', 2, {customerName: 'Somebody else'}), stats('done', 5, 2), editNote('done', 2)]),
  'edit that rewrites who the review is from',
);
await expectDenied(
  commit(A, [editReview('done', 2, {tags: ['Free pizza']}), stats('done', 5, 2), editNote('done', 2)]),
  'edit with a made-up highlight tag',
);
await expectDenied(
  commit(A, [editReview('done', 2), stats('done', 5, 2), editNote('done', 4)]),
  'edit whose notification misstates the new rating',
);
await expectAllowed(
  commit(A, [editReview('done', 2), stats('done', 5, 2), editNote('done', 2)]),
  'customer edits own review: stars 5 -> 2, total 8 -> 5, provider notified again',
);
await expectAllowed(get(P, 'notifications/review_done'), 'provider still reads the refreshed notification');
await expectDenied(commit(P, [del('reviews/done'), stats('done', 3, 1)]), "provider deletes a customer's review");
await expectDenied(commit(B, [del('reviews/done'), stats('done', 3, 1)]), "another customer deletes someone else's review");
await expectDenied(commit(A, [del('reviews/done'), del('notifications/review_done')]), 'delete a review without moving the rating total');
await expectDenied(
  commit(A, [del('reviews/done'), stats('done', 5, 1), del('notifications/review_done')]),
  'delete a review but keep its stars in the total',
);
await expectDenied(
  commit(A, [del('reviews/done'), stats('done', 3, 2), del('notifications/review_done')]),
  'delete a review but keep it in the review count',
);
await expectAllowed(
  commit(A, [del('reviews/done'), stats('done', 3, 1), del('notifications/review_done')]),
  'customer deletes own review: stars leave the total (5 -> 3), notification removed',
);
await expectReadableMissing(get(A, 'reviews/done'), 'deleted review is gone');
await expectAllowed(
  commit(A, [review('done'), stats('done', 8, 2), reviewNote('done')]),
  'customer can review the job again after deleting; it counts once (3 -> 8 over 2)',
);

// ---------------------------------------------- provider flow (regression)
await expectDenied(
  commit(A, [patch('bookings/req', {status: 'confirmed'}, ['acceptedAt'])]),
  'customer accepts own request as provider',
);
await expectAllowed(
  commit(P, [patch('bookings/req', {status: 'confirmed'}, ['acceptedAt'])]),
  'provider accepts assigned request',
);
await expectAllowed(get(P, 'bookings/req'), 'provider reads assigned booking');

// ------------------------------------------- provider verification (admin)
const ADM = 'admin-1';
const NP = 'provider-new';
const NP2 = 'provider-new-2';
const NP3 = 'provider-unverified';
const NP4 = 'provider-minimal';
await seed(`users/${ADM}`, {uid: ADM, name: 'Admin', email: 'admin@admin.homecare.app', role: 'admin'});

// ------------------------------------------- disputes (3-day warranty claims)
// Fresh job (completed a day ago), stale job (completed four days ago).
const DAY = 86400000;
await seed('bookings/fresh', {...base, status: 'completed', paymentStatus: 'paid', completedAt: new Date(Date.now() - DAY)});
await seed('bookings/stale', {...base, status: 'completed', paymentStatus: 'paid', completedAt: new Date(Date.now() - 4 * DAY)});
await seed('bookings/fresh2', {...base, customerId: B, customerName: 'B', status: 'completed', paymentStatus: 'paid', completedAt: new Date(Date.now() - DAY)});
const dispute = (id, who, extra = {}) =>
  set(`disputes/${id}`, {bookingId: id, customerId: who, providerId: P,
    reason: 'Poor work quality', tag: 'Defective repair', description: 'Breaker keeps tripping after the repair.',
    status: 'pending', photoCount: 2, respondDeadline: new Date(Date.now() + 24 * 3600000),
    adminNote: null, decision: null, refundAmount: null, providerResponse: null, ...extra}, ['createdAt']);
const disputePhoto = (id, slot, extra = {}) =>
  set(`disputes/${id}/photos/${slot}`, {base64: 'aGVsbG8=', mimeType: 'image/jpeg', sizeBytes: 5, ...extra}, ['createdAt']);
const disputeNote = (id, extra = {}) =>
  set(`notifications/dispute_${id}`, {recipientId: P, senderId: A, type: 'dispute', bookingId: id,
    title: 'Problem reported on AC Deep Clean', body: 'A reported a problem. Please respond within 24 hours.',
    read: false, ...extra}, ['createdAt']);
await expectAllowed(
  commit(A, [dispute('fresh', A), disputePhoto('fresh', 'p0'), disputePhoto('fresh', 'p1'), disputeNote('fresh')]),
  'customer files a dispute with 2 photos and notifies the provider (inside the 3-day warranty)',
);
await expectDenied(commit(A, [dispute('fresh', A)]), 'second dispute for the same booking');
await expectDenied(commit(A, [dispute('stale', A)]), 'dispute after the 3-day warranty ended');
await expectDenied(commit(A, [dispute('req', A)]), 'dispute on a job that is not completed');
await expectDenied(commit(A, [dispute('done2', A)]), "dispute on another customer's booking");
await expectDenied(commit(B, [dispute('fresh2', B, {reason: 'Because I said so'})]), 'dispute with a made-up reason');
await expectDenied(commit(B, [dispute('fresh2', B, {description: 'short'})]), 'dispute with a too-short description');
await expectDenied(commit(B, [dispute('fresh2', B, {status: 'resolved'})]), 'dispute created already resolved');
await expectDenied(commit(B, [dispute('fresh2', B, {decision: 'refund', refundAmount: 5000})]), 'dispute created with its own refund decision');
await expectDenied(commit(B, [dispute('fresh2', B, {respondDeadline: new Date(Date.now() + 10 * DAY)})]), 'dispute with a far-off respond deadline');
await expectDenied(commit(B, [dispute('fresh2', B, {photoCount: 6})]), 'dispute claiming six photos');
await expectDenied(commit(B, [dispute('fresh2', B), disputePhoto('fresh2', 'p5')]), 'sixth photo slot');
await expectDenied(commit(B, [dispute('fresh2', B), disputePhoto('fresh2', 'p0', {base64: 'A'.repeat(960000)})]), 'photo bigger than a document can hold');
await expectDenied(commit(B, [dispute('fresh2', B), disputePhoto('fresh2', 'p0', {mimeType: 'application/pdf'})]), 'photo that is not an image');
await expectDenied(commit(B, [dispute('fresh2', B), disputeNote('fresh2', {senderId: B, recipientId: B})]), 'dispute notice sent to the wrong person');
await expectDenied(commit(B, [disputeNote('fresh2', {senderId: B})]), 'dispute notice without a dispute');
await expectAllowed(get(A, 'disputes/fresh'), 'customer reads own dispute');
await expectDenied(get(B, 'disputes/fresh'), "customer reads another's dispute");
await expectDenied(get(A, 'disputes'), 'customer lists all disputes');
await expectAllowed(get(A, 'disputes/fresh/photos/p0'), 'customer reads own dispute photo');
await expectDenied(get(B, 'disputes/fresh/photos/p0'), "customer reads another's dispute photo");
await expectAllowed(
  commit(A, [patch('disputes/fresh', {description: 'Breaker still trips. Need an urgent inspection.', photoCount: 1}, ['updatedAt']), disputePhoto('fresh', 'p0'), del('disputes/fresh/photos/p1')]),
  'customer edits a pending dispute (text and photos)',
);
await expectDenied(commit(A, [patch('disputes/fresh', {status: 'resolved'}, ['updatedAt'])]), 'customer resolves own dispute');
await expectDenied(commit(A, [patch('disputes/fresh', {refundAmount: 5500}, ['updatedAt'])]), 'customer sets own refund amount');
await expectDenied(commit(B, [patch('disputes/fresh', {description: 'Not my dispute but editing it.'}, ['updatedAt'])]), "customer edits another's dispute");
await expectAllowed(
  commit(ADM, [patch('disputes/fresh', {status: 'under_review'}, ['updatedAt'])]),
  'safety desk moves the dispute to under review',
);
await expectDenied(
  commit(A, [patch('disputes/fresh', {description: 'Changing it after review began.'}, ['updatedAt'])]),
  'customer edits a dispute that is under review',
);
await expectDenied(commit(A, [disputePhoto('fresh', 'p2')]), 'customer adds a photo after review began');
await expectDenied(
  commit(A, [del('disputes/fresh/photos/p0'), del('notifications/dispute_fresh'), del('disputes/fresh')]),
  'customer withdraws a dispute that is under review',
);
await expectAllowed(
  commit(ADM, [patch('disputes/fresh', {status: 'resolved', decision: 'Refund approved', refundAmount: 2500, adminNote: 'Part refund.'}, ['updatedAt'])]),
  'safety desk resolves the dispute with a refund decision',
);
// Withdrawing: B files, then withdraws while it is still pending.
await expectAllowed(
  commit(B, [dispute('fresh2', B, {photoCount: 1}), disputePhoto('fresh2', 'p0'), disputeNote('fresh2', {senderId: B})]),
  'second customer files a dispute',
);
await expectDenied(commit(A, [del('disputes/fresh2')]), "customer withdraws another's dispute");
await expectAllowed(
  commit(B, [del('disputes/fresh2/photos/p0'), del('notifications/dispute_fresh2'), del('disputes/fresh2')]),
  'customer withdraws a pending dispute (photos and provider notice removed)',
);
await expectAllowed(
  commit(B, [dispute('fresh2', B, {photoCount: 0}), disputeNote('fresh2', {senderId: B})]),
  'customer can file again after withdrawing (warranty still open)',
);
for (const [uid, name] of [[NP, 'New Pro'], [NP2, 'New Pro Two'], [NP3, 'Unverified Pro'], [NP4, 'Name Only']]) {
  await seed(`users/${uid}`, {uid, name, email: `${uid}@x.test`, role: 'provider'});
}
const file = (n) => ({name: n, url: 'https://example.test/' + n});
const submission = (uid, extra = {}) =>
  set(`providerVerifications/${uid}`, {
    providerId: uid, fullName: 'New Pro', phone: '+94771234567', profession: 'Plumber',
    experienceYears: 3, about: '', idType: 'nic', idNumber: '928471923V',
    idFront: file('front.jpg'), idBack: file('back.jpg'), selfie: file('selfie.jpg'),
    cv: file('cv.pdf'), certificates: [file('cert.pdf')], experiences: [], status: 'pending', ...extra,
  }, ['submittedAt']);
const noStatus = (uid, drop) => {
  const w = submission(uid);
  delete w.update.fields[drop];
  return w;
};

await expectDenied(commit(NP2, [submission(NP)]), "provider submits for someone else's account");
await expectDenied(commit(A, [submission(A)]), 'customer submits a provider verification');
await expectDenied(commit(NP, [submission(NP, {status: 'verified'})]), 'provider approves their own verification');
await expectDenied(commit(NP, [submission(NP, {providerCode: 'HCP-1001'})]), 'provider writes their own Provider ID');
// Sign-up is relaxed: documents and most details are optional, but what is sent must still be well formed.
await expectDenied(commit(NP, [submission(NP, {fullName: 'A'})]), 'submission without a real name');
await expectDenied(commit(NP, [submission(NP, {idNumber: 'X'.repeat(21)})]), 'submission with an oversized ID number');
await expectDenied(commit(NP, [submission(NP, {selfie: {name: 'selfie.jpg'}})]), 'submission with a malformed document');
await expectDenied(commit(NP, [submission(NP, {certificates: [file('1.pdf'), file('2.pdf'), file('3.pdf'), file('4.pdf'), file('5.pdf'), file('6.pdf')]})]), 'submission with six certificates');
await expectDenied(commit(NP, [noStatus(NP, 'fullName')]), 'submission without a name field');
const minimal = (uid) => set(`providerVerifications/${uid}`, {providerId: uid, fullName: 'Name Only', phone: '', profession: '',
  experienceYears: 0, about: '', idType: 'nic', idNumber: '', certificates: [], experiences: [], status: 'pending'}, ['submittedAt']);
await expectAllowed(commit(NP4, [minimal(NP4)]), 'provider submits with only a name (no documents yet)');
await expectAllowed(get(ADM, `providerVerifications/${NP4}`), 'admin sees a submission without documents');
await expectAllowed(commit(NP, [submission(NP, {experiences: [{title: 'Site helper', company: 'ABC', years: 2}]})]), 'provider submits details, ID, selfie, CV and certificate (+ optional experience)');
await expectAllowed(commit(NP2, [submission(NP2)]), 'a second provider submits (no optional experience)');
await expectAllowed(get(NP, `providerVerifications/${NP}`), 'provider reads own submission');
await expectDenied(get(NP2, `providerVerifications/${NP}`), "provider reads another provider's submission");
await expectDenied(get(A, `providerVerifications/${NP}`), "customer reads a provider's submission");
await expectAllowed(get(ADM, `providerVerifications/${NP}`), 'admin reads a submission');
await expectAllowed(get(ADM, 'providerVerifications'), 'admin lists submissions');
await expectDenied(get(NP, 'providerVerifications'), 'provider lists all submissions');
await expectDenied(commit(NP, [patch(`providerVerifications/${NP}`, {about: 'edited while pending'})]), 'provider edits a pending submission');

const adminReview = (uid, status, extra = {}) =>
  patch(`providerVerifications/${uid}`, {status, reviewedBy: ADM, ...extra}, ['reviewedAt']);
const publicProfile = (uid, code) =>
  set(`professionals/${uid}`, {name: 'New Pro', specialty: 'Plumber', phone: '+94771234567', verified: true,
    providerCode: code, completedJobs: 0, area: ''});
const verifyNote = (id, to) =>
  set(`notifications/${id}`, {recipientId: to, senderId: ADM, type: 'verification', bookingId: '',
    title: 'You are verified!', body: 'Your Provider ID is HCP-1001. You can now accept jobs.', read: false}, ['createdAt']);

await expectDenied(commit(NP, [adminReview(NP, 'verified', {providerCode: 'HCP-1001'})]), 'provider verifies themselves');
await expectDenied(commit(A, [adminReview(NP, 'verified', {providerCode: 'HCP-1001'})]), 'customer verifies a provider');
await expectDenied(commit(ADM, [adminReview(NP, 'verified')]), 'admin verifies without a Provider ID');
await expectDenied(commit(ADM, [adminReview(NP, 'rejected', {rejectionReason: 'no'})]), 'admin sends back without a real reason');
await expectDenied(commit(ADM, [patch(`providerVerifications/${NP}`, {status: 'verified', providerCode: 'HCP-1001', reviewedBy: ADM, fullName: 'Changed'}, ['reviewedAt'])]), 'admin changes the submitted details while verifying');
await expectDenied(commit(NP, [set('professionals/' + NP, {name: 'Fake', verified: true})]), 'provider publishes their own verified profile');
await expectDenied(commit(ADM, [set('counters/providerIds', {last: 5})]), 'admin starts the Provider ID counter at 5');
await expectDenied(commit(NP, [set('counters/providerIds', {last: 1})]), 'provider moves the Provider ID counter');
await expectDenied(commit(A, [verifyNote('v0', NP)]), 'customer sends a verification notification');
await expectAllowed(
  commit(ADM, [adminReview(NP, 'verified', {providerCode: 'HCP-1001'}), set('counters/providerIds', {last: 1}),
    publicProfile(NP, 'HCP-1001'), verifyNote('v1', NP)]),
  'admin verifies: Provider ID HCP-1001, public profile, counter, notification',
);
await expectAllowed(get(NP, 'notifications/v1'), 'verified provider reads the verification notification');
await expectDenied(get(NP2, 'notifications/v1'), "another provider reads someone else's notification");
await expectAllowed(get(A, `professionals/${NP}`), 'customers can read the verified provider profile');
await expectDenied(commit(ADM, [adminReview(NP, 'verified', {providerCode: 'HCP-1009'}), set('counters/providerIds', {last: 2})]), 'verifying an already verified provider again');
await expectDenied(commit(NP, [submission(NP)]), 'a verified provider overwrites their approved verification');
await expectDenied(commit(ADM, [set('counters/providerIds', {last: 9})]), 'admin jumps the Provider ID counter');

await expectAllowed(
  commit(ADM, [adminReview(NP2, 'rejected', {rejectionReason: 'ID photo is blurry, please re-upload.'}),
    set(`notifications/v2`, {recipientId: NP2, senderId: ADM, type: 'verification', bookingId: '',
      title: 'Verification needs changes', body: 'ID photo is blurry, please re-upload.', read: false}, ['createdAt'])]),
  'admin sends a submission back with a reason',
);
await expectAllowed(commit(NP2, [submission(NP2, {fullName: 'New Pro Two'})]), 'provider fixes and resubmits after being sent back');
await expectAllowed(
  commit(ADM, [adminReview(NP2, 'verified', {providerCode: 'HCP-1002'}), set('counters/providerIds', {last: 2}),
    publicProfile(NP2, 'HCP-1002')]),
  'admin verifies the resubmission (second Provider ID)',
);

// Unverified providers cannot take jobs; the moment they are verified they can.
await seed('bookings/req3', {...base, providerId: NP3, status: 'pending', paymentStatus: 'unpaid'});
await expectDenied(
  commit(NP3, [patch('bookings/req3', {status: 'confirmed'}, ['acceptedAt'])]),
  'unverified provider accepts a job',
);
await seed(`providerVerifications/${NP3}`, {providerId: NP3, status: 'verified', providerCode: 'HCP-1003'});
await expectAllowed(
  commit(NP3, [patch('bookings/req3', {status: 'confirmed'}, ['acceptedAt'])]),
  'the same provider accepts the job once verified',
);

// ------------------------------------------------------ new booking (create)
// Replays CustomerBookingService.createBooking: booking set + slot lock set
// with an "absent" precondition, committed in one transaction.
const PP = 'provider-priced';
const PI = 'provider-inspection';
await seed(`users/${PP}`, {uid: PP, name: 'Priced Pro', email: 'pp@x.test', role: 'provider'});
await seed(`users/${PI}`, {uid: PI, name: 'Amal Perera', email: 'pi@x.test', role: 'provider'});
await seed(`professionals/${PP}`, {name: 'Priced Pro', specialty: 'Plumber', pricing: 2500});
await seed(`professionals/${PI}`, {name: 'Amal Perera', specialty: 'AC technician', pricing: null});

const ND = colomboDate(5);
const newBooking = (id, {uid = A, pro = PP, price = dbl(2500), start = '10:30', end = '12:00',
  booking = {}, lockData = {}, absent = true} = {}) => {
  const lockId = lock(pro, ND, start);
  return commit(uid, [
    set(`bookings/${id}`, {
      reference: 'BK-51693', customerId: uid, customerName: 'A', providerId: pro,
      providerName: 'Pro', serviceName: 'AC technician', status: 'pending',
      slotDate: ND, startTime: start, endTime: end,
      scheduledAt: instant(ND, start), endAt: instant(ND, end), slotLockId: lockId,
      addressId: 'home', address: 'No. 42 Galle Road, Colombo 03', addressLabel: 'Home',
      addressArea: '', accessNotes: '', contactPhone: '', jobNotes: '', photoUrls: [],
      estimatedPrice: price, totalAmount: price, laborCharge: price, serviceFee: 0,
      paymentStatus: 'unpaid', ...booking,
    }, ['createdAt', 'updatedAt']),
    {
      ...set(`slotLocks/${lockId}`, {providerId: pro, date: ND, startTime: start, endTime: end,
        bookingId: id, ...lockData}),
      ...(absent && {currentDocument: {exists: false}}),
    },
  ]);
};

await expectAllowed(newBooking('nb1'), 'customer books a priced provider (booking + slot lock)');
await expectAllowed(newBooking('nb2', {pro: PI, price: null}), 'customer books an on-inspection provider with no price');
await expectDenied(newBooking('nb3', {absent: false}), 'second customer double-books the same slot');
await expectDenied(newBooking('nb3', {uid: B, absent: false}), 'another customer double-books the same slot');
await expectDenied(newBooking('nb4', {start: '13:30', end: '15:00', booking: {customerId: B}}), 'customer creates a booking for another customer');
await expectDenied(newBooking('nb5', {start: '13:30', end: '15:00', booking: {paymentStatus: 'paid'}}), 'new booking marked as paid');
await expectDenied(newBooking('nb6', {start: '13:30', end: '15:00', price: dbl(100)}), 'new booking with a fake lower price');
await expectDenied(newBooking('nb7', {pro: PI, start: '13:30', end: '15:00', price: dbl(1)}), 'on-inspection booking with an invented price');
await expectDenied(newBooking('nb8', {start: '13:30', end: '15:00', booking: {status: 'confirmed'}}), 'new booking skips straight to confirmed');
await expectDenied(newBooking('nb9', {start: '13:30', end: '15:00', booking: {serviceFee: 500}}), 'new booking sets a service fee');
await expectDenied(newBooking('nb10', {start: '13:30', end: '15:00', lockData: {bookingId: 'b1'}}), 'slot lock points at a different booking');
await expectDenied(newBooking('nb11', {pro: 'no-such-provider', start: '13:30', end: '15:00', price: null}), 'booking a provider that does not exist');
await expectDenied(newBooking('nb12', {uid: P, start: '13:30', end: '15:00'}), 'a provider account books a job');
await expectDenied(newBooking('nb13', {start: '13:30', end: '15:00', booking: {isAdmin: true}}), 'new booking with an extra field');
await expectDenied(
  commit(A, [set('bookings/nb14', {customerId: A, providerId: PP, status: 'pending'}, ['createdAt', 'updatedAt'])]),
  'booking without its slot lock',
);
await expectAllowed(get(A, 'bookings/nb1'), 'customer reads the booking they just created');

console.log(`\nAll ${checks} security-rule checks passed.`);
