import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";
import { verifyRazorpaySignature, processPaymentSuccess } from "../../services/paymentService";
import { db } from "../../services/firebase";
import { collections } from "../../constants/collections";

const razorpayKeySecret = defineSecret("RAZORPAY_KEY_SECRET");

/**
 * Callable: verifyPayment
 *
 * Flutter calls this after a successful Razorpay checkout.
 * Verifies the payment signature server-side before marking the order as PAID.
 * Flutter is NEVER allowed to mark orders as PAID directly.
 */
export const verifyPayment = onCall(
  { secrets: [razorpayKeySecret] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const { orderId, razorpayPaymentId, razorpayOrderId, razorpaySignature } =
      request.data as {
        orderId: string;
        razorpayPaymentId: string;
        razorpayOrderId: string;
        razorpaySignature: string;
      };

    if (!orderId || !razorpayPaymentId || !razorpayOrderId || !razorpaySignature) {
      throw new HttpsError(
        "invalid-argument",
        "orderId, razorpayPaymentId, razorpayOrderId, and razorpaySignature are all required."
      );
    }

    // Verify this order belongs to the caller
    const orderSnap = await db.collection(collections.orders).doc(orderId).get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }
    if (orderSnap.data()?.customerId !== request.auth.uid) {
      throw new HttpsError("permission-denied", "This order does not belong to you.");
    }

    const keySecret = razorpayKeySecret.value();
    if (!keySecret) {
      logger.error("verifyPayment: RAZORPAY_KEY_SECRET not configured");
      throw new HttpsError("internal", "Payment verification system not configured.");
    }

    // Razorpay checkout signature body: `${razorpayOrderId}|${razorpayPaymentId}`
    const signatureBody = `${razorpayOrderId}|${razorpayPaymentId}`;
    const isValid = verifyRazorpaySignature(signatureBody, razorpaySignature, keySecret);

    if (!isValid) {
      logger.warn("verifyPayment: Invalid signature", {
        orderId,
        razorpayPaymentId,
        uid: request.auth.uid,
      });
      throw new HttpsError("permission-denied", "Payment signature verification failed.");
    }

    // Signature is valid — mark order as paid
    await processPaymentSuccess(
      orderId,
      razorpayPaymentId,
      razorpayOrderId,
      razorpaySignature
    );

    logger.info("Payment verified and order marked PAID", { orderId, razorpayPaymentId });
    return { success: true, orderId, paymentId: razorpayPaymentId };
  }
);
