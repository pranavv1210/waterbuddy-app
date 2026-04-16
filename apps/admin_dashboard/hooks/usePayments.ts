import { useEffect, useState } from "react";

import { subscribePaymentDashboard } from "../services/paymentService";
import { PaymentDashboardData } from "../services/types";

const initialDashboard: PaymentDashboardData = {
  summary: {
    totalRevenue: 0,
    codRevenue: 0,
    onlineRevenue: 0,
    codCount: 0,
    onlineCount: 0,
  },
  weeklyRevenue: [
    { label: "WK 1", gross: 0, net: 0 },
    { label: "WK 2", gross: 0, net: 0 },
    { label: "WK 3", gross: 0, net: 0 },
    { label: "WK 4", gross: 0, net: 0 },
  ],
  recentPayouts: [],
};

export function usePayments() {
  const [dashboard, setDashboard] = useState<PaymentDashboardData>(initialDashboard);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    const unsubscribe = subscribePaymentDashboard(
      (nextDashboard) => {
        setDashboard(nextDashboard);
        setLoading(false);
      },
      (nextError) => {
        setError(nextError.message);
        setLoading(false);
      },
    );

    return () => unsubscribe();
  }, []);

  return { dashboard, loading, error };
}
