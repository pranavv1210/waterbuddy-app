import { useMemo } from "react";
import { OrderRecord } from "../../services/types";

interface OrderTrendsProps {
  orders: OrderRecord[];
}

export function OrderTrends({ orders }: OrderTrendsProps) {
  const days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

  const trendData = useMemo(() => {
    const today = new Date();
    const trendsMap: { [key: string]: number } = {};

    // Initialize all days with 0
    for (let i = 0; i < 7; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - (6 - i));
      const dayKey = date.toISOString().split("T")[0];
      trendsMap[dayKey] = 0;
    }

    // Count orders by date
    orders.forEach((order) => {
      if (order.createdAt) {
        const orderDate = new Date(order.createdAt).toISOString().split("T")[0];
        if (orderDate in trendsMap) {
          trendsMap[orderDate]++;
        }
      }
    });

    // Convert to array for display
    return Object.values(trendsMap);
  }, [orders]);

  const maxTrend = Math.max(...trendData, 1);

  return (
    <div className="rounded-2xl border border-white/5 bg-[#0D1117]/60 p-5 shadow-lg backdrop-blur-xl">
      <div className="mb-4 flex items-center justify-between gap-4">
        <div>
          <h2 className="text-lg font-bold text-white">Order Trends</h2>
          <p className="text-sm font-medium text-white/60">Volume tracking over the last 7 days</p>
        </div>
        <select className="rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-bold text-white outline-none backdrop-blur-sm focus:ring-2 focus:ring-[#14B8A6]/50">
          <option value="7" className="text-black">Last 7 Days</option>
          <option value="30" className="text-black">Last 30 Days</option>
        </select>
      </div>

      {/* Bar Chart */}
      <div className="group relative h-[220px] w-full overflow-hidden rounded-xl border border-white/5 bg-white/5 p-4 sm:h-[240px] sm:p-6">
        <div className="absolute inset-0 flex items-end justify-between px-4 pb-3 sm:px-6">
          {trendData.map((count, idx) => {
            const heightPercent = (count / maxTrend) * 100 || 5;
            const isHighest = count === Math.max(...trendData) && Math.max(...trendData) > 0;

            return (
              <div key={idx} className="flex w-full flex-col items-center gap-1.5">
                <div
                  className={`w-full rounded-t-lg transition-all duration-500 group-hover:opacity-100 ${
                    isHighest
                      ? "bg-[#14B8A6] opacity-100 shadow-[0_0_15px_rgba(20,184,166,0.5)]"
                      : "bg-[#0F766E]/50 opacity-60 group-hover:opacity-80 group-hover:bg-[#0F766E]"
                  }`}
                  style={{ height: `${Math.max(heightPercent, 10)}%` }}
                ></div>
                <span className={`text-[10px] font-bold ${isHighest ? "text-[#14B8A6]" : "text-white/60"}`}>
                  {days[idx]}
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
