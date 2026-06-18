import { onCall, HttpsError } from "firebase-functions/v2/https";
import { RouteIntelligenceService } from "../../services/routeIntelligenceService";

const routeIntelligence = new RouteIntelligenceService();

export const updateTracking = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const payload = request.data as {
    orderId: string;
    lat: number;
    lng: number;
  };

  await routeIntelligence.updateTracking(payload);

  return { orderId: payload.orderId, ok: true };
});
