import { onCall, HttpsError } from "firebase-functions/v2/https";
import { RefundService } from "../../services/refundService";

const refunds = new RefundService();

export const rejectRefund = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  if (request.auth.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin role is required.");
  }

  const data = request.data as { refundId: string; reason: string };
  if (!data.refundId || !data.reason) {
    throw new HttpsError("invalid-argument", "refundId and reason are required.");
  }

  await refunds.rejectRefund({
    refundId: data.refundId,
    adminId: request.auth.uid,
    reason: data.reason,
  });
  return { refundId: data.refundId, status: "REJECTED" };
});
