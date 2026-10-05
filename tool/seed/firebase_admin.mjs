// Shared Admin SDK bootstrap for the seed and worker scripts.
//
//   --emulator    use local Auth/Firestore emulators (default ports)
//   --production  use the real project; requires GOOGLE_APPLICATION_CREDENTIALS
//
// One of the two flags is required so nothing writes to production by accident.
import {initializeApp, applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';

export const projectId =
  process.env.FIREBASE_PROJECT_ID || 'home-service-booking-app-89796';

export function connect() {
  const args = new Set(process.argv.slice(2));
  if (args.has('--emulator') === args.has('--production')) {
    console.error('Pass exactly one of --emulator or --production.');
    process.exit(2);
  }
  if (args.has('--emulator')) {
    process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
    process.env.FIREBASE_AUTH_EMULATOR_HOST ||= '127.0.0.1:9099';
    initializeApp({projectId});
  } else {
    if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      console.error('Set GOOGLE_APPLICATION_CREDENTIALS to a service-account key.');
      process.exit(2);
    }
    initializeApp({credential: applicationDefault(), projectId});
  }
  return {auth: getAuth(), db: getFirestore(), args};
}

// Sri Lanka is UTC+05:30 with no daylight saving.
const offsetMs = 330 * 60 * 1000;

/** `YYYY-MM-DD` for today in Colombo, shifted by [days]. */
export function colomboDate(days = 0) {
  const local = new Date(Date.now() + offsetMs + days * 86400000);
  return local.toISOString().slice(0, 10);
}

/** Absolute instant of a Colombo wall-clock slot. */
export function colomboInstant(isoDate, hhmm) {
  const [y, m, d] = isoDate.split('-').map(Number);
  const [h, min] = hhmm.split(':').map(Number);
  return new Date(Date.UTC(y, m - 1, d, h, min) - offsetMs);
}

/** ISO weekday (Mon = 1) of a `YYYY-MM-DD` date. */
export function weekday(isoDate) {
  const day = new Date(isoDate + 'T00:00:00Z').getUTCDay();
  return day === 0 ? 7 : day;
}

/** First Colombo date at least [days] ahead that is not a Sunday. */
export function workingDate(days) {
  for (let offset = days; ; offset++) {
    const date = colomboDate(offset);
    if (weekday(date) !== 7) return date;
  }
}

export function lockId(providerId, isoDate, start) {
  return `${providerId}_${isoDate}_${start.replace(':', '')}`;
}
