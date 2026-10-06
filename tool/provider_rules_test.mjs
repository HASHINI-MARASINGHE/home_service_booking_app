// Run only against local Auth/Firestore emulators. No external dependencies.
// node tool/provider_rules_test.mjs
import assert from 'node:assert/strict';

const project = process.env.PROVIDER_TEST_PROJECT || 'home-service-booking-app-89796';
const base = 'http://127.0.0.1:8080/v1/projects/' + project + '/databases/(default)/documents';
const prefix = 'projects/' + project + '/databases/(default)/documents/';
const run = Date.now().toString();
let checks = 0;

function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key,
    value === null ? {nullValue: null} :
    value instanceof Date ? {timestampValue: value.toISOString()} :
    Array.isArray(value) ? {arrayValue: {values: value.map(v => ({stringValue: v}))}} :
    typeof value === 'boolean' ? {booleanValue: value} :
    typeof value === 'number' ? {integerValue: String(value)} : {stringValue: value}
  ]));
}

async function request(url, method, token, body) {
  return fetch(url, {
    method, headers: {'Content-Type': 'application/json', Authorization: 'Bearer ' + token},
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}
async function seed(path, data) {
  const response = await request(base + '/' + path, 'PATCH', 'owner', {fields: fields(data)});
  assert.equal(response.status, 200, await response.text());
}
async function account(label, role) {
  const response = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=local-test', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({email: label + '-' + run + '@example.com', password: 'test-password-123', returnSecureToken: true}),
  });
  assert.equal(response.status, 200, await response.clone().text());
  const user = await response.json();
  await seed('users/' + user.localId, {uid: user.localId, name: label, email: user.email, role});
  return {uid: user.localId, token: user.idToken};
}
async function check(response, allowed, label) {
  const body = await response.text();
  assert.equal(response.status, allowed ? 200 : 403, label + ': ' + body);
  console.log('PASS ' + label);
  checks++;
}
function commit(user, path, data, timestamp) {
  const write = {update: {name: prefix + path, fields: fields(data)}, updateMask: {fieldPaths: Object.keys(data)}};
  if (timestamp) write.updateTransforms = [{fieldPath: timestamp, setToServerValue: 'REQUEST_TIME'}];
  return request(base + ':commit', 'POST', user.token, {writes: [write]});
}

const a = await account('provider-a', 'provider');
const b = await account('provider-b', 'provider');
const customer = await account('customer', 'customer');
// Only admin-verified providers can act on jobs.
await seed('providerVerifications/' + a.uid, {providerId: a.uid, status: 'verified', providerCode: 'HCP-1000'});
const path = 'bookings/rules-' + run;
const pending = {
  providerId: a.uid, customerId: customer.uid, serviceName: 'Emulator test',
  customerName: 'Test customer', address: 'Test location', status: 'pending',
  paymentStatus: 'unpaid', totalAmount: 2500, laborCharge: 2000, serviceFee: 500,
  scheduledAt: new Date(Date.now() + 86400000), createdAt: new Date(),
};
await seed(path, pending);
await check(await request(base + '/' + path, 'GET', a.token), true, 'assigned provider reads booking');
await check(await request(base + '/' + path, 'GET', b.token), false, 'other provider cannot read booking');
await check(await request(base + '/' + path, 'GET', customer.token), true, 'owning customer reads booking');
await check(await request(base + ':runQuery', 'POST', a.token, {
  structuredQuery: {from: [{collectionId: 'bookings'}], where: {fieldFilter: {
    field: {fieldPath: 'providerId'}, op: 'EQUAL', value: {stringValue: a.uid},
  }}},
}), true, 'provider-scoped realtime query shape is authorized');
await check(await request(base + ':runQuery', 'POST', a.token, {
  structuredQuery: {from: [{collectionId: 'bookings'}]},
}), false, 'unscoped booking query is denied');
await check(await commit(b, path, {status: 'confirmed'}, 'acceptedAt'), false, 'other provider cannot accept');
await check(await commit(a, path, {status: 'completed'}, 'completedAt'), false, 'pending cannot be completed');
await check(await commit(a, path, {status: 'confirmed', totalAmount: 1}, 'acceptedAt'), false, 'accept cannot change price');
await check(await commit(a, path, {status: 'confirmed'}, 'acceptedAt'), true, 'pending can be accepted with server time');
await check(await commit(a, path, {status: 'confirmed'}, 'acceptedAt'), false, 'repeat acceptance denied');
await check(await commit(a, path, {status: 'declined'}, 'declinedAt'), false, 'confirmed cannot be declined');
await check(await commit(a, path, {status: 'completed', paymentStatus: 'paid'}, 'completedAt'), false, 'completion cannot forge payment');
await check(await commit(a, path, {status: 'completed'}, 'completedAt'), true, 'confirmed can be completed');
await check(await commit(a, path, {status: 'completed'}, 'completedAt'), false, 'repeat completion denied');
await check(await request(base + '/' + path, 'DELETE', a.token), false, 'provider cannot delete history');

const declined = path + '-declined';
await seed(declined, pending);
await check(await commit(a, declined, {status: 'declined'}, 'declinedAt'), true, 'pending can be declined');
await check(await commit(a, declined, {status: 'confirmed'}, 'acceptedAt'), false, 'declined cannot be accepted');

const expired = path + '-expired';
await seed(expired, {...pending, expiresAt: new Date(Date.now() - 60000)});
await check(await commit(a, expired, {status: 'confirmed'}, 'acceptedAt'), false, 'expired acceptance denied by server clock');

const race = path + '-race';
await seed(race, pending);
const raceResults = await Promise.all([
  commit(a, race, {status: 'confirmed'}, 'acceptedAt'),
  commit(a, race, {status: 'declined'}, 'declinedAt'),
]);
assert.deepEqual(raceResults.map(r => r.status).sort(), [200, 403], 'exactly one competing transition succeeds');
console.log('PASS competing responses allow only one transition');
checks++;

const profilePath = 'providerProfiles/' + a.uid;
const profile = {providerId: a.uid, phone: '', profession: 'Electrician', experience: 3,
  about: 'Local test', services: ['Repairs'], pricing: 2000, availability: true};
await check(await commit(a, profilePath, profile, 'updatedAt'), true, 'provider creates own profile');
await check(await commit(a, profilePath, {about: 'Updated profile'}, 'updatedAt'), true, 'provider edits own profile');
await check(await commit(b, profilePath, {about: 'Unauthorized'}, 'updatedAt'), false, 'other provider cannot edit profile');
await check(await commit(a, profilePath, {rating: 5}, 'updatedAt'), false, 'provider cannot award own rating');
await check(await commit(a, profilePath, {verificationStatus: 'verified'}, 'updatedAt'), false, 'provider cannot self-verify');
await check(await commit(a, profilePath, {experience: -1}, 'updatedAt'), false, 'invalid experience rejected');
console.log(checks + ' security checks passed. Only local emulator data was created.');
