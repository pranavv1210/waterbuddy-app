import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { collections } from "../constants/collections";
import { db, messaging } from "./firebase";

interface NotificationPayload {
  userIds: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

export class NotificationService {
  async send(payload: NotificationPayload): Promise<void> {
    logger.info("Notification dispatch", payload);
    await Promise.all(
      payload.userIds.map(async (userId) => {
        await db.collection(collections.notifications).add({
          userId,
          title: payload.title,
          body: payload.body,
          data: payload.data ?? {},
          read: false,
          createdAt: FieldValue.serverTimestamp(),
        });

        const tokenSnapshots = await Promise.all([
          db.collection(collections.users).doc(userId).collection("fcmTokens").get(),
          db.collection(collections.sellers).doc(userId).collection("fcmTokens").get(),
          db.collection(collections.drivers).doc(userId).collection("fcmTokens").get(),
        ]);
        const tokens = tokenSnapshots
          .flatMap((snapshot) => snapshot.docs)
          .map((doc) => doc.id)
          .filter(Boolean);

        if (tokens.length === 0) return;
        await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title: payload.title,
            body: payload.body,
          },
          data: payload.data ?? {},
          android: {
            priority: "high",
            notification: {
              channelId: "waterbuddy_orders",
            },
          },
        });
      })
    );
  }
}
