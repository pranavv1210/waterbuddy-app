import { onCall, HttpsError } from "firebase-functions/v2/https";
import { PayoutService } from "../../services/payoutService";

const payouts = new PayoutService();

export const approveSellerPayout = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  if (request.auth.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin role is required.");
  }

  const data = request.data as { payoutId: string; method?: string };
  if (!data.payoutId) {
    throw new HttpsError("invalid-argument", "payoutId is required.");
  }
  await payouts.approveSellerPayout({
    payoutId: data.payoutId,
    adminId: request.auth.uid,
    method: data.method,
  });
  return { payoutId: data.payoutId, status: "PAID" };
});
