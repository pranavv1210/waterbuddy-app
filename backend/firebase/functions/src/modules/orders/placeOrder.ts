import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { collections } from "../../constants/collections";
import { OrderRecord } from "../../models/domain";
import { db } from "../../services/firebase";
import { SellerDiscoveryService } from "../../services/sellerDiscoveryService";
import { NotificationService } from "../../services/notificationService";

const sellerDiscoveryService = new SellerDiscoveryService();
const notificationService = new NotificationService();

export const placeOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const payload = request.data as {
    tankSize: number;
    paymentType: "ONLINE" | "COD";
    location: {
      address: string;
      lat: number;
      lng: number;
    };
  };

  const candidateSellerIds = await sellerDiscoveryService.findNearbyEligibleSellerIds({
    tankSize: payload.tankSize,
    lat: payload.location.lat,
    lng: payload.location.lng,
    limit: 5,
  });

  const orderRef = db.collection(collections.orders).doc();
  const order: OrderRecord = {
    id: orderRef.id,
    customerId: request.auth.uid,
    sellerId: null,
    tankSize: payload.tankSize,
    status: "SEARCHING",
    paymentType: payload.paymentType,
    paymentStatus: payload.paymentType === "ONLINE" ? "PENDING" : "COD_PENDING",
    location: payload.location,
    candidateSellerIds,
    rejectedSellerIds: [],
    createdAt: FieldValue.serverTimestamp() as never,
    updatedAt: FieldValue.serverTimestamp() as never,
  };

  await orderRef.set(order);

  await notificationService.send({
    userIds: candidateSellerIds,
    title: "New order request",
    body: "A new delivery request is available.",
    data: { orderId: order.id },
  });

  return { orderId: order.id, status: order.status };
});
