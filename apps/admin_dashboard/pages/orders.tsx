import { useState } from "react";
import { useRouter } from "next/router";

import { AppShell } from "../components/layout/AppShell";
import { OrdersTable } from "../components/tables/OrdersTable";
import { ErrorState } from "../components/ui/ErrorState";
import { LoadingState } from "../components/ui/LoadingState";
import { useOrders } from "../hooks/useOrders";

const statusTabs = ["All Orders", "Searching", "Assigned", "On the Way", "Delivered"];

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
  const customerFilter = typeof router.query.customer === "string" ? router.query.customer : "";

  const filteredOrders = orders.filter(
    (order) =>
      filterOrdersByTab(activeTab, order.status) &&
      (customerFilter.length === 0 || order.customer.toLowerCase().includes(customerFilter.toLowerCase())),
  );
  const deliveredCount = orders.filter((order) => normalizeStatus(order.status) === "delivered").length;
  const activeDeliveriesCount = orders.filter((order) => normalizeStatus(order.status) === "on the way").length;
  const completionRate = orders.length === 0 ? 0 : (deliveredCount / orders.length) * 100;
  const failedDispatchesCount = orders.filter(
    (order) => normalizeStatus(order.status) === "cancelled",
  ).length;

  const onTabChange = (tab: string) => {
    setActiveTab(tab);
    setPage(1);
  };

  const exportCsv = () => {
    const rows = [
      ["id", "customer", "seller", "status", "paymentType", "tankSize", "items", "quantity"],
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
    const csv = rows.map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(",")).join("\n");
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
      <div className="space-y-10">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex gap-3 overflow-x-auto pb-2 sm:pb-0">
            {statusTabs.map((tab) => {
              const active = tab === activeTab;
              return (
                <button
                  key={tab}
                  type="button"
                  onClick={() => onTabChange(tab)}
                  className={`whitespace-nowrap rounded-full px-6 py-2 text-sm transition-colors ${
                    active
                      ? "bg-lilac text-brand-700 font-semibold"
                      : "bg-white border border-lilac/20 text-brand-500 font-medium hover:bg-cream"
                  }`}
                >
                  {tab}
                </button>
              );
            })}
          </div>

          <div className="flex items-center gap-3">
            <button
              type="button"
              className="flex items-center gap-2 rounded-lg bg-white px-4 py-2 text-sm font-medium text-brand-500 transition-colors hover:bg-cream"
            >
              <span className="material-symbols-outlined text-sm">filter_list</span>
              More Filters
            </button>
            <button
              type="button"
              onClick={exportCsv}
              className="flex items-center gap-2 rounded-lg bg-brand-500 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-all hover:opacity-90"
            >
              <span className="material-symbols-outlined text-sm">download</span>
              Export Report
            </button>
          </div>
        </div>

        {loading ? <LoadingState /> : null}
        {error ? <ErrorState message={error} /> : null}
        {!loading && !error ? (
          <OrdersTable orders={filteredOrders} page={page} pageSize={6} onPageChange={setPage} />
        ) : null}

        {!loading && !error ? (
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
            <div className="flex h-40 flex-col justify-between rounded-xl bg-brand-500 p-6">
              <span className="material-symbols-outlined text-3xl text-lilac">local_shipping</span>
              <div>
                <h3 className="text-sm font-medium text-lilac/80">Active Deliveries</h3>
                <p className="text-3xl font-extrabold text-white">{activeDeliveriesCount}</p>
              </div>
            </div>

            <div className="flex h-40 flex-col justify-between rounded-xl bg-lilac p-6">
              <span className="material-symbols-outlined text-3xl text-brand-600">verified</span>
              <div>
                <h3 className="text-sm font-medium text-brand-600/70">Delivered Today</h3>
                <p className="text-3xl font-extrabold text-brand-700">{deliveredCount}</p>
              </div>
            </div>

            <div className="relative flex h-40 flex-col justify-between overflow-hidden rounded-xl border border-lilac/20 bg-white p-6">
              <div className="absolute -right-4 -top-4 h-24 w-24 rounded-full bg-cream opacity-60 blur-2xl"></div>
              <span className="material-symbols-outlined text-3xl text-brand-400">monitoring</span>
              <div>
                <h3 className="text-sm font-medium text-brand-400/80">Completion Rate</h3>
                <p className="text-3xl font-extrabold text-brand-700">{completionRate.toFixed(1)}%</p>
              </div>
            </div>

            <div className="flex h-40 flex-col justify-between rounded-xl border border-lilac/20 bg-white p-6">
              <span className="material-symbols-outlined text-3xl text-brand-500">assignment_late</span>
              <div>
                <h3 className="text-sm font-medium text-brand-400/80">Failed Dispatches</h3>
                <p className="text-3xl font-extrabold text-brand-600">{failedDispatchesCount}</p>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </AppShell>
  );
}
