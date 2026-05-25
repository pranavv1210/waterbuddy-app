import { OrderRecord } from "../../services/types";
import { StatusBadge } from "../ui/StatusBadge";
import { useRouter } from "next/router";

interface RecentLiveOrdersProps {
  orders: OrderRecord[];
}

function getTimeAgo(timestamp: number | string | undefined): string {
  if (!timestamp) return "Just now";

  const ms =
    typeof timestamp === "string" ? new Date(timestamp).getTime() : timestamp;
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
  const router = useRouter();
  const recentOrders = orders.slice(0, 5);

  return (
    <div className="rounded-2xl border border-white/5 bg-[#0D1117]/60 p-5 shadow-lg backdrop-blur-xl">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-lg font-bold text-white">Recent Live Orders</h2>
        <button
          type="button"
          onClick={() => router.push("/orders")}
          className="text-xs font-bold text-sky-600 transition-all hover:underline"
        >
          View All
        </button>
      </div>

      <div className="space-y-3">
        {recentOrders.length > 0 ? (
          recentOrders.map((order) => (
            <div
              key={order.id}
              className="group flex items-center gap-3 rounded-xl border border-transparent p-2.5 transition-all duration-200 hover:border-white/10 hover:bg-white/5"
            >
              {/* Icon */}
              <div
                className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-[#14B8A6]/10 bg-[#0F766E]/20 text-[#14B8A6]`}
              >
                <span className="material-symbols-outlined text-lg">
                  {getStatusIcon(order.status)}
                </span>
              </div>

              {/* Order Info */}
              <div className="flex-1 min-w-0">
                <p className="truncate text-sm font-bold text-white">
                  #{order.id || "ORD-000"}
                </p>
                <p className="truncate text-[11px] font-medium text-white/60">
                  {order.customer || "Customer"} • {order.items || "Order"}
                </p>
              </div>

              {/* Status and Time */}
              <div className="text-right flex flex-col gap-1">
                <StatusBadge value={order.status} />
                <p className="text-[10px] text-white/60">
                  {getTimeAgo(order.createdAt)}
                </p>
              </div>
            </div>
          ))
        ) : (
            <div className="py-6 text-center">
            <p className="text-sm text-white/40">No recent orders</p>
          </div>
        )}
      </div>
    </div>
  );
}
