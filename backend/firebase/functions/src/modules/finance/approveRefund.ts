import { onCall, HttpsError } from "firebase-functions/v2/https";
import { RefundService } from "../../services/refundService";

const refunds = new RefundService();

export const approveRefund = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  if (request.auth.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin role is required.");
  }

  const data = request.data as { refundId: string; razorpayRefundId?: string };
  if (!data.refundId) {
    throw new HttpsError("invalid-argument", "refundId is required.");
  }

  await refunds.approveRefund({
    refundId: data.refundId,
    adminId: request.auth.uid,
    razorpayRefundId: data.razorpayRefundId,
  });
  return { refundId: data.refundId, status: "PROCESSED" };
});
