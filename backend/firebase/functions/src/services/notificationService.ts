import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { collections } from "../constants/collections";
import { NotificationType } from "../models/domain";
import { db, messaging } from "./firebase";

export interface NotificationPayload {
  userIds: string[];
  title: string;
  body: string;
  type?: NotificationType;
  data?: Record<string, string>;
  /** Optional dedup key — prevents sending the same notification twice */
  dedupKey?: string;
}

/**
 * Looks up FCM tokens across all three role sub-collections for a given userId.
 * Sellers and drivers store their tokens under sellers/{uid}/fcmTokens and
 * drivers/{uid}/fcmTokens in addition to users/{uid}/fcmTokens.
 */
async function getTokensForUser(userId: string): Promise<string[]> {
  const [userTokens, sellerTokens, driverTokens] = await Promise.all([
    db.collection(collections.users).doc(userId).collection("fcmTokens").get(),
    db.collection(collections.sellers).doc(userId).collection("fcmTokens").get(),
    db.collection(collections.drivers).doc(userId).collection("fcmTokens").get(),
  ]);

  const tokens = new Set<string>();

  for (const snap of [userTokens, sellerTokens, driverTokens]) {
    for (const doc of snap.docs) {
      const t = doc.id || (doc.data()["token"] as string | undefined);
      if (t) tokens.add(t);
    }
  }

  return [...tokens];
}

/**
 * Removes a batch of invalid FCM tokens from all possible sub-collections.
 */
async function removeInvalidTokens(userId: string, badTokens: string[]): Promise<void> {
  if (badTokens.length === 0) return;
  const batch = db.batch();
  for (const token of badTokens) {
    for (const col of [collections.users, collections.sellers, collections.drivers]) {
      batch.delete(db.collection(col).doc(userId).collection("fcmTokens").doc(token));
    }
  }
  await batch.commit().catch((e) => logger.warn("Failed to remove invalid tokens", { userId, error: e }));
}

export class NotificationService {
  async send(payload: NotificationPayload): Promise<void> {
    logger.info("Notification dispatch", {
      userIds: payload.userIds,
      type: payload.type,
      title: payload.title,
    });

    await Promise.all(
      payload.userIds.map(async (userId) => {
        // 1. Dedup check: skip if this notification was already sent
        if (payload.dedupKey) {
          const dedupRef = db
            .collection(collections.notifications)
            .doc(`dedup_${payload.dedupKey}_${userId}`);
          const existing = await dedupRef.get();
          if (existing.exists) {
            logger.info("Duplicate notification suppressed", { dedupKey: payload.dedupKey, userId });
            return;
          }
          // Mark as sent (TTL-style — no Cloud Function needed for dedup expiry)
          await dedupRef.set({ createdAt: FieldValue.serverTimestamp() });
        }

        // 2. Persist notification in Firestore (in-app notification centre)
        await db.collection(collections.notifications).add({
          userId,
          title: payload.title,
          body: payload.body,
          type: payload.type ?? "SYSTEM_ALERT",
          data: payload.data ?? {},
          read: false,
          createdAt: FieldValue.serverTimestamp(),
        });

        // 3. Look up FCM tokens from all role sub-collections
        const tokens = await getTokensForUser(userId);
        if (tokens.length === 0) {
          logger.info("No FCM tokens found for user", { userId });
          return;
        }

        // 4. Send FCM multicast
        const fcmData: Record<string, string> = {
          ...(payload.data ?? {}),
          type: payload.type ?? "SYSTEM_ALERT",
          title: payload.title,
          body: payload.body,
        };

        const response = await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title: payload.title,
            body: payload.body,
          },
          data: fcmData,
          android: {
            priority: "high",
            notification: {
              channelId: "waterbuddy_orders",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        });

        // 5. Remove invalid tokens
        const invalidTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const code = resp.error?.code ?? "";
            if (
              code === "messaging/registration-token-not-registered" ||
              code === "messaging/invalid-registration-token"
            ) {
              invalidTokens.push(tokens[idx]);
            } else {
              logger.warn("FCM send error", { userId, token: tokens[idx], error: resp.error?.message });
            }
          }
        });

        await removeInvalidTokens(userId, invalidTokens);
      })
    );
  }

  // ── Typed convenience methods ────────────────────────────────────────────────

  async notifyOrderCreated(customerId: string, orderId: string): Promise<void> {
    await this.send({
      userIds: [customerId],
      title: "Order placed",
      body: "We're searching for a nearby tanker. Hang tight!",
      type: "ORDER_OFFER",
      data: { orderId, status: "SEARCHING" },
      dedupKey: `order_created_${orderId}`,
    });
  }

  async notifySellerNewOffer(
    sellerId: string,
    orderId: string,
    offerId: string,
    distanceKm: number,
    timeoutSeconds: number
  ): Promise<void> {
    await this.send({
      userIds: [sellerId],
      title: "New water delivery request",
      body: `Nearest request ${distanceKm.toFixed(1)} km away. Accept within ${timeoutSeconds}s.`,
      type: "ORDER_OFFER",
      data: { orderId, offerId, type: "ORDER_OFFER" },
      dedupKey: `offer_${offerId}`,
    });
  }

  async notifyOrderAccepted(customerId: string, orderId: string): Promise<void> {
    await this.send({
      userIds: [customerId],
      title: "Tanker assigned ✅",
      body: "A nearby tanker accepted your request.",
      type: "ORDER_ACCEPTED",
      data: { orderId, status: "ACCEPTED" },
      dedupKey: `accepted_${orderId}`,
    });
  }

  async notifyDriverAssigned(
    customerId: string,
    orderId: string,
    driverName?: string
  ): Promise<void> {
    await this.send({
      userIds: [customerId],
      title: "Driver on the way 🚛",
      body: driverName ? `${driverName} is heading to you.` : "Your driver has been assigned.",
      type: "DRIVER_ASSIGNED",
      data: { orderId, status: "DRIVER_ASSIGNED" },
      dedupKey: `driver_assigned_${orderId}`,
    });
  }

  async notifyDriverEnRoute(customerId: string, orderId: string): Promise<void> {
    await this.send({
      userIds: [customerId],
      title: "Driver en route 📍",
      body: "Your driver is on the way. Track live on the map.",
      type: "DRIVER_EN_ROUTE",
      data: { orderId, status: "ON_THE_WAY" },
      dedupKey: `en_route_${orderId}`,
    });
  }

  async notifyDriverArrived(customerId: string, orderId: string): Promise<void> {
    await this.send({
      userIds: [customerId],
      title: "Driver arrived 🏠",
      body: "Your driver is at your location. Please be ready.",
      type: "DRIVER_ARRIVED",
      data: { orderId, status: "ARRIVED" },
      dedupKey: `arrived_${orderId}`,
    });
  }

  async notifyOrderDelivered(customerId: string, orderId: string): Promise<void> {
    await this.send({
      userIds: [customerId],
      title: "Delivery complete 💧",
      body: "Your water delivery is complete. Rate your experience!",
      type: "ORDER_DELIVERED",
      data: { orderId, status: "DELIVERED" },
      dedupKey: `delivered_${orderId}`,
    });
  }

  async notifyOrderCancelled(
    userIds: string[],
    orderId: string,
    reason?: string
  ): Promise<void> {
    await this.send({
      userIds,
      title: "Order cancelled",
      body: reason ?? "Your order has been cancelled.",
      type: "ORDER_CANCELLED",
      data: { orderId, status: "CANCELLED" },
      dedupKey: `cancelled_${orderId}`,
    });
  }

  async notifyNoPartnerFound(customerId: string, orderId: string): Promise<void> {
    await this.send({
      userIds: [customerId],
      title: "No tanker found",
      body: "No available tanker accepted this request. Please retry.",
      type: "ORDER_CANCELLED",
      data: { orderId, status: "NO_PARTNER_FOUND" },
      dedupKey: `no_partner_${orderId}`,
    });
  }

  async notifyPaymentSuccess(customerId: string, orderId: string, amount: number): Promise<void> {
    await this.send({
      userIds: [customerId],
      title: "Payment successful ✅",
      body: `₹${(amount / 100).toFixed(2)} paid successfully.`,
      type: "PAYMENT_SUCCESS",
      data: { orderId, status: "PAID" },
      dedupKey: `payment_success_${orderId}`,
    });
  }

  async notifyPaymentFailed(customerId: string, orderId: string): Promise<void> {
    await this.send({
      userIds: [customerId],
      title: "Payment failed ❌",
      body: "Your payment could not be processed. Please try again.",
      type: "PAYMENT_FAILED",
      data: { orderId, status: "FAILED" },
    });
  }

  async notifyAdmins(title: string, body: string, data?: Record<string, string>): Promise<void> {
    try {
      const adminSnapshot = await db.collection(collections.admins).get();
      const adminIds = adminSnapshot.docs.map((d) => d.id);
      if (adminIds.length > 0) {
        await this.send({ userIds: adminIds, title, body, type: "SYSTEM_ALERT", data });
      }
    } catch (e) {
      logger.error("Failed to notify admins", { error: e });
    }
  }
}
