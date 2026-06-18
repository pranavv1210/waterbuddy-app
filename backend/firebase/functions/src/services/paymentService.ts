import * as crypto from "crypto";
import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { collections } from "../constants/collections";
import { PaymentEvent, PaymentStatus } from "../models/domain";
import { db } from "./firebase";
import { NotificationService } from "./notificationService";
import { WalletService } from "./walletService";
import { RefundService } from "./refundService";

const notificationService = new NotificationService();
const walletService = new WalletService();
const refundService = new RefundService(walletService);

/**
 * Verifies a Razorpay webhook or checkout signature.
 *
 * For webhooks: body is the raw request body string, signature is
 * the value of the `x-razorpay-signature` header.
 *
 * For checkout (client-side callback verification):
 *   body = `${razorpayOrderId}|${razorpayPaymentId}`
 *   signature = response.razorpay_signature
 */
export function verifyRazorpaySignature(
  body: string,
  signature: string,
  secret: string
): boolean {
  try {
    const hmac = crypto.createHmac("sha256", secret);
    hmac.update(body);
    const computed = hmac.digest("hex");
    return crypto.timingSafeEqual(Buffer.from(computed), Buffer.from(signature));
  } catch {
    return false;
  }
}

/**
 * Records a payment lifecycle event (idempotent via `razorpayPaymentId` dedup).
 */
export async function recordPaymentEvent(
  orderId: string,
  event: PaymentEvent["event"],
  metadata: Partial<PaymentEvent>
): Promise<void> {
  const eventId = metadata.razorpayPaymentId
    ? `${event}_${metadata.razorpayPaymentId}`
    : `${event}_${orderId}_${Date.now()}`;

  const ref = db.collection(collections.paymentEvents).doc(eventId);
  const existing = await ref.get();
  if (existing.exists) {
    logger.info("Payment event already recorded (idempotent skip)", { eventId });
    return;
  }

  const record: Partial<PaymentEvent> = {
    orderId,
    event,
    status: metadata.status ?? "PENDING",
    ...metadata,
    processedAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  };

  await ref.set(record);
  logger.info("Payment event recorded", { eventId, orderId, event });
}

/**
 * Processes a successful Razorpay payment.
 * - Atomically marks the order as PAID in Firestore.
 * - Records the payment event.
 * - Notifies the customer.
 */
export async function processPaymentSuccess(
  orderId: string,
  razorpayPaymentId: string,
  razorpayOrderId: string,
  razorpaySignature: string,
  amount?: number
): Promise<void> {
  const orderRef = db.collection(collections.orders).doc(orderId);

  await db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) {
      logger.error("processPaymentSuccess: Order not found", { orderId });
      return;
    }
    const order = orderSnap.data()!;

    // Idempotency: if already paid, skip
    if (order.paymentStatus === "PAID" || order.paymentStatus === "COMPLETED") {
      logger.info("Order already paid — skipping duplicate", { orderId });
      return;
    }

    tx.update(orderRef, {
      paymentStatus: "PAID" as PaymentStatus,
      paymentId: razorpayPaymentId,
      razorpayOrderId,
      razorpaySignature,
      paidAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  await recordPaymentEvent(orderId, "payment_captured", {
    razorpayPaymentId,
    razorpayOrderId,
    razorpaySignature,
    status: "PAID",
    amount,
  });

  try {
    const orderSnap = await orderRef.get();
    const order = orderSnap.data() ?? {};
    const customerId = order.customerId as string | undefined;
    const paidAmount = amount != null ? amount / 100 : Number(order.amount ?? 0);
    if (customerId && paidAmount > 0) {
      await walletService.record({
        userId: customerId,
        role: "consumer",
        type: "ORDER_PAYMENT",
        direction: "EXTERNAL_SPEND",
        amount: paidAmount,
        createdBy: "payment_success",
        orderId,
        metadata: { razorpayPaymentId, razorpayOrderId },
      });
    }
  } catch (e) {
    logger.warn("Could not record payment wallet transaction", { orderId, error: e });
  }

  // Notify customer
  try {
    const orderSnap = await orderRef.get();
    const customerId = orderSnap.data()?.customerId as string | undefined;
    if (customerId) {
      await notificationService.notifyPaymentSuccess(customerId, orderId, amount ?? 0);
    }
  } catch (e) {
    logger.warn("Could not send payment success notification", { orderId, error: e });
  }
}

/**
 * Processes a failed Razorpay payment.
 */
export async function processPaymentFailure(
  orderId: string,
  razorpayPaymentId: string,
  errorCode?: string,
  errorDescription?: string
): Promise<void> {
  const orderRef = db.collection(collections.orders).doc(orderId);
  await orderRef.set(
    {
      paymentStatus: "FAILED" as PaymentStatus,
      paymentFailureCode: errorCode,
      paymentFailureDescription: errorDescription,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await recordPaymentEvent(orderId, "payment_failed", {
    razorpayPaymentId,
    status: "FAILED",
    errorCode,
    errorDescription,
  });

  // Notify customer
  try {
    const orderSnap = await orderRef.get();
    const customerId = orderSnap.data()?.customerId as string | undefined;
    if (customerId) {
      await notificationService.notifyPaymentFailed(customerId, orderId);
    }
  } catch (e) {
    logger.warn("Could not send payment failure notification", { orderId, error: e });
  }
}

/**
 * Processes a Razorpay refund event.
 */
export async function processRefund(
  orderId: string,
  razorpayRefundId: string,
  razorpayPaymentId: string,
  amount: number
): Promise<void> {
  const orderRef = db.collection(collections.orders).doc(orderId);
  await orderRef.set(
    {
      paymentStatus: "REFUNDED" as PaymentStatus,
      refundId: razorpayRefundId,
      refundAmount: amount,
      refundedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await recordPaymentEvent(orderId, "refund_created", {
    razorpayPaymentId,
    razorpayRefundId,
    status: "REFUNDED",
    amount,
  });

  try {
    const existing = await db
      .collection(collections.refunds)
      .where("razorpayRefundId", "==", razorpayRefundId)
      .limit(1)
      .get();
    if (existing.empty) {
      const orderSnap = await orderRef.get();
      const order = orderSnap.data() ?? {};
      const refund = await refundService.requestRefund({
        orderId,
        requestedBy: String(order.customerId),
        type: "PAYMENT_FAILURE",
        reason: "Razorpay refund webhook",
        requestedAmount: amount / 100,
      });
      await refundService.approveRefund({
        refundId: refund.refundId,
        adminId: "razorpay_webhook",
        razorpayRefundId,
      });
    }
  } catch (e) {
    logger.warn("Could not mirror refund into refund engine", { orderId, error: e });
  }

  logger.info("Refund processed", { orderId, razorpayRefundId, amount });
}
