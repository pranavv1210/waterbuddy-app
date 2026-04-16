import { collection, onSnapshot, orderBy, query } from "firebase/firestore";

import { db } from "./firebase";
import { OrderRecord } from "./types";

function valueOrDash(value: unknown): string {
  return typeof value === "string" && value.trim().length > 0 ? value : "-";
}

function normalizeOrderStatus(rawStatus: unknown): string {
  const status = valueOrDash(rawStatus).toLowerCase();

  if (status === "pending" || status === "searching") {
    return "Searching";
  }
  if (status === "accepted" || status === "assigned") {
    return "Assigned";
  }
  if (status === "in_progress" || status === "on_the_way" || status === "on the way") {
    return "On the Way";
  }
  if (status === "delivered") {
    return "Delivered";
  }
  if (status === "cancelled") {
    return "Cancelled";
  }

  return status === "-" ? "Searching" : status;
}

function resolveTankSize(data: Record<string, unknown>): string {
  const explicitTankSize = valueOrDash(data.tankSize);
  if (explicitTankSize !== "-") {
    return explicitTankSize;
  }

  const itemName = valueOrDash(data.items ?? data.itemName);
  const quantity = data.quantity;
  const safeQuantity = typeof quantity === "number" && Number.isFinite(quantity) ? quantity : null;

  if (itemName === "-") {
    return "-";
  }

  return safeQuantity && safeQuantity > 0 ? `${itemName} x ${safeQuantity}` : itemName;
}

export function subscribeOrders(
  callback: (orders: OrderRecord[]) => void,
  onError: (error: Error) => void,
): () => void {
  const ordersQuery = query(collection(db, "orders"), orderBy("createdAt", "desc"));

  return onSnapshot(
    ordersQuery,
    (snapshot: any) => {
      const orders = snapshot.docs.map((doc: any) => {
        const data = doc.data();
        return {
          id: doc.id,
          customer: valueOrDash(data.customerName ?? data.customerId),
          seller: valueOrDash(data.sellerName ?? data.sellerId),
          status: normalizeOrderStatus(data.status),
          paymentType: valueOrDash(data.paymentType),
          tankSize: resolveTankSize(data),
          createdAt: data.createdAt?.toMillis ? data.createdAt.toMillis() : data.createdAt,
          items: valueOrDash(data.items ?? data.itemName),
          quantity: typeof data.quantity === "number" ? data.quantity : undefined,
        } satisfies OrderRecord;
      });
      callback(orders);
    },
    (error: any) => onError(error),
  );
}
