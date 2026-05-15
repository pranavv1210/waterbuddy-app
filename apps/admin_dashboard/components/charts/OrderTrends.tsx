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
    <div className="bg-[#0D1117]/60 backdrop-blur-xl rounded-2xl p-8 shadow-lg border border-white/5">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-xl font-bold text-white">Order Trends</h2>
          <p className="text-sm text-white/60 font-medium">Volume tracking over the last 7 days</p>
        </div>
        <select className="bg-white/5 border border-white/10 text-xs font-bold rounded-lg px-3 py-2 text-white focus:ring-2 focus:ring-[#14B8A6]/50 outline-none backdrop-blur-sm">
          <option value="7" className="text-black">Last 7 Days</option>
          <option value="30" className="text-black">Last 30 Days</option>
        </select>
      </div>

      {/* Bar Chart */}
      <div className="relative h-[300px] w-full bg-white/5 rounded-xl overflow-hidden group p-8 border border-white/5">
        <div className="absolute inset-0 flex items-end justify-between px-8 pb-4">
          {trendData.map((count, idx) => {
            const heightPercent = (count / maxTrend) * 100 || 5;
            const isHighest = count === Math.max(...trendData) && Math.max(...trendData) > 0;

            return (
              <div key={idx} className="flex flex-col items-center gap-2 w-full">
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
