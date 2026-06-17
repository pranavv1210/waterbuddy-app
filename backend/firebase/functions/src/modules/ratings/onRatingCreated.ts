import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import { aggregateRating } from "../../services/ratingService";
import { collections } from "../../constants/collections";

/**
 * Firestore trigger: fires when a new rating document is created.
 * Recomputes the aggregate rating for the ratee.
 *
 * This provides a backup aggregation path in case the submitRating
 * callable function's inline aggregation failed.
 */
export const onRatingCreated = onDocumentCreated(
  `${collections.ratings}/{ratingId}`,
  async (event) => {
    const rating = event.data?.data();
    if (!rating) return;

    const { rateeId, rateeRole } = rating as {
      rateeId: string;
      rateeRole: "seller" | "driver" | "customer";
    };

    if (!rateeId || !rateeRole || rateeRole === "customer") return;

    try {
      await aggregateRating(rateeId, rateeRole);
      logger.info("Rating aggregated on creation trigger", {
        ratingId: event.params.ratingId,
        rateeId,
        rateeRole,
      });
    } catch (err) {
      logger.error("onRatingCreated aggregation error", {
        ratingId: event.params.ratingId,
        rateeId,
        error: err,
      });
    }
  }
);
