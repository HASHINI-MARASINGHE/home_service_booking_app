// Security-rule tests for the provider quote / price-approval flow.
// Runs against a local Firestore emulator only:
//
//   firebase emulators:exec --only firestore "node tool/quote_rules_test.mjs"
//
// Loads ./firestore.rules into an isolated demo project, then replays the
// exact writes the Flutter services make (ProviderBookingService.sendQuote /
// reviseQuote and CustomerBookingService.acceptQuote / declineQuote) as REST
// commits, next to the writes a modified client could try.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const host =
  process.env.FIRESTORE_EMULATOR_HOST || process.env.FIRESTORE_HOST || '127.0.0.1:8085';
const project = 'demo-homecare-quotes-' + Date.now();
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

// Dart writes money as doubles (3500.0); wrap a number to send it that way.
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

const stampsOf = (stamps) =>
  stamps.length
    ? {updateTransforms: stamps.map((f) => ({fieldPath: f, setToServerValue: 'REQUEST_TIME'}))}
    : {};
const set = (path, data, stamps = []) => ({
  update: {name: prefix + path, fields: fields(data)},
  ...stampsOf(stamps),
});
const patch = (path, data, stamps = []) => ({
  update: {name: prefix + path, fields: fields(data)},
  updateMask: {fieldPaths: Object.keys(data)},
  currentDocument: {exists: true},
  ...stampsOf(stamps),
});

const commit = (uid, writes) =>
  call(`${root}:commit`, 'POST', uid && token(uid), {writes});

async function read(path) {
  const res = await call(`${root}/${path}`, 'GET', 'owner');
  const text = await res.text();
  assert.equal(res.status, 200, text);
  return JSON.parse(text).fields;
}

async function expectAllowed(promise, label) {
  const res = await promise;
  assert.equal(res.status, 200, `${label} should be ALLOWED: ${await res.text()}`);
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
const Q = 'provider-q';
await seed(`users/${A}`, {uid: A, name: 'A', email: 'a@x.test', role: 'customer'});
await seed(`users/${B}`, {uid: B, name: 'B', email: 'b@x.test', role: 'customer'});
await seed(`users/${P}`, {uid: P, name: 'P', email: 'p@x.test', role: 'provider'});
await seed(`users/${Q}`, {uid: Q, name: 'Q', email: 'q@x.test', role: 'provider'});
for (const pro of [P, Q]) {
  await seed(`providerVerifications/${pro}`, {providerId: pro, status: 'verified', providerCode: 'HCP-1'});
}
await seed(`professionals/${P}`, {name: 'Nuwan', specialty: 'AC', verified: true, pricing: 4500});
await seed('professionals/no-price-pro', {name: 'No Price', specialty: 'AC', verified: true});

const D = colomboDate(3);
const future = instant(D, '10:30');
const quoteBooking = (extra = {}) => ({
  customerId: A,
  providerId: P,
  serviceName: 'AC repair',
  customerName: 'A',
  providerName: 'Nuwan',
  address: 'No. 42 Galle Road, Colombo 03',
  status: 'pending',
  quoteStatus: 'pending',
  quoteCurrency: 'LKR',
  estimatedPrice: dbl(4500),
  totalAmount: dbl(4500),
  laborCharge: dbl(4500),
  serviceFee: 0,
  paymentStatus: 'unpaid',
  accessNotes: '',
  jobNotes: '',
  photoUrls: [],
  slotDate: D,
  startTime: '10:30',
  endTime: '12:00',
  scheduledAt: future,
  endAt: instant(D, '12:00'),
  ...extra,
});

const entry = (amount, status, extra = {}) => ({
  amount: dbl(amount),
  status,
  createdAt: new Date(),
  note: null,
  reason: null,
  ...extra,
});

let noteSeq = 0;
const noteId = (booking) => `quote_${booking}_${Date.now()}${noteSeq++}`;
const notice = (id, from, to, booking, extra = {}) =>
  set(
    `notifications/${id}`,
    {
      recipientId: to,
      senderId: from,
      type: 'quote',
      bookingId: booking,
      title: 'Quote',
      body: 'A quote changed.',
      read: false,
      ...extra,
    },
    ['createdAt'],
  );

const quoteStamps = ['quoteUpdatedAt', 'updatedAt'];
const sendQuote = (id, history, extra = {}) =>
  patch(
    `bookings/${id}`,
    {
      quoteStatus: 'quoted',
      quotedAmount: dbl(3500),
      quoteNote: 'Parts included',
      quoteHistory: history,
      ...extra,
    },
    quoteStamps,
  );

// ------------------------------------------------------ booking creation
const BD = colomboDate(5);
const newBooking = (id, extra = {}) =>
  set(
    `bookings/${id}`,
    {
      reference: 'BK-12345', customerId: A, customerName: 'A', providerId: P, providerName: 'Nuwan',
      serviceName: 'AC Deep Clean', status: 'pending', slotDate: BD, startTime: '09:00', endTime: '10:30',
      scheduledAt: instant(BD, '09:00'), endAt: instant(BD, '10:30'), slotLockId: lock(P, BD, '09:00'),
      addressId: 'home', address: 'No. 42 Galle Road, Colombo 03', addressLabel: 'Home',
      addressArea: 'Western Province', accessNotes: '', contactPhone: '', jobNotes: '', photoUrls: [],
      estimatedPrice: dbl(4500), totalAmount: dbl(4500), laborCharge: dbl(4500), serviceFee: 0,
      paymentStatus: 'unpaid', quoteStatus: 'pending', quoteCurrency: 'LKR', ...extra,
    },
    ['createdAt', 'updatedAt'],
  );
const newLock = (id) =>
  set(`slotLocks/${lock(P, BD, '09:00')}`, {
    providerId: P, date: BD, startTime: '09:00', endTime: '10:30', bookingId: id,
  });

await expectAllowed(
  commit(A, [newBooking('nb1'), newLock('nb1')]),
  'customer books with a pending quote',
);
await expectDenied(
  commit(A, [newBooking('nb2', {quoteStatus: 'accepted'}), newLock('nb2')]),
  'booking that starts with an already accepted quote',
);
await expectDenied(
  commit(A, [newBooking('nb3', {acceptedAmount: dbl(1)}), newLock('nb3')]),
  'booking that carries its own accepted amount',
);

// A provider with no base price can still be booked.
const NB = colomboDate(6);
await expectAllowed(
  commit(A, [
    set(
      'bookings/nb-noprice',
      {
        reference: 'BK-22222', customerId: A, customerName: 'A', providerId: 'no-price-pro',
        providerName: 'No Price', serviceName: 'AC repair', status: 'pending', slotDate: NB,
        startTime: '09:00', endTime: '10:30', scheduledAt: instant(NB, '09:00'),
        endAt: instant(NB, '10:30'), slotLockId: lock('no-price-pro', NB, '09:00'),
        addressId: 'home', address: 'No. 42 Galle Road', addressLabel: 'Home',
        addressArea: 'Western Province', accessNotes: '', contactPhone: '', jobNotes: '',
        photoUrls: [], estimatedPrice: null, totalAmount: null, laborCharge: null,
        serviceFee: 0, paymentStatus: 'unpaid', quoteStatus: 'pending', quoteCurrency: 'LKR',
      },
      ['createdAt', 'updatedAt'],
    ),
    set(`slotLocks/${lock('no-price-pro', NB, '09:00')}`, {
      providerId: 'no-price-pro', date: NB, startTime: '09:00', endTime: '10:30',
      bookingId: 'nb-noprice',
    }),
  ]),
  'a provider with no base price can still be booked',
);

// ------------------------------------------------ first quote on a request
await seed('bookings/q1', quoteBooking());
const h1 = [entry(3500, 'quoted', {note: 'Parts included'})];

await expectDenied(
  commit(Q, [sendQuote('q1', h1), notice(noteId('q1'), Q, A, 'q1')]),
  'another provider quotes a job that is not theirs',
);
await expectDenied(
  commit(A, [sendQuote('q1', h1)]),
  'the customer sets their own quote',
);
await expectDenied(
  commit(P, [sendQuote('q1', h1, {quotedAmount: dbl(0)})]),
  'quote of 0',
);
await expectDenied(
  commit(P, [sendQuote('q1', [entry(0, 'quoted')], {quotedAmount: dbl(0)})]),
  'quote of 0 with matching history',
);
await expectDenied(
  commit(P, [sendQuote('q1', [entry(3500.5, 'quoted')], {quotedAmount: dbl(3500.5)})]),
  'quote with cents',
);
await expectDenied(
  commit(P, [sendQuote('q1', [entry(99999999, 'quoted')], {quotedAmount: dbl(99999999)})]),
  'quote above the maximum',
);
await expectDenied(
  commit(P, [sendQuote('q1', [])]),
  'quote that skips the price history',
);
await expectDenied(
  commit(P, [sendQuote('q1', [entry(1, 'quoted')])]),
  'history amount that does not match the quote',
);
await expectDenied(
  commit(P, [sendQuote('q1', h1, {totalAmount: dbl(1)})]),
  'quote that also rewrites totalAmount',
);
await expectDenied(
  commit(P, [sendQuote('q1', h1, {acceptedAmount: dbl(3500)})]),
  'quote that also writes acceptedAmount',
);
await expectDenied(
  commit(P, [sendQuote('q1', h1, {status: 'confirmed'})]),
  'quote that also confirms the job',
);
await expectDenied(
  commit(P, [
    patch('bookings/q1', {quoteStatus: 'accepted', quotedAmount: dbl(3500), quoteHistory: h1}, quoteStamps),
  ]),
  'provider marks their own quote as accepted',
);
await expectDenied(
  commit(P, [notice(noteId('q1'), P, A, 'q1')]),
  'quote notice with no quote change behind it (spam)',
);
await expectDenied(
  commit(P, [sendQuote('q1', h1), notice(noteId('q1'), P, B, 'q1')]),
  'quote notice addressed to someone who is not the customer',
);
await expectDenied(
  commit(P, [sendQuote('q1', h1), notice('review_q1', P, A, 'q1')]),
  'quote notice with a made-up id',
);
await expectAllowed(
  commit(P, [sendQuote('q1', h1), notice(noteId('q1'), P, A, 'q1')]),
  'provider sends a quote and tells the customer',
);
await expectDenied(
  commit(P, [sendQuote('q1', [...h1, entry(4000, 'quoted')], {quotedAmount: dbl(4000)})]),
  'provider re-sends while the customer has not answered',
);
await expectDenied(
  commit(P, [
    patch('bookings/q1', {status: 'confirmed'}, ['acceptedAt']),
  ]),
  'provider confirms a quote-flow request without the customer',
);

// -------------------------------------------------- the customer answers
const accept = (id, amount, history, extra = {}) =>
  patch(
    `bookings/${id}`,
    {
      status: 'confirmed',
      quoteStatus: 'accepted',
      acceptedAmount: dbl(amount),
      totalAmount: dbl(amount),
      laborCharge: dbl(amount),
      quoteHistory: history,
      ...extra,
    },
    ['acceptedAt', ...quoteStamps],
  );
const h1a = [...h1, entry(3500, 'accepted')];

await expectDenied(
  commit(B, [accept('q1', 3500, h1a), notice(noteId('q1'), B, P, 'q1')]),
  'a different customer accepts the quote',
);
await expectDenied(
  commit(P, [accept('q1', 3500, h1a)]),
  'the provider accepts their own quote',
);
await expectDenied(
  commit(A, [accept('q1', 100, [...h1, entry(100, 'accepted')])]),
  'customer accepts for less than the quote',
);
await expectDenied(
  commit(A, [accept('q1', 3500, h1a, {estimatedPrice: dbl(1)})]),
  'accept that also rewrites the estimate',
);
await expectDenied(
  commit(A, [accept('q1', 3500, h1a, {serviceFee: dbl(0), paymentStatus: 'paid'})]),
  'accept that also marks the booking paid',
);
await expectDenied(
  commit(A, [accept('q1', 3500, [...h1, entry(3500, 'declined')])]),
  'accept whose history says declined',
);
await expectAllowed(
  commit(A, [accept('q1', 3500, h1a), notice(noteId('q1'), A, P, 'q1')]),
  'customer accepts: job confirmed and the price locked',
);
const locked = await read('bookings/q1');
assert.equal(locked.status.stringValue, 'confirmed');
assert.equal(Number(locked.acceptedAmount.doubleValue ?? locked.acceptedAmount.integerValue), 3500);
assert.equal(Number(locked.totalAmount.doubleValue ?? locked.totalAmount.integerValue), 3500);
console.log('PASS  state  booking is confirmed at the accepted price');
checks++;

// ------------------------------------------------- decline, then re-quote
await seed('bookings/q2', quoteBooking());
await expectAllowed(
  commit(P, [sendQuote('q2', h1), notice(noteId('q2'), P, A, 'q2')]),
  'quote on a second request',
);
const decline = (id, history, extra = {}) =>
  patch(`bookings/${id}`, {quoteStatus: 'declined', quoteHistory: history, ...extra}, quoteStamps);
const h2d = [...h1, entry(3500, 'declined')];
await expectDenied(
  commit(A, [decline('q2', h2d, {status: 'declined'})]),
  'decline that also changes the booking status',
);
await expectAllowed(
  commit(A, [decline('q2', h2d), notice(noteId('q2'), A, P, 'q2')]),
  'customer declines the quote',
);
const stillOpen = await read('bookings/q2');
assert.equal(stillOpen.status.stringValue, 'pending');
await expectAllowed(
  commit(P, [
    sendQuote('q2', [...h2d, entry(3000, 'quoted')], {quotedAmount: dbl(3000)}),
    notice(noteId('q2'), P, A, 'q2'),
  ]),
  'provider sends a new quote after a decline',
);

// ----------------------------------------------------- legacy (no quotes)
const legacy = quoteBooking();
delete legacy.quoteStatus;
delete legacy.quoteCurrency;
await seed('bookings/old-pending', legacy);
await expectAllowed(
  commit(P, [patch('bookings/old-pending', {status: 'confirmed'}, ['acceptedAt'])]),
  'provider accepts a request made before quotes existed',
);
await expectAllowed(
  commit(P, [patch('bookings/old-pending', {status: 'completed'}, ['completedAt'])]),
  'provider completes an old job that has a price',
);
await seed('bookings/old-noprice', {...legacy, status: 'confirmed', totalAmount: null, estimatedPrice: null, laborCharge: null});
await expectDenied(
  commit(P, [patch('bookings/old-noprice', {status: 'completed'}, ['completedAt'])]),
  'completing an old job that has no price',
);
await expectAllowed(
  commit(P, [
    sendQuote('old-noprice', [entry(3500, 'quoted', {reason: 'First price for this job'})], {quotedAmount: dbl(3500)}),
    notice(noteId('old-noprice'), P, A, 'old-noprice'),
  ]),
  'provider can still quote an old confirmed job with no price',
);

// ------------------------------------------------------ completion rules
await expectAllowed(
  commit(P, [patch('bookings/q1', {status: 'completed'}, ['completedAt'])]),
  'provider completes a job whose quote was accepted',
);
await seed('bookings/q-unpriced', quoteBooking({status: 'confirmed', quoteStatus: 'accepted', acceptedAmount: null, totalAmount: null}));
await expectDenied(
  commit(P, [patch('bookings/q-unpriced', {status: 'completed'}, ['completedAt'])]),
  'completing a job with no accepted amount',
);

// ----------------------------------------------------------- revisions
const confirmed = (extra = {}) =>
  quoteBooking({
    status: 'confirmed',
    quoteStatus: 'accepted',
    acceptedAmount: dbl(3500),
    quotedAmount: dbl(3500),
    totalAmount: dbl(3500),
    laborCharge: dbl(3500),
    quoteHistory: [entry(3500, 'quoted'), entry(3500, 'accepted')],
    ...extra,
  });
await seed('bookings/r1', confirmed());
const base2 = [entry(3500, 'quoted'), entry(3500, 'accepted')];
const revise = (id, amount, reason, extra = {}) =>
  sendQuote(id, [...base2, entry(amount, 'quoted', {reason})], {quotedAmount: dbl(amount), ...extra});

await expectDenied(
  commit(P, [revise('r1', 5000, null)]),
  'revision with no reason',
);
await expectDenied(
  commit(P, [revise('r1', 5000, 'x')]),
  'revision with a one-letter reason',
);
await expectDenied(
  commit(P, [revise('r1', 3500, 'Same price again')]),
  'revision to the same amount',
);
await expectDenied(
  commit(Q, [revise('r1', 5000, 'Extra pipework'), notice(noteId('r1'), Q, A, 'r1')]),
  'another provider revises the price',
);
await expectDenied(
  commit(P, [revise('r1', 5000, 'Extra pipework', {totalAmount: dbl(5000)})]),
  'revision that also changes the approved total',
);
await expectAllowed(
  commit(P, [revise('r1', 5000, 'Extra pipework found'), notice(noteId('r1'), P, A, 'r1')]),
  'provider revises a confirmed job with a reason',
);
const mid = await read('bookings/r1');
assert.equal(Number(mid.acceptedAmount.doubleValue ?? mid.acceptedAmount.integerValue), 3500);
assert.equal(mid.quoteStatus.stringValue, 'quoted');
console.log('PASS  state  the old accepted amount stays until the customer answers');
checks++;
await expectDenied(
  commit(P, [patch('bookings/r1', {status: 'completed'}, ['completedAt'])]),
  'completing while a revision waits for the customer',
);
const fullHistory = [...base2, entry(5000, 'quoted', {reason: 'Extra pipework found'})];
await expectDenied(
  commit(A, [
    patch(
      'bookings/r1',
      {
        quoteStatus: 'accepted', acceptedAmount: dbl(5000), totalAmount: dbl(5000),
        laborCharge: dbl(5000), quoteHistory: [...fullHistory, entry(5000, 'accepted')],
        status: 'pending',
      },
      ['acceptedAt', ...quoteStamps],
    ),
  ]),
  'accepting a revision while moving the job back to pending',
);
await expectAllowed(
  commit(A, [
    decline('r1', [...fullHistory, entry(5000, 'declined')]),
    notice(noteId('r1'), A, P, 'r1'),
  ]),
  'customer declines the revision',
);
const kept = await read('bookings/r1');
assert.equal(Number(kept.acceptedAmount.doubleValue ?? kept.acceptedAmount.integerValue), 3500);
assert.equal(kept.status.stringValue, 'confirmed');
console.log('PASS  state  declined revision keeps the original accepted amount');
checks++;
await expectAllowed(
  commit(P, [
    sendQuote('r1', [...fullHistory, entry(5000, 'declined'), entry(4200, 'quoted', {reason: 'Smaller fix'})], {quotedAmount: dbl(4200)}),
    notice(noteId('r1'), P, A, 'r1'),
  ]),
  'provider sends another revision after a declined one',
);
await expectAllowed(
  commit(A, [
    patch(
      'bookings/r1',
      {
        quoteStatus: 'accepted', acceptedAmount: dbl(4200), totalAmount: dbl(4200),
        laborCharge: dbl(4200),
        quoteHistory: [...fullHistory, entry(5000, 'declined'), entry(4200, 'quoted'), entry(4200, 'accepted')],
      },
      quoteStamps,
    ),
    notice(noteId('r1'), A, P, 'r1'),
  ]),
  'customer accepts the new revision (status stays confirmed)',
);
const revised = await read('bookings/r1');
assert.equal(Number(revised.acceptedAmount.doubleValue ?? revised.acceptedAmount.integerValue), 4200);
assert.equal(Number(revised.totalAmount.doubleValue ?? revised.totalAmount.integerValue), 4200);
console.log('PASS  state  accepted revision updates the approved amount');
checks++;

// ------------------------------------------- cancel while a quote is open
await seed(
  'bookings/c1',
  quoteBooking({
    quoteStatus: 'quoted',
    quotedAmount: dbl(3500),
    quoteHistory: h1,
    scheduledAt: new Date(Date.now() + 3600000),
    slotDate: null,
    startTime: null,
    endTime: null,
    endAt: null,
  }),
);
const cancel = (fee) =>
  patch(
    'bookings/c1',
    {
      status: 'cancelled', cancellationReason: 'Changed my plans',
      cancellationFee: dbl(fee), refundAmount: dbl(0), slotLockId: null,
    },
    ['cancelledAt', 'updatedAt'],
  );
await expectDenied(
  commit(A, [cancel(900)]),
  'late cancellation fee charged against an estimate nobody agreed to',
);
await expectAllowed(
  commit(A, [cancel(0)]),
  'customer cancels while a quote is open (no fee: nothing was agreed)',
);
await expectDenied(
  commit(A, [
    decline('c1', h2d),
  ]),
  'answering a quote on a cancelled booking',
);
await expectDenied(
  commit(P, [sendQuote('c1', h1)]),
  'quoting a cancelled booking',
);

console.log(`\nAll ${checks} quote rule checks passed.`);
