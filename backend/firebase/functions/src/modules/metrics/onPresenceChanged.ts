import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { AnalyticsService } from "../../services/analyticsService";
import { collections } from "../../constants/collections";

const analytics = new AnalyticsService();

function onlineDelta(before: unknown, after: unknown): number {
  const wasOnline = before === true;
  const isOnline = after === true;
  if (wasOnline === isOnline) return 0;
  return isOnline ? 1 : -1;
}

export const onSellerPresenceChanged = onDocumentWritten(
  `${collections.sellers}/{sellerId}`,
  async (event) => {
    const delta = onlineDelta(
      event.data?.before?.data()?.isOnline,
      event.data?.after?.data()?.isOnline
    );
    if (delta !== 0) {
      await analytics.incrementActiveSellers(delta);
    }
  }
);

export const onDriverPresenceChanged = onDocumentWritten(
  `${collections.drivers}/{driverId}`,
  async (event) => {
    const delta = onlineDelta(
      event.data?.before?.data()?.isOnline,
      event.data?.after?.data()?.isOnline
    );
    if (delta !== 0) {
      await analytics.incrementActiveDrivers(delta);
    }
  }
);
