import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";
import * as https from "https";
import { db } from "../../services/firebase";
import { collections } from "../../constants/collections";

const razorpayKeyId = defineSecret("RAZORPAY_KEY_ID");
const razorpayKeySecret = defineSecret("RAZORPAY_KEY_SECRET");

/**
 * Creates a Razorpay Order server-side and returns the razorpayOrderId to Flutter.
 *
 * Flutter must pass this `razorpayOrderId` into the Razorpay checkout `order_id` field.
 * This is required so the webhook can match payments to app orders.
 */
export const createRazorpayOrder = onCall(
  { secrets: [razorpayKeyId, razorpayKeySecret] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const { orderId, amountPaise } = request.data as {
      orderId: string;
      amountPaise: number;
    };

    if (!orderId || !amountPaise || amountPaise < 100) {
      throw new HttpsError("invalid-argument", "orderId and amountPaise (min 100) are required.");
    }

    // Verify the order belongs to the caller
    const orderSnap = await db.collection(collections.orders).doc(orderId).get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }
    if (orderSnap.data()?.customerId !== request.auth.uid) {
      throw new HttpsError("permission-denied", "This order does not belong to you.");
    }

    const keyId = razorpayKeyId.value();
    const keySecret = razorpayKeySecret.value();

    if (!keyId || !keySecret) {
      logger.error("Razorpay secrets not configured");
      throw new HttpsError("internal", "Payment system not configured.");
    }

    try {
      const razorpayOrder = await createRazorpayOrderViaApi({
        keyId,
        keySecret,
        amountPaise,
        currency: "INR",
        receipt: orderId,
        notes: { app_order_id: orderId },
      });

      // Store the razorpayOrderId on the app order for webhook matching
      await db.collection(collections.orders).doc(orderId).set(
        { razorpayOrderId: razorpayOrder.id, updatedAt: new Date() },
        { merge: true }
      );

      logger.info("Razorpay order created", { orderId, razorpayOrderId: razorpayOrder.id });

      return {
        razorpayOrderId: razorpayOrder.id,
        keyId,
        amountPaise,
        currency: "INR",
      };
    } catch (err) {
      logger.error("Failed to create Razorpay order", { orderId, error: err });
      throw new HttpsError("internal", "Failed to create payment order. Please retry.");
    }
  }
);

function createRazorpayOrderViaApi(params: {
  keyId: string;
  keySecret: string;
  amountPaise: number;
  currency: string;
  receipt: string;
  notes: Record<string, string>;
}): Promise<{ id: string }> {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      amount: params.amountPaise,
      currency: params.currency,
      receipt: params.receipt,
      notes: params.notes,
    });

    const auth = Buffer.from(`${params.keyId}:${params.keySecret}`).toString("base64");

    const options: https.RequestOptions = {
      hostname: "api.razorpay.com",
      path: "/v1/orders",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${auth}`,
        "Content-Length": Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.id) {
            resolve(parsed as { id: string });
          } else {
            reject(new Error(`Razorpay API error: ${JSON.stringify(parsed)}`));
          }
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}
