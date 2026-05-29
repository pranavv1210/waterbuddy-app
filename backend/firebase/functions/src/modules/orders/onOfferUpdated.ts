import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { DispatchService } from "../../services/dispatchService";

const dispatchService = new DispatchService();

export const onOfferUpdated = onDocumentUpdated(
  "order_offers/{offerId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;

    const offerId = event.params.offerId;
    if (after.status === "accepted") {
      await dispatchService.acceptOffer({
        offerId,
        sellerId: after.sellerId,
        driverId: after.driverId ?? after.sellerId,
      });
    }
    if (after.status === "rejected") {
      await dispatchService.rejectOffer({
        offerId,
        sellerId: after.sellerId,
      });
    }
  }
);
