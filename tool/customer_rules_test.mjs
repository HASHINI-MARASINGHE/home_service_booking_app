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
const review = (id) =>
  set(`reviews/${id}`, {bookingId: id, customerId: A, providerId: P, rating: 5, comment: 'Great'}, ['createdAt']);
await expectDenied(commit(A, [review('req')]), 'review before job completion');
await expectAllowed(commit(A, [review('done')]), 'review a completed job');
await expectDenied(commit(A, [review('done')]), 'overwrite an existing review');
await expectAllowed(
  commit(A, [set('disputes/d1', {bookingId: 'done', customerId: A, providerId: P,
    category: 'Work quality', description: 'Unit still rattles after repair.', status: 'open'}, ['createdAt'])]),
  'report a problem on own booking',
);
await expectDenied(
  commit(B, [set('disputes/d2', {bookingId: 'done', customerId: B, providerId: P,
    category: 'Work quality', description: 'Not my booking at all here.', status: 'open'}, ['createdAt'])]),
  "dispute on another customer's booking",
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

console.log(`\nAll ${checks} security-rule checks passed.`);
