import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { collections } from "../constants/collections";
import { RatingRecord } from "../models/domain";
import { db } from "./firebase";

/**
 * Writes a new rating to Firestore and triggers aggregation.
 * Each order can only be rated once per rater.
 */
export async function submitRating(params: {
  orderId: string;
  raterId: string;
  rateeId: string;
  rateeRole: "seller" | "driver" | "customer" | "service";
  stars: number;
  comment?: string;
}): Promise<string> {
  if (params.stars < 1 || params.stars > 5) {
    throw new Error("Stars must be between 1 and 5");
  }

  // Idempotency: one rating per order + rater + ratee target.
  const dedupId = `${params.orderId}_${params.raterId}_${params.rateeRole}_${params.rateeId}`;
  const existingRef = db.collection(collections.ratings).doc(dedupId);
  const existing = await existingRef.get();
  if (existing.exists) {
    logger.info("Rating already submitted", { orderId: params.orderId, raterId: params.raterId });
    return dedupId;
  }

  const rating: Omit<RatingRecord, "id"> = {
    orderId: params.orderId,
    raterId: params.raterId,
    rateeId: params.rateeId,
    rateeRole: params.rateeRole,
    stars: params.stars,
    comment: params.comment,
    createdAt: FieldValue.serverTimestamp(),
  };

  await existingRef.set(rating);
  if (params.comment != null && params.comment.trim().length > 0) {
    await db.collection(collections.reviews).doc(dedupId).set({
      id: dedupId,
      orderId: params.orderId,
      raterId: params.raterId,
      rateeId: params.rateeId,
      rateeRole: params.rateeRole,
      comment: params.comment.trim(),
      stars: params.stars,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  logger.info("Rating submitted", {
    ratingId: dedupId,
    rateeId: params.rateeId,
    stars: params.stars,
  });

  // Immediately aggregate after write
  await aggregateRating(params.rateeId, params.rateeRole);

  return dedupId;
}

/**
 * Recomputes average rating and count for a given user (seller or driver).
 * Updates both the role-specific profile and the rating_aggregates collection.
 */
export async function aggregateRating(
  userId: string,
  role: "seller" | "driver" | "customer" | "service"
): Promise<void> {
  if (role === "customer" || role === "service") return; // No profile aggregation needed

  const ratingsSnapshot = await db
    .collection(collections.ratings)
    .where("rateeId", "==", userId)
    .where("rateeRole", "==", role)
    .get();

  if (ratingsSnapshot.empty) return;

  const stars = ratingsSnapshot.docs.map((d) => d.data().stars as number);
  const total = stars.reduce((sum, s) => sum + s, 0);
  const average = Math.round((total / stars.length) * 10) / 10; // 1 decimal
  const count = stars.length;

  const aggregate = {
    userId,
    role,
    averageRating: average,
    ratingCount: count,
    updatedAt: FieldValue.serverTimestamp(),
  };

  // Update the rating_aggregates document
  await db
    .collection(collections.ratingAggregates)
    .doc(userId)
    .set(aggregate, { merge: true });

  // Also update the profile document directly for fast reads
  const profileCollection =
    role === "seller" ? collections.sellers : collections.drivers;
  await db.collection(profileCollection).doc(userId).set(
    {
      averageRating: average,
      ratingCount: count,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  logger.info("Rating aggregated", { userId, role, average, count });

  const metricsCollection =
    role === "seller" ? collections.sellerMetrics : collections.driverMetrics;
  await db.collection(metricsCollection).doc(userId).set(
    {
      ratingAverage: average,
      ratingCount: count,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}
