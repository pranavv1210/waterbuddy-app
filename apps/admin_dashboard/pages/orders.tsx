import { useState } from "react";
import { useRouter } from "next/router";

import { AppShell } from "../components/layout/AppShell";
import { OrdersTable } from "../components/tables/OrdersTable";
import { ErrorState } from "../components/ui/ErrorState";
import { LoadingState } from "../components/ui/LoadingState";
import { useOrders } from "../hooks/useOrders";

const statusTabs = [
  "All Orders",
  "Searching",
  "Assigned",
  "On the Way",
  "Delivered",
];

function normalizeStatus(status: string): string {
  return status.trim().toLowerCase();
}

function filterOrdersByTab(statusTab: string, statusValue: string): boolean {
  const normalizedStatus = normalizeStatus(statusValue);
  if (statusTab === "All Orders") {
    return true;
  }
  if (statusTab === "On the Way") {
    return normalizedStatus === "on the way";
  }
  return normalizedStatus === normalizeStatus(statusTab);
}

export default function OrdersPage() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState("All Orders");
  const [page, setPage] = useState(1);
  const { orders, loading, error } = useOrders("all");
  const customerFilter =
    typeof router.query.customer === "string" ? router.query.customer : "";

  const filteredOrders = orders.filter(
    (order) =>
      filterOrdersByTab(activeTab, order.status) &&
      (customerFilter.length === 0 ||
        order.customer.toLowerCase().includes(customerFilter.toLowerCase())),
  );
  const deliveredCount = orders.filter(
    (order) => normalizeStatus(order.status) === "delivered",
  ).length;
  const activeDeliveriesCount = orders.filter(
    (order) => normalizeStatus(order.status) === "on the way",
  ).length;
  const completionRate =
    orders.length === 0 ? 0 : (deliveredCount / orders.length) * 100;
  const failedDispatchesCount = orders.filter(
    (order) => normalizeStatus(order.status) === "cancelled",
  ).length;

  const onTabChange = (tab: string) => {
    setActiveTab(tab);
    setPage(1);
  };

  const exportCsv = () => {
    const rows = [
      [
        "id",
        "customer",
        "seller",
        "status",
        "paymentType",
        "tankSize",
        "items",
        "quantity",
      ],
      ...filteredOrders.map((order) => [
        order.id,
        order.customer,
        order.seller,
        order.status,
        order.paymentType,
        order.tankSize,
        order.items ?? "",
        String(order.quantity ?? ""),
      ]),
    ];
    const csv = rows
      .map((row) =>
        row
          .map((value) => `"${String(value).replaceAll('"', '""')}"`)
          .join(","),
      )
      .join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "waterbuddy-orders.csv";
    anchor.click();
    URL.revokeObjectURL(url);
  };

  return (
    <AppShell>
      <div className="space-y-6">
        {/* Page Header */}
        <div className="flex flex-col gap-6">
          <div className="flex flex-wrap items-end justify-between gap-3">
            <div>
              <h1 className="mb-1 text-3xl font-extrabold tracking-tight text-white">
                Orders Management
              </h1>
              <p className="text-white/60 font-medium">
                Track and manage all deliveries in real-time.
              </p>
            </div>

            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={exportCsv}
                className="flex items-center gap-2 rounded-xl bg-[#14B8A6] px-6 py-2.5 text-sm font-bold text-white shadow-[0_0_20px_rgba(20,184,166,0.3)] transition-all hover:scale-[1.02] active:scale-[0.98]"
              >
                <span className="material-symbols-outlined text-lg">
                  download
                </span>
                Export Report
              </button>
            </div>
          </div>

          <div className="flex flex-wrap items-center justify-between gap-4">
            <div className="flex gap-2 overflow-x-auto pb-1.5 scrollbar-hide">
              {statusTabs.map((tab) => {
                const active = tab === activeTab;
                return (
                  <button
                    key={tab}
                    type="button"
                    onClick={() => onTabChange(tab)}
                    className={`whitespace-nowrap rounded-xl px-6 py-2 text-xs font-bold transition-all ${
                      active
                        ? "bg-[#14B8A6] text-white shadow-[0_0_15px_rgba(20,184,166,0.4)]"
                        : "bg-white/5 text-white/60 hover:bg-white/10 hover:text-white border border-white/5"
                    }`}
                  >
                    {tab}
                  </button>
                );
              })}
            </div>

            <div className="flex flex-wrap items-center gap-2.5">
              <div className="relative group w-full sm:w-auto">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-white/40 text-lg group-focus-within:text-[#14B8A6] transition-colors">
                  search
                </span>
                <input
                  type="text"
                  placeholder="Filter by customer..."
                  className="w-full rounded-xl border border-sky-100 bg-white py-2 pl-10 pr-4 text-xs font-medium text-slate-950 outline-none transition-all placeholder:text-slate-400 focus:border-sky-300 focus:ring-2 focus:ring-sky-100 sm:w-64"
                  onChange={(e) => {
                    const val = e.target.value;
                    router.push(
                      { query: { ...router.query, customer: val } },
                      undefined,
                      { shallow: true },
                    );
                  }}
                />
              </div>
            </div>
          </div>
        </div>

        {loading ? <LoadingState /> : null}
        {error ? <ErrorState message={error} /> : null}

        {!loading && !error ? (
          <div className="space-y-6">
            <OrdersTable
              orders={filteredOrders}
              page={page}
              pageSize={8}
              onPageChange={setPage}
            />

            {/* Quick Stats Grid */}
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
              <div className="group flex h-32 flex-col justify-between rounded-2xl border border-[#14B8A6]/20 bg-[#14B8A6]/10 p-5 shadow-lg transition-all hover:bg-[#14B8A6]/15">
                <div className="bg-[#14B8A6]/20 w-12 h-12 rounded-xl flex items-center justify-center text-[#14B8A6]">
                  <span
                    className="material-symbols-outlined text-2xl"
                    style={{ fontVariationSettings: "'FILL' 1" }}
                  >
                    local_shipping
                  </span>
                </div>
                <div>
                  <h3 className="text-xs font-bold text-[#14B8A6] uppercase tracking-widest mb-1">
                    Active Deliveries
                  </h3>
                  <p className="text-3xl font-extrabold text-white">
                    {activeDeliveriesCount}
                  </p>
                </div>
              </div>

              <div className="group flex h-32 flex-col justify-between rounded-2xl border border-blue-500/20 bg-blue-500/10 p-5 shadow-lg transition-all hover:bg-blue-500/15">
                <div className="bg-blue-500/20 w-12 h-12 rounded-xl flex items-center justify-center text-blue-400">
                  <span
                    className="material-symbols-outlined text-2xl"
                    style={{ fontVariationSettings: "'FILL' 1" }}
                  >
                    verified
                  </span>
                </div>
                <div>
                  <h3 className="text-xs font-bold text-blue-400 uppercase tracking-widest mb-1">
                    Delivered Today
                  </h3>
                  <p className="text-3xl font-extrabold text-white">
                    {deliveredCount}
                  </p>
                </div>
              </div>

              <div className="group flex h-32 flex-col justify-between rounded-2xl border border-purple-500/20 bg-purple-500/10 p-5 shadow-lg transition-all hover:bg-purple-500/15">
                <div className="bg-purple-500/20 w-12 h-12 rounded-xl flex items-center justify-center text-purple-400">
                  <span
                    className="material-symbols-outlined text-2xl"
                    style={{ fontVariationSettings: "'FILL' 1" }}
                  >
                    monitoring
                  </span>
                </div>
                <div>
                  <h3 className="text-xs font-bold text-purple-400 uppercase tracking-widest mb-1">
                    Completion Rate
                  </h3>
                  <p className="text-3xl font-extrabold text-white">
                    {completionRate.toFixed(1)}%
                  </p>
                </div>
              </div>

              <div className="group flex h-32 flex-col justify-between rounded-2xl border border-red-500/20 bg-red-500/10 p-5 shadow-lg transition-all hover:bg-red-500/15">
                <div className="bg-red-500/20 w-12 h-12 rounded-xl flex items-center justify-center text-red-400">
                  <span
                    className="material-symbols-outlined text-2xl"
                    style={{ fontVariationSettings: "'FILL' 1" }}
                  >
                    assignment_late
                  </span>
                </div>
                <div>
                  <h3 className="text-xs font-bold text-red-400 uppercase tracking-widest mb-1">
                    Failed Dispatches
                  </h3>
                  <p className="text-3xl font-extrabold text-white">
                    {failedDispatchesCount}
                  </p>
                </div>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </AppShell>
  );
}
