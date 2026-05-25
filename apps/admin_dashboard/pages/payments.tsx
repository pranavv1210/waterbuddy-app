import { AppShell } from "../components/layout/AppShell";
import { ErrorState } from "../components/ui/ErrorState";
import { LoadingState } from "../components/ui/LoadingState";
import { usePayments } from "../hooks/usePayments";
import { useState } from "react";
import { useRouter } from "next/router";
import { StatusBadge } from "../components/ui/StatusBadge";

function formatCurrency(value: number): string {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
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
  const growthPercentage =
    previousEstimate > 0
      ? ((summary.totalRevenue - previousEstimate) / previousEstimate) * 100
      : 0;

  const maxWeeklyGross = Math.max(
    ...weeklyRevenue.map((item) => item.gross),
    1,
  );
  const onlineRatio =
    summary.totalRevenue > 0
      ? (summary.onlineRevenue / summary.totalRevenue) * 100
      : 0;
  const commissionTargetRatio =
    commission > 0 ? Math.min(100, (commission / 30000) * 100) : 0;
  const visiblePayouts = recentPayouts.slice(0, visiblePayoutCount);

  const exportCsv = () => {
    const rows = [
      [
        "id",
        "sellerName",
        "sellerCode",
        "transactionId",
        "date",
        "amount",
        "status",
      ],
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
    anchor.download = "waterbuddy-payments.csv";
    anchor.click();
    URL.revokeObjectURL(url);
  };

  return (
    <AppShell>
      <div className="space-y-10">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <nav className="mb-2 flex gap-2 text-[10px] font-bold uppercase tracking-[0.2em] text-[#14B8A6]">
              <span>Financials</span>
              <span className="text-white/20">/</span>
              <span className="text-white/60">Revenue & Settlements</span>
            </nav>
            <h1 className="text-4xl font-extrabold tracking-tight text-white">
              Treasury Management
            </h1>
            <p className="mt-1 text-white/40 font-medium">
              Real-time financial performance and seller settlements.
            </p>
          </div>
          <div className="flex flex-wrap gap-3">
            <button
              type="button"
              onClick={exportCsv}
              className="flex items-center gap-2 rounded-xl bg-[#14B8A6] px-6 py-2.5 text-xs font-black text-white shadow-[0_0_20px_rgba(20,184,166,0.3)] transition-all hover:scale-[1.02] active:scale-[0.98] uppercase tracking-widest"
            >
              <span className="material-symbols-outlined text-[20px]">
                download
              </span>
              Export Report
            </button>
          </div>
        </div>

        {loading ? <LoadingState /> : null}
        {error ? <ErrorState message={error} /> : null}

        {!loading && !error ? (
          <>
            <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
              <div className="relative group overflow-hidden rounded-3xl bg-[#0D1117]/60 border border-white/5 p-8 md:col-span-2 backdrop-blur-xl shadow-xl">
                <div className="relative z-10 flex h-full flex-col justify-between">
                  <div>
                    <div className="flex items-start justify-between">
                      <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#14B8A6]">
                        Total Revenue
                      </span>
                      <span className="rounded-lg bg-emerald-500/10 px-3 py-1 text-xs font-black text-emerald-400 border border-emerald-500/20">
                        {growthPercentage >= 0 ? "+" : ""}
                        {growthPercentage.toFixed(1)}%
                      </span>
                    </div>
                    <div className="mt-6 text-5xl font-black text-white tracking-tighter">
                      {formatCurrency(summary.totalRevenue)}
                    </div>
                  </div>
                  <div className="mt-8 flex items-center gap-2 text-xs font-bold text-white/40 uppercase tracking-wider">
                    <span className="material-symbols-outlined text-[#14B8A6] text-lg">
                      trending_up
                    </span>
                    <span>
                      ₹{Math.round(summary.totalRevenue - previousEstimate)}{" "}
                      growth vs last period
                    </span>
                  </div>
                </div>
                <div className="absolute -bottom-12 -right-12 opacity-[0.03] group-hover:opacity-10 transition-opacity duration-1000">
                  <span
                    className="material-symbols-outlined text-[240px]"
                    style={{ fontVariationSettings: "'FILL' 1" }}
                  >
                    payments
                  </span>
                </div>
              </div>

              <div className="rounded-3xl bg-white/5 border border-white/5 p-8 backdrop-blur-xl transition-all hover:bg-white/[0.07]">
                <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#14B8A6]">
                  Platform Fee (15%)
                </span>
                <div className="mt-4 text-3xl font-black text-white tracking-tighter">
                  {formatCurrency(commission)}
                </div>
                <div className="mt-8 h-2 w-full overflow-hidden rounded-full bg-white/5 border border-white/5">
                  <div
                    className="h-full rounded-full bg-[#14B8A6] shadow-[0_0_15px_rgba(20,184,166,0.5)]"
                    style={{ width: `${commissionTargetRatio}%` }}
                  ></div>
                </div>
                <div className="mt-3 flex justify-between text-[9px] font-black uppercase tracking-[0.1em] text-white/20">
                  <span>Target Range</span>
                  <span>{commissionTargetRatio.toFixed(0)}% Achieved</span>
                </div>
              </div>

              <div className="rounded-3xl bg-white/5 border border-white/5 p-8 backdrop-blur-xl transition-all hover:bg-white/[0.07]">
                <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-amber-400">
                  Pending Settlements
                </span>
                <div className="mt-4 text-3xl font-black text-white tracking-tighter">
                  {formatCurrency(pendingPayoutAmount)}
                </div>
                <div className="mt-8 flex flex-col gap-3">
                  <div className="flex items-center gap-3">
                    <div className="h-2 w-2 rounded-full bg-[#14B8A6]"></div>
                    <span className="text-[10px] font-bold uppercase tracking-wider text-white/40">
                      {completedPayoutCount} Finalized
                    </span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="h-2 w-2 rounded-full bg-amber-500"></div>
                    <span className="text-[10px] font-bold uppercase tracking-wider text-white/40">
                      {pendingPayoutCount} Processing
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
              <div className="flex flex-col gap-8 rounded-3xl bg-[#0D1117]/60 border border-white/5 p-8 lg:col-span-2 backdrop-blur-xl shadow-xl">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-sm font-black uppercase tracking-widest text-white">
                      Revenue Dynamics
                    </h3>
                    <p className="text-[10px] font-bold text-white/20 mt-1 uppercase tracking-widest">
                      Performance Heatmap
                    </p>
                  </div>
                  <div className="flex items-center gap-4 text-[9px] font-black uppercase tracking-[0.2em]">
                    <div className="flex items-center gap-2">
                      <div className="h-2 w-2 rounded-full bg-[#14B8A6]"></div>
                      <span className="text-white/60">Gross Volume</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="h-2 w-2 rounded-full bg-blue-500"></div>
                      <span className="text-white/60">Net Yield</span>
                    </div>
                  </div>
                </div>

                <div className="flex min-h-[300px] flex-1 items-end justify-between gap-4 px-4 pb-4">
                  {weeklyRevenue.map((week) => {
                    const grossHeight = Math.max(
                      16,
                      (week.gross / maxWeeklyGross) * 220,
                    );
                    const netHeight = Math.max(
                      10,
                      (week.net / maxWeeklyGross) * 200,
                    );

                    return (
                      <div
                        key={week.label}
                        className="group flex flex-1 flex-col items-center gap-3"
                      >
                        <div className="flex w-full max-w-[42px] flex-col items-center gap-1.5 h-[240px] justify-end">
                          <div
                            className="relative w-full rounded-xl bg-[#14B8A6]/10 transition-all group-hover:bg-[#14B8A6]/20 border border-[#14B8A6]/10"
                            style={{ height: `${grossHeight}px` }}
                          >
                            <div
                              className="absolute bottom-0 w-full rounded-xl bg-[#14B8A6] shadow-[0_0_15px_rgba(20,184,166,0.3)] transition-all group-hover:scale-y-105 origin-bottom"
                              style={{
                                height: `${Math.max(8, grossHeight * 0.78)}px`,
                              }}
                            ></div>
                          </div>
                          <div
                            className="relative w-full rounded-xl bg-blue-500/10 transition-all group-hover:bg-blue-500/20 border border-blue-500/10"
                            style={{ height: `${netHeight}px` }}
                          >
                            <div
                              className="absolute top-0 w-full rounded-xl bg-blue-500 transition-all group-hover:scale-y-105 origin-top"
                              style={{
                                height: `${Math.max(8, netHeight * 0.72)}px`,
                              }}
                            ></div>
                          </div>
                        </div>
                        <span className="text-[10px] font-black uppercase tracking-widest text-white/20 group-hover:text-white/60 transition-colors">
                          {week.label}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="flex flex-col justify-between rounded-3xl bg-[#14B8A6] p-8 text-white shadow-[0_0_30px_rgba(20,184,166,0.2)]">
                <div>
                  <div className="bg-white/20 w-12 h-12 rounded-2xl flex items-center justify-center mb-6">
                    <span className="material-symbols-outlined text-2xl">
                      insights
                    </span>
                  </div>
                  <h3 className="text-xl font-extrabold tracking-tight">
                    Payment Liquidity
                  </h3>
                  <p className="mt-1 text-xs font-bold text-white/60 uppercase tracking-widest">
                    Transaction Channel Split
                  </p>
                </div>

                <div className="relative flex justify-center py-10">
                  <div className="absolute inset-0 flex items-center justify-center">
                    <div className="text-center">
                      <div className="text-4xl font-black tracking-tighter">
                        {onlineRatio.toFixed(0)}%
                      </div>
                      <div className="text-[10px] font-black uppercase tracking-[0.2em] text-white/40">
                        Digital
                      </div>
                    </div>
                  </div>
                  <svg className="w-48 h-48 transform -rotate-90">
                    <circle
                      cx="96"
                      cy="96"
                      r="80"
                      stroke="rgba(255,255,255,0.1)"
                      strokeWidth="16"
                      fill="transparent"
                    />
                    <circle
                      cx="96"
                      cy="96"
                      r="80"
                      stroke="white"
                      strokeWidth="16"
                      fill="transparent"
                      strokeDasharray={502.4}
                      strokeDashoffset={502.4 * (1 - onlineRatio / 100)}
                      strokeLinecap="round"
                      className="transition-all duration-1000 ease-out"
                    />
                  </svg>
                </div>

                <div className="space-y-4 pt-4 border-t border-white/10">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="h-2 w-2 rounded-full bg-white"></div>
                      <span className="text-[10px] font-bold uppercase tracking-wider">
                        Digital Assets
                      </span>
                    </div>
                    <span className="text-sm font-black">
                      {formatCurrency(summary.onlineRevenue)}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="h-2 w-2 rounded-full bg-white/30"></div>
                      <span className="text-[10px] font-bold uppercase tracking-wider">
                        Physical Cash
                      </span>
                    </div>
                    <span className="text-sm font-black">
                      {formatCurrency(summary.codRevenue)}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="overflow-hidden rounded-3xl border border-white/5 bg-[#0D1117]/60 shadow-xl backdrop-blur-xl">
              <div className="flex items-center justify-between border-b border-white/5 p-8">
                <div>
                  <h3 className="text-lg font-black tracking-tight text-white">
                    Settlement History
                  </h3>
                  <p className="text-[10px] font-bold text-white/20 mt-1 uppercase tracking-[0.2em]">
                    Partner Disbursement Logs
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => router.push("/payments?history=all")}
                  className="flex items-center gap-2 rounded-xl bg-white/5 px-4 py-2 text-[10px] font-black uppercase tracking-widest text-white/60 transition-all hover:bg-white/10 hover:text-white"
                >
                  Full Archive{" "}
                  <span className="material-symbols-outlined text-sm">
                    arrow_forward
                  </span>
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full border-collapse text-left">
                  <thead className="bg-white/5 text-[10px] uppercase tracking-[0.2em] text-white/40">
                    <tr>
                      <th className="px-8 py-5 font-bold">Counterparty</th>
                      <th className="px-6 py-5 font-bold">Transmission ID</th>
                      <th className="px-6 py-5 font-bold">Execution Date</th>
                      <th className="px-6 py-5 font-bold text-right">Volume</th>
                      <th className="px-6 py-5 font-bold">Status</th>
                      <th className="px-8 py-5 text-right font-bold">
                        Registry
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5 text-sm">
                    {visiblePayouts.map((payout) => (
                      <tr
                        key={payout.id}
                        className="group transition-colors hover:bg-white/5"
                      >
                        <td className="px-8 py-6">
                          <div className="flex items-center gap-4">
                            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#14B8A6]/20 text-xs font-black text-[#14B8A6] border border-[#14B8A6]/10">
                              {payoutInitials(payout.sellerName)}
                            </div>
                            <div>
                              <div className="font-bold text-white/90">
                                {payout.sellerName}
                              </div>
                              <div className="text-[10px] font-bold text-white/20 uppercase">
                                Network ID: {payout.sellerCode}
                              </div>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-6 font-mono text-[10px] text-white/40 uppercase tracking-tighter">
                          #{payout.transactionId}
                        </td>
                        <td className="px-6 py-6 text-xs font-bold text-white/60 uppercase tracking-wider">
                          {formatDate(payout.date)}
                        </td>
                        <td className="px-6 py-6 text-base font-black text-white text-right tracking-tighter">
                          {formatCurrency(payout.amount)}
                        </td>
                        <td className="px-6 py-6">
                          <StatusBadge value={payout.status} />
                        </td>
                        <td className="px-8 py-6 text-right">
                          <button
                            type="button"
                            onClick={() =>
                              router.push(
                                `/payments?transaction=${encodeURIComponent(payout.transactionId)}`,
                              )
                            }
                            className="flex items-center justify-center h-8 w-8 rounded-lg bg-white/5 text-white/40 transition-colors hover:bg-white/10 hover:text-white ml-auto"
                          >
                            <span className="material-symbols-outlined text-lg">
                              more_vert
                            </span>
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="bg-white/[0.02] border-t border-white/5 p-6 text-center">
                <button
                  type="button"
                  onClick={() =>
                    setVisiblePayoutCount((count) =>
                      Math.min(recentPayouts.length, count + 5),
                    )
                  }
                  className="text-[10px] font-black uppercase tracking-widest text-white/20 transition-colors hover:text-[#14B8A6]"
                >
                  Load More Financial Records
                </button>
              </div>
            </div>
          </>
        ) : null}
      </div>
    </AppShell>
  );
}
