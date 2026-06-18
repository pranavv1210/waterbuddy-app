import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import {
  cleanExpiredOffers,
  cleanStaleOrders,
  cleanOrphanNotifications,
  cleanInactiveLocations,
  cleanOldDispatchLogs,
  cleanDedupRecords,
  cleanOldMetrics,
  cleanOrphanSessions,
  aggregateDailyMetrics,
  reconcileWallets,
  recalculateRatings,
  compileMonthlySellerStats,
  compileMonthlyDriverStats,
  generateMonthlyCommissionReports,
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

/**
 * Once per day at 1:00 AM UTC: delete system metrics older than 90 days.
 */
export const cleanupOldMetrics = onSchedule("0 1 * * *", async () => {
  try {
    const count = await cleanOldMetrics(90);
    logger.info(`Scheduled: cleanupOldMetrics — deleted ${count} old metrics docs`);
  } catch (err) {
    logger.error("Scheduled: cleanupOldMetrics failed", { error: err });
  }
});

/**
 * Every hour: clean up orphan sessions (active orders stuck for > 24 hours).
 */
export const cleanupOrphanSessions = onSchedule("every 60 minutes", async () => {
  try {
    const count = await cleanOrphanSessions();
    logger.info(`Scheduled: cleanupOrphanSessions — cancelled ${count} orphan sessions`);
  } catch (err) {
    logger.error("Scheduled: cleanupOrphanSessions failed", { error: err });
  }
});

/**
 * Daily aggregation and reconciliation tasks.
 * Scheduled to run once per day at 2:00 AM UTC.
 */
export const dailyMaintenanceJobs = onSchedule("0 2 * * *", async () => {
  try {
    await Promise.all([
      aggregateDailyMetrics(),
      reconcileWallets(),
      recalculateRatings(),
    ]);
    logger.info("Scheduled: dailyMaintenanceJobs finished successfully");
  } catch (err) {
    logger.error("Scheduled: dailyMaintenanceJobs failed", { error: err });
  }
});

/**
 * Monthly analytics compile and invoicing.
 * Scheduled to run once per month on the 1st day at midnight.
 */
export const monthlyReportingJobs = onSchedule("0 0 1 * *", async () => {
  try {
    await Promise.all([
      compileMonthlySellerStats(),
      compileMonthlyDriverStats(),
      generateMonthlyCommissionReports(),
    ]);
    logger.info("Scheduled: monthlyReportingJobs finished successfully");
  } catch (err) {
    logger.error("Scheduled: monthlyReportingJobs failed", { error: err });
  }
});
