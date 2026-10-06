// Creates (or resets) a HomeCare admin account. Admin accounts can never be
// created from the app: the sign-up screen only offers Customer and Provider,
// and the security rules refuse any user document with the admin role.
//
//   node create_admin.mjs --emulator   --username admin --password '...' --name 'HomeCare Admin'
//   node create_admin.mjs --production --username admin --password '...' --name 'HomeCare Admin'
//
// Sign in on the login screen with "Admin sign in" using the username
// (`admin` is `admin@admin.homecare.app`) and the password.
import {connect} from './firebase_admin.mjs';

const {auth, db} = connect();
const arg = (name) => {
  const i = process.argv.indexOf(`--${name}`);
  return i < 0 ? undefined : process.argv[i + 1];
};

const username = (arg('username') || 'admin').trim().toLowerCase();
const password = arg('password');
const name = arg('name') || 'HomeCare Admin';
if (!password || password.length < 10) {
  console.error('Pass --password with at least 10 characters.');
  process.exit(2);
}
const email = username.includes('@') ? username : `${username}@admin.homecare.app`;

let uid;
try {
  const existing = await auth.getUserByEmail(email);
  uid = existing.uid;
  await auth.updateUser(uid, {password, displayName: name, emailVerified: true});
} catch (error) {
  if (error.code !== 'auth/user-not-found') throw error;
  uid = (await auth.createUser({email, password, displayName: name, emailVerified: true})).uid;
}
await db.doc(`users/${uid}`).set({uid, name, email, role: 'admin', photoUrl: null});
console.log(`Admin ready. Username: ${username}  (sign-in address ${email})`);
process.exit(0);
