import { onCall, HttpsError } from "firebase-functions/v2/https";
import { RefundService } from "../../services/refundService";
import { RefundType } from "../../models/domain";

const refunds = new RefundService();

export const requestRefund = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const data = request.data as {
    orderId: string;
    type: RefundType;
    reason: string;
    requestedAmount?: number;
  };
  if (!data.orderId || !data.type || !data.reason) {
    throw new HttpsError("invalid-argument", "orderId, type, and reason are required.");
  }

  return refunds.requestRefund({
    orderId: data.orderId,
    requestedBy: request.auth.uid,
    type: data.type,
    reason: data.reason,
    requestedAmount: data.requestedAmount,
  });
});
