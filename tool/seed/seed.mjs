// Development seed data for the customer booking-management screens.
//
//   cd tool/seed && npm install
//   node seed.mjs --emulator          # local emulators (recommended)
//   node seed.mjs --production        # real project (needs a service account)
//
// Safe to re-run: every record uses a fixed ID and is overwritten, so the
// demo returns to its starting state (e.g. after cancelling a booking).
import {FieldValue, Timestamp} from 'firebase-admin/firestore';

import {
  colomboDate,
  colomboInstant,
  connect,
  lockId,
  workingDate,
} from './firebase_admin.mjs';

const {auth, db} = connect();
const PASSWORD = 'HomeCare@123';

const people = {
  customer: {
    uid: 'seed-customer-dilshan',
    email: 'customer@homecare.test',
    name: 'Dilshan Perera',
    role: 'customer',
  },
  newCustomer: {
    uid: 'seed-customer-amaya',
    email: 'newcustomer@homecare.test',
    name: 'Amaya Silva',
    role: 'customer',
  },
  otherCustomer: {
    uid: 'seed-customer-ruwan',
    email: 'other@homecare.test',
    name: 'Ruwan Jayasuriya',
    role: 'customer',
  },
  nuwan: {
    uid: 'seed-provider-nuwan',
    email: 'nuwan@homecare.test',
    name: 'Nuwan Fernando',
    role: 'provider',
  },
  kasun: {
    uid: 'seed-provider-kasun',
    email: 'kasun@homecare.test',
    name: 'Kasun Wijesinghe',
    role: 'provider',
  },
};

const ts = (date) => Timestamp.fromDate(date);
const daysAgo = (n) => new Date(Date.now() - n * 86400000);

async function upsertUser(person) {
  try {
    await auth.updateUser(person.uid, {
      email: person.email,
      password: PASSWORD,
      displayName: person.name,
      emailVerified: true,
    });
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    await auth.createUser({
      uid: person.uid,
      email: person.email,
      password: PASSWORD,
      displayName: person.name,
      emailVerified: true,
    });
  }
  await db.doc(`users/${person.uid}`).set({
    uid: person.uid,
    name: person.name,
    email: person.email,
    role: person.role,
    photoUrl: null,
  });
}

const workingSlots = [
  {start: '08:30', end: '10:00'},
  {start: '10:30', end: '12:00'},
  {start: '13:30', end: '15:00'},
  {start: '15:30', end: '17:00'},
  {start: '17:30', end: '19:00'},
];

const professionals = {
  [people.nuwan.uid]: {
    name: people.nuwan.name,
    photoUrl:
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=300&q=80',
    specialty: 'Air Conditioning & Electrical Specialist',
    rating: 4.9,
    completedJobs: 128,
    verified: true,
    phone: '+94771112233',
    licenseNumber: 'LK-AC-409',
    area: 'Colombo 03',
    workingSlots,
    workingDays: [1, 2, 3, 4, 5, 6],
  },
  [people.kasun.uid]: {
    name: people.kasun.name,
    photoUrl:
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&q=80',
    specialty: 'Plumbing & Sanitation Specialist',
    rating: 4.7,
    completedJobs: 86,
    verified: true,
    phone: '+94772223344',
    licenseNumber: 'LK-PL-112',
    area: 'Dehiwala',
    workingSlots,
    workingDays: [1, 2, 3, 4, 5, 6],
  },
};

const services = {
  'ac-deep-clean': {
    name: 'AC Deep Clean & Servicing',
    description: 'Indoor and outdoor unit deep clean with coil flush.',
    price: 4500,
    durationMinutes: 90,
    category: 'AC & Cooling',
  },
  'ac-repair': {
    name: 'Inverter AC Repair',
    description: 'Diagnosis and repair of inverter split units.',
    price: 4500,
    durationMinutes: 90,
    category: 'AC & Cooling',
  },
  'office-disinfection': {
    name: 'Deep Office Disinfection',
    description: 'Hospital-grade disinfection for offices up to 3,000 sq ft.',
    price: 7000,
    durationMinutes: 90,
    category: 'Cleaning',
  },
  'plumbing-fix': {
    name: 'Bathroom Plumbing Fix',
    description: 'Leaks, blockages and fixture replacement.',
    price: 3000,
    durationMinutes: 90,
    category: 'Plumbing',
  },
  electrician: {
    name: 'Electrical Repairs',
    description: 'Wiring faults, sockets, breakers and lighting.',
    price: 2500,
    durationMinutes: 60,
    category: 'Electrical',
  },
};

const home = {
  id: 'seed-address-home',
  type: 'home',
  label: 'Home',
  houseNumber: 'No. 42',
  street: 'Galle Road',
  city: 'Colombo 03',
  postalCode: '00300',
  province: 'Western Province',
  landmark: 'Opposite Majestic City, Blue Gate',
  accessNotes: 'Blue gate, ring bell 2B.',
  latitude: 6.8935,
  longitude: 79.8553,
  isDefault: true,
};
const office = {
  id: 'seed-address-office',
  type: 'office',
  label: 'Office • World Trade Center',
  houseNumber: 'Level 14, East Tower',
  street: 'Echelon Square',
  city: 'Colombo 01',
  postalCode: '00100',
  province: 'Western Province',
  landmark: 'Security desk entrance • Visitor badge required',
  accessNotes: '',
  latitude: 6.9338,
  longitude: 79.8436,
  isDefault: false,
};
const parents = {
  id: 'seed-address-parents',
  type: 'parents',
  label: "Parents' House",
  houseNumber: 'No. 18/4',
  street: 'Temple Road',
  city: 'Dehiwala',
  postalCode: '10350',
  province: 'Western Province',
  landmark: 'Near Bellanwila junction, 2nd lane right',
  accessNotes: '',
  latitude: null,
  longitude: null,
  isDefault: false,
};
const line = (a) => `${a.houseNumber} ${a.street}, ${a.city}`;

function slot(date, start, end) {
  return {
    slotDate: date,
    startTime: start,
    endTime: end,
    scheduledAt: ts(colomboInstant(date, start)),
    endAt: ts(colomboInstant(date, end)),
  };
}

function priced(items, serviceFee) {
  const total = items.reduce((sum, item) => sum + item.amount, 0);
  return {
    lineItems: items.map((item) => ({detail: '', ...item})),
    estimatedPrice: total,
    totalAmount: total,
    serviceFee,
    laborCharge: total - serviceFee,
  };
}

const upcomingDate = workingDate(3);
const officeDate = workingDate(5);
const completedDate = colomboDate(-10);
const cancelledDate = colomboDate(-2);

const bookings = {
  'seed-bk-78924': {
    reference: 'BK-78924',
    customerId: people.customer.uid,
    customerName: people.customer.name,
    providerId: people.nuwan.uid,
    providerName: people.nuwan.name,
    serviceId: 'ac-deep-clean',
    serviceName: 'AC Deep Clean & Servicing',
    serviceDetail: '2 Inverter Indoor & Outdoor Units',
    serviceTier: 'Domestic Tier 1',
    status: 'confirmed',
    ...slot(upcomingDate, '10:30', '12:00'),
    addressId: home.id,
    address: line(home),
    addressLabel: home.label,
    addressArea: 'Kollupitiya Ward, Western Province',
    addressNeedsUpdate: false,
    accessNotes:
      'Blue gate, ring bell 2B. Please call before entering to secure pets.',
    contactPhone: '+94771234567',
    jobNotes:
      'AC unit in master bedroom is making a rattling noise and cooling ' +
      'slower than usual.',
    photoUrls: [
      'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600&q=70',
      'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=600&q=70',
    ],
    ...priced(
      [
        {label: 'Base AC Servicing (2 Units)', amount: 4500},
        {label: 'Disinfection & Coil Flush', amount: 800},
        {label: 'Platform SafeCare Fee', amount: 200},
      ],
      200,
    ),
    paymentMethod: 'card',
    cardLast4: '8821',
    paymentStatus: 'escrow',
    createdAt: ts(daysAgo(4)),
    acceptedAt: ts(daysAgo(4)),
  },
  'seed-bk-79102': {
    reference: 'BK-79102',
    customerId: people.customer.uid,
    customerName: people.customer.name,
    providerId: people.kasun.uid,
    providerName: people.kasun.name,
    serviceId: 'office-disinfection',
    serviceName: 'Deep Office Disinfection',
    serviceDetail: 'Open-plan office, approx. 2,400 sq ft',
    serviceTier: 'Commercial',
    status: 'pending',
    ...slot(officeDate, '08:30', '10:00'),
    addressId: office.id,
    address: line(office),
    addressLabel: office.label,
    addressArea: 'Echelon Square, Western Province',
    addressNeedsUpdate: false,
    accessNotes: 'Register at the security desk; visitor badge required.',
    contactPhone: '+94771234567',
    jobNotes: '',
    photoUrls: [],
    ...priced(
      [
        {label: 'Deep Office Disinfection', amount: 7000},
        {label: 'Eco-safe chemical kit', amount: 600},
        {label: 'Platform SafeCare Fee', amount: 200},
      ],
      200,
    ),
    paymentMethod: 'cash',
    paymentStatus: 'unpaid',
    createdAt: ts(daysAgo(1)),
  },
  'seed-bk-77310': {
    reference: 'BK-77310',
    customerId: people.customer.uid,
    customerName: people.customer.name,
    providerId: people.nuwan.uid,
    providerName: people.nuwan.name,
    serviceId: 'ac-repair',
    serviceName: 'Inverter AC Repair',
    serviceDetail: '2 × Inverter Split Units',
    serviceTier: 'Domestic Tier 1',
    status: 'completed',
    ...slot(completedDate, '10:00', '11:30'),
    addressId: home.id,
    address: line(home),
    addressLabel: home.label,
    addressArea: 'Kollupitiya Ward, Western Province',
    addressNeedsUpdate: false,
    accessNotes: 'Blue gate, ring bell 2B.',
    contactPhone: '+94771234567',
    jobNotes: 'Unit trips the breaker after 10 minutes.',
    photoUrls: [],
    ...priced(
      [
        {label: 'Base AC Deep Clean', detail: '2 × Inverter Split Units (Indoor & Outdoor)', amount: 4500},
        {label: 'Replacement Capacitor & Filter', detail: 'Japanese grade 45µF + Anti-mold mesh', amount: 6200},
        {label: 'Extra Labor & Chemical Flush', detail: '1.5 hrs deep condenser coil pressure foam', amount: 2600},
        {label: 'Platform SafeCare & Insurance', amount: 400},
        {label: 'VAT / Municipality Taxes', detail: 'Calculated at standard 8% municipal rate', amount: 800},
      ],
      400,
    ),
    paymentMethod: 'card',
    cardLast4: '8821',
    paymentStatus: 'paid',
    createdAt: ts(daysAgo(14)),
    acceptedAt: ts(daysAgo(14)),
    completedAt: ts(colomboInstant(completedDate, '11:35')),
  },
  'seed-bk-76455': {
    reference: 'BK-76455',
    customerId: people.customer.uid,
    customerName: people.customer.name,
    providerId: people.kasun.uid,
    providerName: people.kasun.name,
    serviceId: 'plumbing-fix',
    serviceName: 'Bathroom Plumbing Fix',
    serviceDetail: 'Leaking mixer tap and shower drain',
    serviceTier: 'Domestic',
    status: 'cancelled',
    ...slot(cancelledDate, '13:30', '15:00'),
    addressId: parents.id,
    address: line(parents),
    addressLabel: parents.label,
    addressArea: 'Dehiwala, Western Province',
    addressNeedsUpdate: false,
    accessNotes: '',
    contactPhone: '+94771234567',
    jobNotes: '',
    photoUrls: [],
    ...priced(
      [
        {label: 'Bathroom Plumbing Fix', amount: 3000},
        {label: 'Platform SafeCare Fee', amount: 200},
      ],
      200,
    ),
    paymentMethod: 'card',
    cardLast4: '8821',
    paymentStatus: 'refund_pending',
    cancellationReason: 'Changed my plans',
    cancellationFee: 0,
    refundAmount: 3200,
    cancelledAt: ts(daysAgo(3)),
    createdAt: ts(daysAgo(6)),
  },
  // Another customer's booking that occupies one of Nuwan's slots, so the
  // reschedule screen shows a genuinely "Booked" slot.
  'seed-bk-80117': {
    reference: 'BK-80117',
    customerId: people.otherCustomer.uid,
    customerName: people.otherCustomer.name,
    providerId: people.nuwan.uid,
    providerName: people.nuwan.name,
    serviceId: 'electrician',
    serviceName: 'Electrical Repairs',
    status: 'confirmed',
    ...slot(upcomingDate, '15:30', '17:00'),
    address: 'No. 7 Havelock Road, Colombo 05',
    addressArea: 'Havelock Town, Western Province',
    contactPhone: '+94775556677',
    ...priced([{label: 'Electrical Repairs', amount: 2500}], 200),
    paymentMethod: 'cash',
    paymentStatus: 'unpaid',
    createdAt: ts(daysAgo(2)),
    acceptedAt: ts(daysAgo(2)),
  },
};

for (const [id, booking] of Object.entries(bookings)) {
  if (booking.status === 'pending' || booking.status === 'confirmed') {
    booking.slotLockId = lockId(booking.providerId, booking.slotDate, booking.startTime);
  }
}

async function clearPrevious() {
  const ids = Object.keys(bookings);
  const locks = await db.collection('slotLocks').where('bookingId', 'in', ids).get();
  const batch = db.batch();
  locks.forEach((doc) => batch.delete(doc.ref));
  for (const id of ids) {
    batch.delete(db.doc(`refunds/${id}`));
    batch.delete(db.doc(`receipts/${id}`));
    batch.delete(db.doc(`reviews/${id}`));
  }
  for (const person of [people.customer, people.newCustomer, people.otherCustomer]) {
    const addresses = await db.collection(`users/${person.uid}/addresses`).get();
    addresses.forEach((doc) => batch.delete(doc.ref));
  }
  await batch.commit();
}

async function main() {
  console.log('Creating accounts…');
  for (const person of Object.values(people)) await upsertUser(person);

  console.log('Clearing previous seed records…');
  await clearPrevious();

  const batch = db.batch();
  for (const [uid, pro] of Object.entries(professionals)) {
    batch.set(db.doc(`professionals/${uid}`), pro);
    batch.set(db.doc(`providerProfiles/${uid}`), {
      providerId: uid,
      phone: pro.phone,
      profession: pro.specialty,
      experience: 8,
      about: `${pro.name} is a HomeCare verified professional.`,
      services: [pro.specialty],
      pricing: 2500,
      availability: true,
      verificationStatus: 'verified',
      rating: pro.rating,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  for (const [id, service] of Object.entries(services)) {
    batch.set(db.doc(`services/${id}`), service);
  }
  for (const address of [home, office, parents]) {
    const {id, ...data} = address;
    batch.set(db.doc(`users/${people.customer.uid}/addresses/${id}`), {
      ...data,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  for (const [id, booking] of Object.entries(bookings)) {
    batch.set(db.doc(`bookings/${id}`), {...booking, updatedAt: FieldValue.serverTimestamp()});
    if (booking.slotLockId) {
      batch.set(db.doc(`slotLocks/${booking.slotLockId}`), {
        providerId: booking.providerId,
        date: booking.slotDate,
        startTime: booking.startTime,
        endTime: booking.endTime,
        bookingId: id,
      });
    }
  }

  const completed = bookings['seed-bk-77310'];
  batch.set(db.doc('receipts/seed-bk-77310'), {
    bookingId: 'seed-bk-77310',
    customerId: completed.customerId,
    providerId: completed.providerId,
    receiptNumber: `INV-${completedDate.slice(0, 4)}-8841`,
    bookingReference: completed.reference,
    issuedAt: completed.completedAt,
    signedOffAt: completed.completedAt,
    serviceDate: completed.scheduledAt,
    startTime: completed.startTime,
    endTime: completed.endTime,
    providerName: people.nuwan.name,
    providerTitle: 'AC Maintenance Specialist • Top Pro',
    providerPhotoUrl: professionals[people.nuwan.uid].photoUrl,
    licenseNumber: professionals[people.nuwan.uid].licenseNumber,
    customerName: people.customer.name,
    serviceAddress: line(home),
    lineItems: completed.lineItems,
    totalAmount: completed.totalAmount,
    paymentMethod: 'card',
    cardLast4: '8821',
    paymentStatus: 'paid',
    paymentNote:
      'LKR 14,500 released from SafePay Escrow to Nuwan Fernando upon OTP ' +
      'customer confirmation.',
    verificationCode: `HOMECARE|INV-${completedDate.slice(0, 4)}-8841|BK-77310|14500`,
  });

  batch.set(db.doc('refunds/seed-bk-76455'), {
    bookingId: 'seed-bk-76455',
    customerId: people.customer.uid,
    amount: 3200,
    cancellationFee: 0,
    percentage: 100,
    method: 'card',
    cardLast4: '8821',
    refundReference: 'REF-992014',
    reason: 'Changed my plans',
    status: 'processing',
    gateway: 'PayHere',
    bankName: 'Commercial Bank of Ceylon',
    createdAt: ts(daysAgo(3)),
    // "Now", so the tracker shows In Progress until the worker settles it.
    processingAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();
  console.log('\nSeed complete. Password for every account: ' + PASSWORD);
  for (const person of Object.values(people)) {
    console.log(`  ${person.role.padEnd(8)} ${person.email}`);
  }
  console.log(`\nUpcoming AC booking: ${upcomingDate} 10:30 (BK-78924)`);
}

main().then(
  () => process.exit(0),
  (error) => {
    console.error(error);
    process.exit(1);
  },
);
