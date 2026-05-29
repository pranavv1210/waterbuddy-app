import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { collections } from "../../constants/collections";
import { OrderRecord } from "../../models/domain";
import { db } from "../../services/firebase";
import { DispatchService } from "../../services/dispatchService";

const dispatchService = new DispatchService();

export const placeOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const settings = await dispatchService.getSettings();
  if (!settings.bookingsEnabled || settings.maintenanceMode) {
    throw new HttpsError("failed-precondition", "Bookings are currently disabled.");
  }

  const payload = request.data as {
    tankSize: number;
    tankLabel?: string;
    tankId?: string;
    amount?: number;
    pricingSnapshot?: Record<string, unknown>;
    paymentType: "ONLINE" | "COD";
    location: {
      address: string;
      lat?: number;
      lng?: number;
      latitude?: number;
      longitude?: number;
    };
  };

  const orderRef = db.collection(collections.orders).doc();
  const latitude = Number(payload.location.latitude ?? payload.location.lat);
  const longitude = Number(payload.location.longitude ?? payload.location.lng);
  const order: OrderRecord = {
    id: orderRef.id,
    customerId: request.auth.uid,
    customerName: request.auth.token.name ?? "",
    customerPhone: request.auth.token.phone_number ?? "",
    sellerId: null,
    driverId: null,
    tankSize: payload.tankSize,
    tankLabel: payload.tankLabel ?? `${payload.tankSize}L Tanker`,
    tankId: payload.tankId ?? "",
    amount: payload.amount ?? 0,
    pricingSnapshot: payload.pricingSnapshot ?? {},
    status: "SEARCHING",
    paymentType: payload.paymentType,
    paymentStatus: "PENDING",
    location: {
      address: payload.location.address,
      latitude,
      longitude,
      lat: latitude,
      lng: longitude,
    } as never,
    candidateSellerIds: [],
    rejectedSellerIds: [],
    currentOfferId: null,
    dispatchAttempt: 0,
    createdAt: FieldValue.serverTimestamp() as never,
    updatedAt: FieldValue.serverTimestamp() as never,
  };

  await orderRef.set(order);
  await dispatchService.startDispatch(orderRef.id);

  return { orderId: order.id, status: order.status };
});
