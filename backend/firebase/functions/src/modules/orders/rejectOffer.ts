import { onCall, HttpsError } from "firebase-functions/v2/https";
import { DispatchService } from "../../services/dispatchService";

const dispatchService = new DispatchService();

export const rejectOffer = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const { offerId } = request.data as { offerId: string };
  if (!offerId) {
    throw new HttpsError("invalid-argument", "offerId is required.");
  }

  await dispatchService.rejectOffer({
    offerId,
    sellerId: request.auth.uid,
  });

  return { offerId, status: "rejected" };
});
