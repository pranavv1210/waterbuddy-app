import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { collections } from "../../constants/collections";
import { db } from "../../services/firebase";

export const updateTracking = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const payload = request.data as {
    orderId: string;
    lat: number;
    lng: number;
  };

  await db.collection(collections.tracking).doc(payload.orderId).set({
    orderId: payload.orderId,
    lat: payload.lat,
    lng: payload.lng,
    timestamp: FieldValue.serverTimestamp(),
  });

  return { orderId: payload.orderId, ok: true };
});
