import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { collections } from "../../constants/collections";
import { db } from "../../services/firebase";
import { NotificationService } from "../../services/notificationService";

const notificationService = new NotificationService();

export const acceptOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const { orderId } = request.data as { orderId: string };
  const orderRef = db.collection(collections.orders).doc(orderId);

  const updatedOrder = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(orderRef);

    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const order = snapshot.data();

    if (order?.status !== "SEARCHING") {
      throw new HttpsError("failed-precondition", "Order is no longer open.");
    }

    const nextOrder = {
      ...order,
      sellerId: request.auth.uid,
      status: "ASSIGNED",
      rejectedSellerIds: (order?.candidateSellerIds ?? []).filter(
        (candidateSellerId: string) => candidateSellerId !== request.auth.uid
      ),
      updatedAt: FieldValue.serverTimestamp(),
    };

    transaction.update(orderRef, nextOrder);
    return nextOrder;
  });

  await notificationService.send({
    userIds: [updatedOrder.customerId],
    title: "Order assigned",
    body: "A seller accepted your order.",
    data: { orderId },
  });

  return { orderId, status: updatedOrder.status };
});
