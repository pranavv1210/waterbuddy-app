import { OrderRecord } from "../../services/types";
import { StatusBadge } from "../ui/StatusBadge";

interface RecentLiveOrdersProps {
  orders: OrderRecord[];
}

function getTimeAgo(timestamp: number | string | undefined): string {
  if (!timestamp) return "Just now";

  const ms = typeof timestamp === "string" ? new Date(timestamp).getTime() : timestamp;
  const now = new Date().getTime();
  const diffMs = now - ms;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);

  if (diffMins < 1) return "Just now";
  if (diffMins < 60) return `${diffMins} min${diffMins > 1 ? "s" : ""} ago`;
  if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? "s" : ""} ago`;
  return "Recently";
}

function getStatusIcon(status: string): string {
  switch (status) {
    case "in_progress":
      return "local_shipping";
    case "assigned":
      return "person";
    case "pending":
      return "schedule";
    case "delivered":
      return "check_circle";
    case "cancelled":
      return "cancel";
    default:
      return "inventory_2";
  }
}

function getIconColor(status: string): string {
  switch (status) {
    case "in_progress":
      return "bg-lilac text-brand-600";
    case "assigned":
      return "bg-brand-100 text-brand-600";
    case "pending":
      return "bg-brand-100 text-brand-600";
    case "delivered":
      return "bg-green-100 text-green-700";
    case "cancelled":
      return "bg-red-100 text-red-700";
    default:
      return "bg-brand-100 text-brand-600";
  }
}

export function RecentLiveOrders({ orders }: RecentLiveOrdersProps) {
  const recentOrders = orders.slice(0, 5);

  return (
    <div className="bg-white rounded-2xl p-8 shadow-sm border border-lilac/10">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-bold text-brand-600">Recent Live Orders</h2>
        <button className="text-lilac text-xs font-bold hover:underline transition-all">View All</button>
      </div>

      <div className="space-y-4">
        {recentOrders.length > 0 ? (
          recentOrders.map((order) => (
            <div
              key={order.id}
              className="group flex items-center gap-4 p-3 rounded-xl transition-all duration-200 hover:bg-cream border border-transparent hover:border-lilac/20"
            >
              {/* Icon */}
              <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${getIconColor(order.status)}`}>
                <span className="material-symbols-outlined text-lg">{getStatusIcon(order.status)}</span>
              </div>

              {/* Order Info */}
              <div className="flex-1 min-w-0">
                <p className="text-sm font-bold text-brand-600 truncate">#{order.id || "ORD-000"}</p>
                <p className="text-[11px] text-brand-400 font-medium truncate">
                  {order.customer || "Customer"} • {order.items || "Order"}
                </p>
              </div>

              {/* Status and Time */}
              <div className="text-right flex flex-col gap-1">
                <StatusBadge value={order.status} />
                <p className="text-[10px] text-brand-400">{getTimeAgo(order.createdAt)}</p>
              </div>
            </div>
          ))
        ) : (
          <div className="text-center py-8">
            <p className="text-sm text-brand-400">No recent orders</p>
          </div>
        )}
      </div>
    </div>
  );
}
