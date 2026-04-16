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
    <div className="overflow-hidden rounded-xl border border-lilac/15 bg-white shadow-sm">
      <table className="min-w-full border-collapse text-left">
        <thead className="bg-cream text-xs uppercase tracking-widest text-brand-400">
          <tr>
            <th className="px-6 py-4 font-bold">Order ID</th>
            <th className="px-6 py-4 font-bold">Customer Name</th>
            <th className="px-6 py-4 font-bold">Seller Name</th>
            <th className="px-6 py-4 font-bold">Tank Size</th>
            <th className="px-6 py-4 font-bold">Status</th>
            <th className="px-6 py-4 font-bold">Payment Type</th>
            <th className="px-6 py-4 text-center font-bold">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-lilac/15 text-sm">
          {visibleOrders.map((order) => (
            <tr key={order.id} className="group transition-colors hover:bg-cream/70">
              <td className="px-6 py-5 font-semibold text-brand-600">#{order.id}</td>
              <td className="px-6 py-5 font-medium text-brand-700">{order.customer}</td>
              <td className="px-6 py-5 text-brand-600">{order.seller}</td>
              <td className="px-6 py-5 text-brand-600">{order.tankSize}</td>
              <td className="px-6 py-5">
                <StatusBadge value={order.status} />
              </td>
              <td className="px-6 py-5 text-brand-600">{order.paymentType}</td>
              <td className="px-6 py-5 text-center">
                <button
                  type="button"
                  onClick={() => router.push(`/orders?order=${encodeURIComponent(order.id)}`)}
                  className="material-symbols-outlined text-brand-400 transition-colors hover:text-brand-600"
                >
                  more_vert
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      {visibleOrders.length === 0 ? (
        <div className="p-6 text-sm text-brand-400">No orders found for current filters.</div>
      ) : null}

      <div className="flex items-center justify-between border-t border-lilac/15 bg-cream/30 px-6 py-4">
        <p className="text-sm font-medium text-brand-400">
          Showing {orders.length === 0 ? 0 : startIndex + 1} to {Math.min(startIndex + pageSize, orders.length)} of {orders.length} orders
        </p>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => onPageChange(Math.max(1, safePage - 1))}
            disabled={safePage === 1}
            className="rounded-lg border border-lilac/30 p-2 disabled:cursor-not-allowed disabled:opacity-40"
          >
            <span className="material-symbols-outlined text-sm">chevron_left</span>
          </button>

          {pageNumbers.map((pageNumber) => (
            <button
              key={pageNumber}
              type="button"
              onClick={() => onPageChange(pageNumber)}
              className={`h-8 w-8 rounded-lg text-sm font-semibold transition-colors ${
                pageNumber === safePage ? "bg-brand-500 text-white" : "text-brand-600 hover:bg-cream"
              }`}
            >
              {pageNumber}
            </button>
          ))}

          <button
            type="button"
            onClick={() => onPageChange(Math.min(totalPages, safePage + 1))}
            disabled={safePage === totalPages}
            className="rounded-lg border border-lilac/30 p-2 disabled:cursor-not-allowed disabled:opacity-40"
          >
            <span className="material-symbols-outlined text-sm">chevron_right</span>
          </button>
        </div>
      </div>
    </div>
  );
}
