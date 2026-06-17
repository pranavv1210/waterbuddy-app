import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import {
  cleanExpiredOffers,
  cleanStaleOrders,
  cleanOrphanNotifications,
  cleanInactiveLocations,
  cleanOldDispatchLogs,
  cleanDedupRecords,
} from "../../services/cleanupService";

/**
 * Every 5 minutes: expire pending offers that have passed their timeout.
 * This is the primary offer expiry mechanism.
 */
export const cleanupExpiredOffers = onSchedule("every 5 minutes", async () => {
  try {
    const count = await cleanExpiredOffers();
    logger.info(`Scheduled: cleanExpiredOffers — expired ${count} offers`);
  } catch (err) {
    logger.error("Scheduled: cleanExpiredOffers failed", { error: err });
  }
});

/**
 * Every 15 minutes: cancel orders stuck in SEARCHING for > 10 minutes.
 */
export const cleanupStaleOrders = onSchedule("every 15 minutes", async () => {
  try {
    const count = await cleanStaleOrders(10);
    logger.info(`Scheduled: cleanStaleOrders — cancelled ${count} stale orders`);
  } catch (err) {
    logger.error("Scheduled: cleanStaleOrders failed", { error: err });
  }
});

/**
 * Every 30 minutes: delete read notifications older than 7 days.
 * Also cleans notification dedup records older than 2 days.
 */
export const cleanupOrphanNotifications = onSchedule("every 30 minutes", async () => {
  try {
    const [notifCount, dedupCount] = await Promise.all([
      cleanOrphanNotifications(7),
      cleanDedupRecords(),
    ]);
    logger.info(
      `Scheduled: cleanOrphanNotifications — deleted ${notifCount} notifications, ${dedupCount} dedup records`
    );
  } catch (err) {
    logger.error("Scheduled: cleanOrphanNotifications failed", { error: err });
  }
});

/**
 * Every hour: remove stale seller/driver location documents for users
 * who have been offline > 2 hours.
 */
export const cleanupInactiveLocations = onSchedule("every 60 minutes", async () => {
  try {
    const count = await cleanInactiveLocations(2);
    logger.info(`Scheduled: cleanInactiveLocations — cleaned ${count} location documents`);
  } catch (err) {
    logger.error("Scheduled: cleanInactiveLocations failed", { error: err });
  }
});

/**
 * Once per day at midnight UTC: delete dispatch logs older than 30 days.
 */
export const cleanupOldDispatchLogs = onSchedule("0 0 * * *", async () => {
  try {
    const count = await cleanOldDispatchLogs(30);
    logger.info(`Scheduled: cleanOldDispatchLogs — deleted ${count} old logs`);
  } catch (err) {
    logger.error("Scheduled: cleanOldDispatchLogs failed", { error: err });
  }
});
