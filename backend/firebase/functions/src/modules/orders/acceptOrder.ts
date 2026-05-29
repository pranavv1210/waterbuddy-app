import { onCall, HttpsError } from "firebase-functions/v2/https";
import { DispatchService } from "../../services/dispatchService";

const dispatchService = new DispatchService();

export const acceptOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const { offerId, driverId } = request.data as {
    offerId: string;
    driverId?: string | null;
  };
  if (!offerId) {
    throw new HttpsError("invalid-argument", "offerId is required.");
  }

  try {
    return await dispatchService.acceptOffer({
      offerId,
      sellerId: request.auth.uid,
      driverId: driverId ?? request.auth.uid,
    });
  } catch (error) {
    throw new HttpsError(
      "failed-precondition",
      error instanceof Error ? error.message : "Unable to accept offer."
    );
  }
});
