// Mock payment + receipt backend for development. In production this logic
// belongs in Cloud Functions (or a server) connected to the real payment
// gateway; the Firestore contract stays the same.
//
//   node backend_worker.mjs --emulator            # one pass
//   node backend_worker.mjs --emulator --watch    # keep running
//
// Refunds:  initiated → processing → refunded (after REFUND_SETTLE_SECONDS)
// Receipts: completed bookings without a receipt get one; escrow → paid.
import {FieldValue, Timestamp} from 'firebase-admin/firestore';

import {connect} from './firebase_admin.mjs';

const {db, args} = connect();
const settleAfterMs = Number(process.env.REFUND_SETTLE_SECONDS || 120) * 1000;

async function advanceRefunds() {
  const now = Date.now();
  const refunds = await db
    .collection('refunds')
    .where('status', 'in', ['initiated', 'processing'])
    .get();
  for (const doc of refunds.docs) {
    const refund = doc.data();
    if (refund.status === 'initiated') {
      await doc.ref.update({
        status: 'processing',
        processingAt: FieldValue.serverTimestamp(),
        gateway: refund.gateway || 'PayHere',
        bankName: refund.bankName || 'Commercial Bank of Ceylon',
      });
      console.log(`refund ${doc.id}: initiated → processing`);
    } else if (now - refund.processingAt.toMillis() >= settleAfterMs) {
      await db.runTransaction(async (tx) => {
        tx.update(doc.ref, {
          status: 'refunded',
          refundedAt: FieldValue.serverTimestamp(),
        });
        tx.update(db.doc(`bookings/${doc.id}`), {
          paymentStatus: 'refunded',
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
      console.log(`refund ${doc.id}: processing → refunded`);
    }
  }
}

async function issueReceipts() {
  const completed = await db
    .collection('bookings')
    .where('status', '==', 'completed')
    .get();
  for (const doc of completed.docs) {
    const receiptRef = db.doc(`receipts/${doc.id}`);
    if ((await receiptRef.get()).exists) continue;
    const b = doc.data();
    const pro = (await db.doc(`professionals/${b.providerId}`).get()).data() || {};
    const year = new Date().getFullYear();
    const number = `INV-${year}-${doc.id.slice(-4).toUpperCase()}`;
    const total = b.totalAmount ?? b.estimatedPrice ?? 0;
    const items = Array.isArray(b.lineItems) && b.lineItems.length
      ? b.lineItems
      : [{label: b.serviceName, detail: '', amount: total}];
    const signedOff = b.completedAt || Timestamp.now();
    await db.runTransaction(async (tx) => {
      tx.set(receiptRef, {
        bookingId: doc.id,
        customerId: b.customerId,
        providerId: b.providerId,
        receiptNumber: number,
        bookingReference: b.reference || doc.id.slice(0, 6).toUpperCase(),
        issuedAt: FieldValue.serverTimestamp(),
        signedOffAt: signedOff,
        serviceDate: b.scheduledAt ?? null,
        startTime: b.startTime ?? '',
        endTime: b.endTime ?? '',
        providerName: pro.name || b.providerName || '',
        providerTitle: pro.specialty || '',
        providerPhotoUrl: pro.photoUrl || null,
        licenseNumber: pro.licenseNumber || '',
        customerName: b.customerName || '',
        serviceAddress: b.address || '',
        lineItems: items,
        totalAmount: total,
        paymentMethod: b.paymentMethod || 'cash',
        cardLast4: b.cardLast4 || null,
        paymentStatus: 'paid',
        paymentNote: b.paymentMethod === 'card'
          ? `LKR ${total.toLocaleString('en-US')} released from escrow to ` +
            `${pro.name || 'the professional'} after job sign-off.`
          : 'Paid to the professional on completion.',
        verificationCode: `HOMECARE|${number}|${b.reference || doc.id}|${total}`,
      });
      tx.update(doc.ref, {
        paymentStatus: 'paid',
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    console.log(`receipt ${number} issued for booking ${doc.id}`);
  }
}

async function pass() {
  await advanceRefunds();
  await issueReceipts();
}

if (args.has('--watch')) {
  console.log(`Worker running (refunds settle after ${settleAfterMs / 1000}s). Ctrl+C to stop.`);
  for (;;) {
    try {
      await pass();
    } catch (error) {
      console.error(error);
    }
    await new Promise((resolve) => setTimeout(resolve, 15000));
  }
} else {
  await pass();
  process.exit(0);
}
