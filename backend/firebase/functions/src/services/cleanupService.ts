import { logger } from "firebase-functions";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { collections } from "../constants/collections";
import { db } from "./firebase";
import { NotificationService } from "./notificationService";

const notificationService = new NotificationService();

/**
 * Expires pending offers that have passed their expiresAt time.
 * Returns the count of expired offers.
 */
export async function cleanExpiredOffers(): Promise<number> {
  const snapshot = await db
    .collection(collections.orderOffers)
    .where("status", "==", "pending")
    .where("expiresAt", "<=", Timestamp.now())
    .limit(100)
    .get();

  if (snapshot.empty) return 0;

  const batch = db.batch();
  for (const doc of snapshot.docs) {
    batch.set(
      doc.ref,
      { status: "expired", updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
  }
  await batch.commit();
  logger.info(`cleanExpiredOffers: expired ${snapshot.size} offers`);
  return snapshot.size;
}

/**
 * Cancels orders that have been SEARCHING for longer than maxAgeMinutes
 * with no seller found, and notifies the customer.
 */
export async function cleanStaleOrders(maxAgeMinutes = 10): Promise<number> {
  const cutoff = Timestamp.fromMillis(Date.now() - maxAgeMinutes * 60 * 1000);
  const snapshot = await db
    .collection(collections.orders)
    .where("status", "==", "SEARCHING")
    .where("createdAt", "<=", cutoff)
    .limit(50)
    .get();

  if (snapshot.empty) return 0;

  await Promise.all(
    snapshot.docs.map(async (doc) => {
      const order = doc.data();
      await doc.ref.set(
        {
          status: "NO_PARTNER_FOUND",
          failureReason: "No seller found within timeout",
          currentOfferId: null,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      // Notify customer
      if (order.customerId) {
        await notificationService.notifyNoPartnerFound(order.customerId as string, doc.id).catch((e) =>
          logger.warn("Failed to notify customer on stale order", { orderId: doc.id, error: e })
        );
      }
    })
  );

  logger.info(`cleanStaleOrders: cancelled ${snapshot.size} stale orders`);
  return snapshot.size;
}

/**
 * Deletes read notifications older than retentionDays (default 7).
 */
export async function cleanOrphanNotifications(retentionDays = 7): Promise<number> {
  const cutoff = Timestamp.fromMillis(Date.now() - retentionDays * 24 * 60 * 60 * 1000);
  const snapshot = await db
    .collection(collections.notifications)
    .where("read", "==", true)
    .where("createdAt", "<=", cutoff)
    .limit(200)
    .get();

  if (snapshot.empty) return 0;

  const batch = db.batch();
  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();
  logger.info(`cleanOrphanNotifications: deleted ${snapshot.size} old notifications`);
  return snapshot.size;
}

/**
 * Removes seller_locations and driver_locations for users offline > inactiveHours.
 */
export async function cleanInactiveLocations(inactiveHours = 2): Promise<number> {
  const cutoff = Timestamp.fromMillis(Date.now() - inactiveHours * 60 * 60 * 1000);
  let count = 0;

  for (const col of [collections.sellerLocations, collections.driverLocations]) {
    const snap = await db
      .collection(col)
      .where("updatedAt", "<=", cutoff)
      .limit(50)
      .get();

    if (!snap.empty) {
      const batch = db.batch();
      for (const doc of snap.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();
      count += snap.size;
    }
  }

  // Also clear `currentLocation` field on offline sellers/drivers
  const offlineSellers = await db
    .collection(collections.sellers)
    .where("isOnline", "==", false)
    .where("lastActiveAt", "<=", cutoff)
    .limit(50)
    .get();

  if (!offlineSellers.empty) {
    const batch = db.batch();
    for (const doc of offlineSellers.docs) {
      if (doc.data().currentLocation) {
        batch.update(doc.ref, { currentLocation: FieldValue.delete() });
      }
    }
    await batch.commit();
  }

  logger.info(`cleanInactiveLocations: cleaned ${count} location documents`);
  return count;
}

/**
 * Deletes dispatch_logs older than retentionDays (default 30).
 */
export async function cleanOldDispatchLogs(retentionDays = 30): Promise<number> {
  const cutoff = Timestamp.fromMillis(Date.now() - retentionDays * 24 * 60 * 60 * 1000);
  const snapshot = await db
    .collection(collections.dispatchLogs)
    .where("createdAt", "<=", cutoff)
    .limit(500)
    .get();

  if (snapshot.empty) return 0;

  const batch = db.batch();
  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();
  logger.info(`cleanOldDispatchLogs: deleted ${snapshot.size} old logs`);
  return snapshot.size;
}

/**
 * Deletes notification dedup documents older than 2 days.
 */
export async function cleanDedupRecords(): Promise<number> {
  const cutoff = Timestamp.fromMillis(Date.now() - 2 * 24 * 60 * 60 * 1000);
  const snapshot = await db
    .collection(collections.notifications)
    .where("createdAt", "<=", cutoff)
    // Dedup docs are prefixed with "dedup_"
    .limit(200)
    .get();

  const dedupDocs = snapshot.docs.filter((d) => d.id.startsWith("dedup_"));
  if (dedupDocs.length === 0) return 0;

  const batch = db.batch();
  for (const doc of dedupDocs) {
    batch.delete(doc.ref);
  }
  await batch.commit();
  logger.info(`cleanDedupRecords: deleted ${dedupDocs.length} dedup records`);
  return dedupDocs.length;
}
