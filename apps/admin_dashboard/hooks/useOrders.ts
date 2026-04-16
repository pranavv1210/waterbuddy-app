import { useEffect, useMemo, useState } from "react";

import { subscribeOrders } from "../services/orderService";
import { OrderRecord } from "../services/types";

export function useOrders(statusFilter: string = "all") {
  const [orders, setOrders] = useState<OrderRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    const unsubscribe = subscribeOrders(
      (nextOrders) => {
        setOrders(nextOrders);
        setLoading(false);
      },
      (nextError) => {
        setError(nextError.message);
        setLoading(false);
      },
    );

    return () => unsubscribe();
  }, []);

  const filteredOrders = useMemo(() => {
    if (statusFilter === "all") {
      return orders;
    }
    return orders.filter((order) => order.status.toLowerCase() === statusFilter.toLowerCase());
  }, [orders, statusFilter]);

  return { orders: filteredOrders, loading, error };
}
