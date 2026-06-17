import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";
import {
  verifyRazorpaySignature,
  processPaymentSuccess,
  processPaymentFailure,
  processRefund,
} from "../../services/paymentService";

const razorpayWebhookSecret = defineSecret("RAZORPAY_WEBHOOK_SECRET");

/**
 * Razorpay Webhook Handler
 *
 * Receives payment events from Razorpay and verifies them server-side
 * using HMAC-SHA256. Flutter callbacks are NEVER trusted for payment
 * status updates.
 *
 * Configure in Razorpay Dashboard:
 *   Webhook URL: https://<region>-<project>.cloudfunctions.net/paymentWebhook
 *   Events: payment.captured, payment.failed, refund.created
 */
export const paymentWebhook = onRequest(
  {
    secrets: [razorpayWebhookSecret],
    // Allow unauthenticated requests (Razorpay doesn't send Firebase auth tokens)
    invoker: "public",
  },
  async (req, res) => {
    // Only allow POST
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const signature = req.headers["x-razorpay-signature"] as string | undefined;
    if (!signature) {
      logger.warn("Webhook: missing x-razorpay-signature header");
      res.status(400).json({ error: "Missing signature" });
      return;
    }

    // Razorpay sends the raw body — we need the raw string for HMAC verification
    const rawBody =
      typeof req.body === "string"
        ? req.body
        : JSON.stringify(req.body);

    const secret = razorpayWebhookSecret.value();
    if (!secret) {
      logger.error("Webhook: RAZORPAY_WEBHOOK_SECRET secret not configured");
      res.status(500).json({ error: "Server configuration error" });
      return;
    }

    const isValid = verifyRazorpaySignature(rawBody, signature, secret);
    if (!isValid) {
      logger.warn("Webhook: invalid signature — possible fraud attempt");
      res.status(401).json({ error: "Invalid signature" });
      return;
    }

    const event = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
    const eventType: string = event.event ?? "";
    const payload = event.payload ?? {};

    logger.info("Razorpay webhook received", { eventType });

    try {
      switch (eventType) {
        case "payment.captured": {
          const payment = payload.payment?.entity ?? {};
          const orderId = payment.notes?.app_order_id as string | undefined;
          if (!orderId) {
            logger.warn("Webhook: payment.captured missing app_order_id note", { paymentId: payment.id });
            break;
          }
          await processPaymentSuccess(
            orderId,
            payment.id as string,
            payment.order_id as string,
            signature,
            payment.amount as number
          );
          break;
        }

        case "payment.failed": {
          const payment = payload.payment?.entity ?? {};
          const orderId = payment.notes?.app_order_id as string | undefined;
          if (!orderId) {
            logger.warn("Webhook: payment.failed missing app_order_id note", { paymentId: payment.id });
            break;
          }
          await processPaymentFailure(
            orderId,
            payment.id as string,
            payment.error_code as string | undefined,
            payment.error_description as string | undefined
          );
          break;
        }

        case "refund.created": {
          const refund = payload.refund?.entity ?? {};
          const payment = payload.payment?.entity ?? {};
          const orderId = payment.notes?.app_order_id as string | undefined;
          if (!orderId) {
            logger.warn("Webhook: refund.created missing app_order_id note");
            break;
          }
          await processRefund(
            orderId,
            refund.id as string,
            refund.payment_id as string,
            refund.amount as number
          );
          break;
        }

        default:
          logger.info("Webhook: unhandled event type", { eventType });
      }

      // Always respond 200 quickly to acknowledge receipt
      res.status(200).json({ received: true });
    } catch (err) {
      logger.error("Webhook processing error", { eventType, error: err });
      // Still return 200 to prevent Razorpay from retrying for errors we already logged
      res.status(200).json({ received: true, error: "Processing error logged" });
    }
  }
);
