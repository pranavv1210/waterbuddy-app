import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import { NotificationService } from "../../services/notificationService";
import { AnalyticsService } from "../../services/analyticsService";
import { collections } from "../../constants/collections";
import { db } from "../../services/firebase";
import { OrderStatus } from "../../models/domain";

const notifications = new NotificationService();
const analytics = new AnalyticsService();

/**
 * Firestore trigger: fires on every order document update.
 * Routes status transitions to FCM notifications and analytics counters.
 * This is the single source of truth for status-driven notifications.
 */
export const onOrderStatusChanged = onDocumentUpdated(
  `${collections.orders}/{orderId}`,
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    const previousStatus = before.status as OrderStatus | undefined;
    const newStatus = after.status as OrderStatus | undefined;
    const orderId = event.params.orderId;

    // No status change — nothing to do
    if (previousStatus === newStatus) return;

    const customerId = after.customerId as string | undefined;
    const sellerId = after.sellerId as string | null | undefined;
    const driverId = after.driverId as string | null | undefined;

    logger.info("Order status changed", { orderId, previousStatus, newStatus });

    try {
      switch (newStatus) {
        case "ACCEPTED":
          if (customerId) {
            await notifications.notifyOrderAccepted(customerId, orderId);
          }
          break;

        case "DRIVER_ASSIGNED":
          if (customerId) {
            // Fetch driver name if available
            let driverName: string | undefined;
            if (driverId) {
              const driverSnap = await db.collection(collections.drivers).doc(driverId).get();
              driverName = driverSnap.data()?.name as string | undefined;
            }
            await notifications.notifyDriverAssigned(customerId, orderId, driverName);
          }
          break;

        case "ON_THE_WAY": {
          if (customerId) {
            await notifications.notifyDriverEnRoute(customerId, orderId);
          }
          // Also notify the driver of the assignment confirmation
          if (driverId && previousStatus !== "ON_THE_WAY") {
            await notifications.send({
              userIds: [driverId],
              title: "Delivery started",
              body: "Navigate to the customer's location.",
              type: "DRIVER_ASSIGNED",
              data: { orderId, status: "ON_THE_WAY" },
              dedupKey: `driver_start_${orderId}`,
            });
          }
          break;
        }

        case "ARRIVED":
          if (customerId) {
            await notifications.notifyDriverArrived(customerId, orderId);
          }
          break;

        case "DELIVERED": {
          if (customerId) {
            await notifications.notifyOrderDelivered(customerId, orderId);
          }

          // Analytics
          await analytics.incrementOrdersCompleted();

          // Record revenue
          const amount = after.amount as number | undefined;
          if (amount && amount > 0) {
            await analytics.recordRevenue(amount * 100); // store in paise
          }

          // Record delivery time
          const createdAt = before.createdAt?.toDate?.() as Date | undefined;
          const now = new Date();
          if (createdAt) {
            const durationMinutes = Math.round((now.getTime() - createdAt.getTime()) / 60000);
            await analytics.recordDeliveryTime(durationMinutes);
          }

          // Free up seller availability
          if (sellerId) {
            await db.collection(collections.sellers).doc(sellerId).set(
              {
                isAvailable: true,
                activeOrderId: null,
                updatedAt: new Date(),
              },
              { merge: true }
            );
          }
          break;
        }

        case "CANCELLED": {
          const cancelledBySystem = after.cancelledBy === "system";
          const reason = after.cancellationReason as string | undefined;

          const notifyIds: string[] = [];
          if (customerId) notifyIds.push(customerId);
          if (sellerId) notifyIds.push(sellerId);
          if (driverId && driverId !== sellerId) notifyIds.push(driverId);

          await notifications.notifyOrderCancelled(notifyIds, orderId, reason);

          await analytics.incrementOrdersCancelled();

          // Free up seller
          if (sellerId) {
            await db.collection(collections.sellers).doc(sellerId).set(
              {
                isAvailable: true,
                activeOrderId: null,
                updatedAt: new Date(),
              },
              { merge: true }
            );
          }

          // Alert admins for system-cancelled orders
          if (cancelledBySystem) {
            await notifications.notifyAdmins(
              "System order cancellation",
              `Order ${orderId} was cancelled by system. Reason: ${reason ?? "unknown"}`,
              { orderId }
            );
          }
          break;
        }

        case "NO_PARTNER_FOUND":
          if (customerId) {
            await notifications.notifyNoPartnerFound(customerId, orderId);
          }
          await analytics.incrementOrdersCancelled();
          break;

        case "FAILED":
          // Already handled in dispatchService.failOrder — notify admins
          await notifications.notifyAdmins(
            "Order failed",
            `Order ${orderId} failed: ${after.failureReason ?? "unknown"}`,
            { orderId }
          );
          break;

        default:
          // SEARCHING, OFFER_SENT, DELIVERING — no notification needed here
          break;
      }
    } catch (err) {
      logger.error("onOrderStatusChanged error", { orderId, newStatus, error: err });
    }
  }
);
