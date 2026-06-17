import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { submitRating } from "../../services/ratingService";
import { db } from "../../services/firebase";
import { collections } from "../../constants/collections";

/**
 * Callable: submitRating
 *
 * Allows a user to submit a rating (1–5 stars) for a completed order.
 * Idempotent — one rating per order per rater.
 * Triggers rating aggregation on the ratee's profile.
 */
export const submitRatingFn = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const { orderId, rateeId, rateeRole, stars, comment } = request.data as {
    orderId: string;
    rateeId: string;
    rateeRole: "seller" | "driver";
    stars: number;
    comment?: string;
  };

  if (!orderId || !rateeId || !rateeRole || !stars) {
    throw new HttpsError("invalid-argument", "orderId, rateeId, rateeRole, and stars are required.");
  }

  if (stars < 1 || stars > 5 || !Number.isInteger(stars)) {
    throw new HttpsError("invalid-argument", "stars must be an integer between 1 and 5.");
  }

  // Verify the order exists and is completed
  const orderSnap = await db.collection(collections.orders).doc(orderId).get();
  if (!orderSnap.exists) {
    throw new HttpsError("not-found", "Order not found.");
  }

  const order = orderSnap.data()!;
  const completedStatuses = ["DELIVERED", "COMPLETED"];
  if (!completedStatuses.includes(order.status)) {
    throw new HttpsError("failed-precondition", "Can only rate completed orders.");
  }

  // Verify the caller was part of this order
  const isCustomer = order.customerId === request.auth.uid;
  const isSeller = order.sellerId === request.auth.uid;
  const isDriver = order.driverId === request.auth.uid;

  if (!isCustomer && !isSeller && !isDriver) {
    throw new HttpsError("permission-denied", "You were not part of this order.");
  }

  try {
    const ratingId = await submitRating({
      orderId,
      raterId: request.auth.uid,
      rateeId,
      rateeRole,
      stars,
      comment,
    });

    logger.info("Rating submitted via callable", { ratingId, orderId, stars });
    return { success: true, ratingId };
  } catch (err) {
    logger.error("submitRating callable error", { orderId, error: err });
    throw new HttpsError(
      "internal",
      err instanceof Error ? err.message : "Failed to submit rating."
    );
  }
});
