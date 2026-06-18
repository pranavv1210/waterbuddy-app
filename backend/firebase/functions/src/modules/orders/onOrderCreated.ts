import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { DispatchService } from "../../services/dispatchService";
import { AnalyticsService } from "../../services/analyticsService";

const dispatchService = new DispatchService();
const analytics = new AnalyticsService();

export const onOrderCreated = onDocumentCreated("orders/{orderId}", async (event) => {
  const orderId = event.params.orderId;
  await analytics.incrementOrdersCreated();
  await dispatchService.startDispatch(orderId);
});
