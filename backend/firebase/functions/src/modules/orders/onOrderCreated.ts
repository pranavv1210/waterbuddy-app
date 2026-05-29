import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { DispatchService } from "../../services/dispatchService";

const dispatchService = new DispatchService();

export const onOrderCreated = onDocumentCreated("orders/{orderId}", async (event) => {
  const orderId = event.params.orderId;
  await dispatchService.startDispatch(orderId);
});
