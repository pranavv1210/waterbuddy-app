import { useRouter } from "next/router";

import { OrderRecord } from "../../services/types";
import { StatusBadge } from "../ui/StatusBadge";

interface OrdersTableProps {
  orders: OrderRecord[];
  page: number;
  pageSize: number;
  onPageChange: (page: number) => void;
}

export function OrdersTable({ orders, page, pageSize, onPageChange }: OrdersTableProps) {
  const router = useRouter();
  const totalPages = Math.max(1, Math.ceil(orders.length / pageSize));
  const safePage = Math.min(page, totalPages);
  const startIndex = (safePage - 1) * pageSize;
  const visibleOrders = orders.slice(startIndex, startIndex + pageSize);
  const pageNumbers = Array.from({ length: Math.min(totalPages, 5) }, (_, index) => index + 1);

  return (
    <div className="overflow-hidden rounded-2xl border border-white/5 bg-[#0D1117]/60 shadow-xl backdrop-blur-xl">
      <div className="overflow-x-auto">
        <table className="min-w-full border-collapse text-left">
          <thead className="bg-white/5 text-[10px] uppercase tracking-[0.2em] text-white/40">
            <tr>
              <th className="px-5 py-3.5 font-bold">Order ID</th>
              <th className="px-5 py-3.5 font-bold">Customer</th>
              <th className="px-5 py-3.5 font-bold">Seller</th>
              <th className="px-5 py-3.5 font-bold">Tank Size</th>
              <th className="px-5 py-3.5 font-bold">Status</th>
              <th className="px-5 py-3.5 font-bold">Payment</th>
              <th className="px-5 py-3.5 text-center font-bold">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5 text-sm">
            {visibleOrders.map((order) => (
              <tr key={order.id} className="group transition-colors hover:bg-white/5">
                <td className="px-5 py-4 font-bold text-[#14B8A6]">#{order.id}</td>
                <td className="px-5 py-4 font-semibold text-white/90">{order.customer}</td>
                <td className="px-5 py-4 text-white/60">{order.seller}</td>
                <td className="px-5 py-4 text-white/60">{order.tankSize}</td>
                <td className="px-5 py-4">
                  <StatusBadge value={order.status} />
                </td>
                <td className="px-5 py-4 text-[10px] font-bold uppercase tracking-wider text-white/60">{order.paymentType}</td>
                <td className="px-5 py-4 text-center">
                  <button
                    type="button"
                    onClick={() => router.push(`/orders?order=${encodeURIComponent(order.id)}`)}
                    className="flex items-center justify-center h-8 w-8 rounded-lg bg-white/5 text-white/40 transition-colors hover:bg-white/10 hover:text-white mx-auto"
                  >
                    <span className="material-symbols-outlined text-lg">more_vert</span>
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {visibleOrders.length === 0 ? (
        <div className="p-8 text-center text-sm text-white/20">No orders found matching the criteria.</div>
      ) : null}

      <div className="flex items-center justify-between border-t border-white/5 bg-white/[0.02] px-5 py-3.5">
        <p className="text-xs font-medium text-white/40">
          Showing <span className="text-white/80">{orders.length === 0 ? 0 : startIndex + 1}</span> to <span className="text-white/80">{Math.min(startIndex + pageSize, orders.length)}</span> of <span className="text-white/80">{orders.length}</span> orders
        </p>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => onPageChange(Math.max(1, safePage - 1))}
            disabled={safePage === 1}
            className="flex h-8 w-8 items-center justify-center rounded-lg border border-white/5 bg-white/5 text-white/40 transition-colors hover:bg-white/10 hover:text-white disabled:cursor-not-allowed disabled:opacity-20"
          >
            <span className="material-symbols-outlined text-sm">chevron_left</span>
          </button>

          {pageNumbers.map((pageNumber) => (
            <button
              key={pageNumber}
              type="button"
              onClick={() => onPageChange(pageNumber)}
              className={`h-8 w-8 rounded-lg text-xs font-bold transition-all ${
                pageNumber === safePage 
                  ? "bg-[#14B8A6] text-white shadow-[0_0_15px_rgba(20,184,166,0.4)]" 
                  : "bg-white/5 text-white/60 hover:bg-white/10 hover:text-white"
              }`}
            >
              {pageNumber}
            </button>
          ))}

          <button
            type="button"
            onClick={() => onPageChange(Math.min(totalPages, safePage + 1))}
            disabled={safePage === totalPages}
            className="flex h-8 w-8 items-center justify-center rounded-lg border border-white/5 bg-white/5 text-white/40 transition-colors hover:bg-white/10 hover:text-white disabled:cursor-not-allowed disabled:opacity-20"
          >
            <span className="material-symbols-outlined text-sm">chevron_right</span>
          </button>
        </div>
      </div>
    </div>
  );
}
