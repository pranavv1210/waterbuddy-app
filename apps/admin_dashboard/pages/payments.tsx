import { AppShell } from "../components/layout/AppShell";
import { ErrorState } from "../components/ui/ErrorState";
import { LoadingState } from "../components/ui/LoadingState";
import { usePayments } from "../hooks/usePayments";
import { useState } from "react";
import { useRouter } from "next/router";

function formatCurrency(value: number): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 2,
  }).format(value);
}

function formatDate(value: number | string | undefined): string {
  if (!value) {
    return "-";
  }
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "2-digit",
    year: "numeric",
  }).format(new Date(value));
}

function payoutInitials(name: string): string {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part.charAt(0).toUpperCase())
    .join("");
}

export default function PaymentsPage() {
  const router = useRouter();
  const { dashboard, loading, error } = usePayments();
  const [visiblePayoutCount, setVisiblePayoutCount] = useState(5);

  const { summary, weeklyRevenue, recentPayouts } = dashboard;
  const commission = summary.totalRevenue * 0.15;
  const netRevenue = summary.totalRevenue - commission;
  const pendingPayoutAmount = recentPayouts
    .filter((item) => item.status.toLowerCase() === "pending")
    .reduce((sum, item) => sum + item.amount, 0);
  const completedPayoutCount = recentPayouts.filter(
    (item) => item.status.toLowerCase() === "completed",
  ).length;
  const pendingPayoutCount = recentPayouts.filter(
    (item) => item.status.toLowerCase() === "pending",
  ).length;
  const previousEstimate = summary.totalRevenue * 0.88;
  const growthPercentage = previousEstimate > 0 ? ((summary.totalRevenue - previousEstimate) / previousEstimate) * 100 : 0;

  const maxWeeklyGross = Math.max(...weeklyRevenue.map((item) => item.gross), 1);
  const onlineRatio = summary.totalRevenue > 0 ? (summary.onlineRevenue / summary.totalRevenue) * 100 : 0;
  const commissionTargetRatio = commission > 0 ? Math.min(100, (commission / 30000) * 100) : 0;
  const visiblePayouts = recentPayouts.slice(0, visiblePayoutCount);

  const exportCsv = () => {
    const rows = [
      ["id", "sellerName", "sellerCode", "transactionId", "date", "amount", "status"],
      ...recentPayouts.map((payout) => [
        payout.id,
        payout.sellerName,
        payout.sellerCode,
        payout.transactionId,
        String(payout.date ?? ""),
        String(payout.amount),
        payout.status,
      ]),
    ];
    const csv = rows.map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "waterbuddy-payments.csv";
    anchor.click();
    URL.revokeObjectURL(url);
  };

  return (
    <AppShell>
      <div className="space-y-8">
        <div className="flex items-end justify-between">
          <div>
            <h1 className="text-4xl font-extrabold tracking-tight text-brand-600">Payments &amp; Revenue</h1>
            <p className="mt-1 text-brand-400">Real-time financial performance and seller settlements.</p>
          </div>
          <div className="flex gap-3">
            <button
              type="button"
              className="flex items-center gap-2 rounded-lg border border-lilac/20 bg-white px-4 py-2 text-sm font-semibold text-brand-600 transition-colors hover:bg-cream"
            >
              <span className="material-symbols-outlined text-[20px]">calendar_today</span>
              Last 30 Days
            </button>
            <button
              type="button"
              onClick={exportCsv}
              className="flex items-center gap-2 rounded-lg bg-brand-500 px-4 py-2 text-sm font-semibold text-white shadow-md transition-opacity hover:opacity-90"
            >
              <span className="material-symbols-outlined text-[20px]">download</span>
              Export Report
            </button>
          </div>
        </div>

        {loading ? <LoadingState /> : null}
        {error ? <ErrorState message={error} /> : null}

        {!loading && !error ? (
          <>
            <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
              <div className="relative overflow-hidden rounded-xl bg-white p-6 md:col-span-2">
                <div className="relative z-10 flex h-full flex-col justify-between">
                  <div>
                    <div className="flex items-start justify-between">
                      <span className="text-xs font-bold uppercase tracking-widest text-brand-400">Total Revenue</span>
                      <span className="rounded bg-lilac/35 px-2 py-1 text-xs font-bold text-brand-700">
                        {growthPercentage >= 0 ? "+" : ""}
                        {growthPercentage.toFixed(1)}%
                      </span>
                    </div>
                    <div className="brand-font mt-4 text-5xl font-black text-brand-600">
                      {formatCurrency(summary.totalRevenue)}
                    </div>
                  </div>
                  <div className="mt-8 flex items-center gap-2 text-sm text-brand-400">
                    <span className="material-symbols-outlined text-lilac">trending_up</span>
                    <span>{formatCurrency(summary.totalRevenue - previousEstimate)} more than previous period</span>
                  </div>
                </div>
                <div className="absolute -bottom-8 -right-8 opacity-10">
                  <span className="material-symbols-outlined text-[180px] text-brand-600">payments</span>
                </div>
              </div>

              <div className="rounded-xl bg-white p-6">
                <span className="text-xs font-bold uppercase tracking-widest text-brand-400">Commission (15%)</span>
                <div className="brand-font mt-3 text-3xl font-bold text-brand-500">{formatCurrency(commission)}</div>
                <div className="mt-6 h-2 w-full overflow-hidden rounded-full bg-cream">
                  <div className="h-full rounded-full bg-lilac" style={{ width: `${commissionTargetRatio}%` }}></div>
                </div>
                <div className="mt-2 flex justify-between text-[10px] text-brand-400">
                  <span>MONTHLY TARGET</span>
                  <span>{commissionTargetRatio.toFixed(0)}% REACHED</span>
                </div>
              </div>

              <div className="rounded-xl bg-white p-6">
                <span className="text-xs font-bold uppercase tracking-widest text-brand-400">Pending Payouts</span>
                <div className="brand-font mt-3 text-3xl font-bold text-brand-600">{formatCurrency(pendingPayoutAmount)}</div>
                <div className="mt-4 flex flex-col gap-2">
                  <div className="flex items-center gap-2 text-xs">
                    <span className="h-2 w-2 rounded-full bg-brand-500"></span>
                    <span className="text-brand-400">{completedPayoutCount} Sellers completed</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs">
                    <span className="h-2 w-2 rounded-full bg-lilac"></span>
                    <span className="text-brand-400">{pendingPayoutCount} Sellers pending</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
              <div className="flex flex-col gap-8 rounded-xl bg-white p-8 lg:col-span-2">
                <div className="flex items-center justify-between">
                  <h3 className="brand-font text-lg font-bold text-brand-600">Weekly Revenue Breakdown</h3>
                  <div className="flex items-center gap-4 text-xs font-semibold">
                    <div className="flex items-center gap-1.5">
                      <div className="h-3 w-3 rounded-sm bg-brand-500"></div>
                      <span>GROSS</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <div className="h-3 w-3 rounded-sm bg-lilac"></div>
                      <span>NET</span>
                    </div>
                  </div>
                </div>

                <div className="flex min-h-[300px] flex-1 items-end justify-between gap-4 px-4">
                  {weeklyRevenue.map((week) => {
                    const grossHeight = Math.max(16, (week.gross / maxWeeklyGross) * 220);
                    const netHeight = Math.max(10, (week.net / maxWeeklyGross) * 200);

                    return (
                      <div key={week.label} className="group flex flex-1 flex-col items-center gap-2">
                        <div className="flex w-full max-w-[42px] flex-col items-center gap-1">
                          <div
                            className="relative w-full rounded-t-lg bg-brand-500/20 transition-all group-hover:bg-brand-500/30"
                            style={{ height: `${grossHeight}px` }}
                          >
                            <div
                              className="absolute bottom-0 w-full rounded-t-lg bg-brand-500"
                              style={{ height: `${Math.max(8, grossHeight * 0.78)}px` }}
                            ></div>
                          </div>
                          <div
                            className="relative w-full rounded-b-lg bg-lilac/40 transition-all group-hover:bg-lilac/60"
                            style={{ height: `${netHeight}px` }}
                          >
                            <div
                              className="absolute top-0 w-full rounded-b-lg bg-lilac"
                              style={{ height: `${Math.max(8, netHeight * 0.72)}px` }}
                            ></div>
                          </div>
                        </div>
                        <span className="text-[10px] font-bold text-brand-400">{week.label}</span>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="flex flex-col justify-between rounded-xl bg-brand-500 p-8 text-white">
                <div>
                  <h3 className="brand-font text-lg font-bold">Payment Methods</h3>
                  <p className="mt-1 text-xs italic text-lilac">Breakdown by transaction volume</p>
                </div>

                <div className="relative flex justify-center py-10">
                  <div
                    className="flex h-40 w-40 items-center justify-center rounded-full border-[16px] border-lilac border-r-transparent border-b-transparent"
                    style={{ transform: "rotate(45deg)" }}
                  >
                    <div style={{ transform: "rotate(-45deg)" }} className="text-center">
                      <div className="text-2xl font-black">{onlineRatio.toFixed(0)}%</div>
                      <div className="text-[10px] font-bold uppercase tracking-tighter text-lilac">Digital</div>
                    </div>
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <div className="h-3 w-3 rounded-full bg-lilac"></div>
                      <span>Online Payments</span>
                    </div>
                    <span className="font-bold">{formatCurrency(summary.onlineRevenue)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <div className="h-3 w-3 rounded-full bg-brand-700"></div>
                      <span>Cash on Delivery</span>
                    </div>
                    <span className="font-bold">{formatCurrency(summary.codRevenue)}</span>
                  </div>
                  <div className="text-xs text-lilac">Net after commission: {formatCurrency(netRevenue)}</div>
                </div>
              </div>
            </div>

            <div className="overflow-hidden rounded-xl bg-white shadow-sm">
              <div className="flex items-center justify-between border-b border-cream p-6">
                <h3 className="brand-font text-xl font-bold text-brand-600">Recent Seller Payouts</h3>
                <button
                  type="button"
                  onClick={() => router.push("/payments?history=all")}
                  className="flex items-center gap-1 text-sm font-bold text-brand-500 hover:underline"
                >
                  View All History <span className="material-symbols-outlined text-sm">arrow_forward</span>
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full border-collapse text-left">
                  <thead>
                    <tr className="bg-cream">
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-widest text-brand-400">Seller Name</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-widest text-brand-400">Transaction ID</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-widest text-brand-400">Date</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-widest text-brand-400">Amount</th>
                      <th className="px-6 py-4 text-xs font-bold uppercase tracking-widest text-brand-400">Status</th>
                      <th className="px-6 py-4 text-right text-xs font-bold uppercase tracking-widest text-brand-400">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-cream">
                    {visiblePayouts.map((payout) => (
                      <tr key={payout.id} className="group cursor-pointer transition-colors hover:bg-cream/60">
                        <td className="px-6 py-5">
                          <div className="flex items-center gap-3">
                            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-500 text-xs font-bold text-white">
                              {payoutInitials(payout.sellerName)}
                            </div>
                            <div>
                              <div className="font-bold text-brand-600">{payout.sellerName}</div>
                              <div className="text-[10px] uppercase text-brand-400">ID: {payout.sellerCode}</div>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-5 font-mono text-xs text-brand-400">#{payout.transactionId}</td>
                        <td className="px-6 py-5 text-sm text-brand-400">{formatDate(payout.date)}</td>
                        <td className="px-6 py-5 text-sm font-bold text-brand-600">{formatCurrency(payout.amount)}</td>
                        <td className="px-6 py-5">
                          <span
                            className={`inline-flex rounded-full px-3 py-1 text-xs font-bold ${
                              payout.status.toLowerCase() === "completed"
                                ? "bg-lilac/35 text-brand-700"
                                : "bg-cream text-brand-600"
                            }`}
                          >
                            {payout.status}
                          </span>
                        </td>
                        <td className="px-6 py-5 text-right">
                          <button
                            type="button"
                            onClick={() => router.push(`/payments?transaction=${encodeURIComponent(payout.transactionId)}`)}
                            className="rounded-full p-2 transition-colors hover:bg-cream"
                          >
                            <span className="material-symbols-outlined text-brand-400">more_vert</span>
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="bg-cream/30 p-4 text-center">
                <button
                  type="button"
                  onClick={() => setVisiblePayoutCount((count) => Math.min(recentPayouts.length, count + 5))}
                  className="text-xs font-bold text-brand-400 transition-colors hover:text-brand-600"
                >
                  Load More Transactions
                </button>
              </div>
            </div>
          </>
        ) : null}
      </div>
    </AppShell>
  );
}
