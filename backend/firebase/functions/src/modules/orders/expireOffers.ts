import { onSchedule } from "firebase-functions/v2/scheduler";
import { DispatchService } from "../../services/dispatchService";

const dispatchService = new DispatchService();

export const expireOffers = onSchedule("every 1 minutes", async () => {
  await dispatchService.expireStaleOffers();
});
