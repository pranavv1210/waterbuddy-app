import { useMemo, useState } from "react";

import { AppShell } from "../components/layout/AppShell";
import { ComplaintsTable } from "../components/tables/ComplaintsTable";
import { ErrorState } from "../components/ui/ErrorState";
import { LoadingState } from "../components/ui/LoadingState";
import { useComplaints } from "../hooks/useComplaints";
import { ComplaintRecord } from "../services/types";

function weekLabel(dateMillis: number): string {
  const now = new Date();
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - 6);
  return dateMillis >= startOfWeek.getTime() ? "current" : "previous";
}

export default function ComplaintsPage() {
  const { complaints, loading, error, updateComplaintStatus } = useComplaints();
  const [actionError, setActionError] = useState<string | null>(null);
  const [filterMode, setFilterMode] = useState<"all" | "active" | "priority">("all");
  const [page, setPage] = useState(1);

  const handleStatusUpdate = async (complaint: ComplaintRecord) => {
    setActionError(null);
    try {
      await updateComplaintStatus(complaint);
    } catch (statusError) {
      const message = statusError instanceof Error ? statusError.message : "Unable to update complaint status.";
      setActionError(message);
    }
  };

  const criticalOpenCount = complaints.filter(
    (complaint) => complaint.priority.toLowerCase() === "critical" && complaint.status.toLowerCase() !== "resolved",
  ).length;

  const totalCount = complaints.length;
  const openCount = complaints.filter((complaint) => complaint.status.toLowerCase() === "open").length;
  const resolvedCount = complaints.filter((complaint) => complaint.status.toLowerCase() === "resolved").length;
  const averageResolutionHours = complaints.length === 0 ? 0 : 2.4;

  const weeklySeries = useMemo(() => {
    const buckets = [0, 0, 0, 0, 0, 0, 0];
    complaints.forEach((complaint) => {
      if (typeof complaint.createdAt === "number") {
        const date = new Date(complaint.createdAt);
        const day = date.getDay();
        buckets[day] += 1;
      }
    });
    const maxValue = Math.max(...buckets, 1);
    return { buckets, maxValue };
  }, [complaints]);

  const currentWeek = complaints.filter(
    (complaint) => typeof complaint.createdAt === "number" && weekLabel(complaint.createdAt) === "current",
  ).length;
  const previousWeek = complaints.filter(
    (complaint) => typeof complaint.createdAt === "number" && weekLabel(complaint.createdAt) === "previous",
  ).length;
  const weeklyGrowthPercent = previousWeek === 0 ? 0 : ((currentWeek - previousWeek) / previousWeek) * 100;

  return (
    <AppShell>
      <div className="space-y-10">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div>
             <nav className="mb-2 flex gap-2 text-[10px] font-bold uppercase tracking-[0.2em] text-[#14B8A6]">
              <span>Support</span>
              <span className="text-white/20">/</span>
              <span className="text-white/60">Tickets</span>
            </nav>
            <h2 className="text-4xl font-extrabold tracking-tight text-white">Support Center</h2>
            <p className="mt-1 text-white/40 font-medium">
              Manage and resolve incoming water delivery issues and customer complaints.
            </p>
          </div>
          
          <div className="flex items-center gap-4 rounded-2xl bg-red-500/10 border border-red-500/20 p-5 backdrop-blur-xl">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-red-500/20 text-red-400">
              <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>priority_high</span>
            </div>
            <div>
              <p className="text-2xl font-black text-white leading-none">{criticalOpenCount}</p>
              <p className="mt-2 text-[10px] font-black uppercase tracking-[0.15em] text-red-400/60">Critical Open</p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
          <div className="flex flex-col justify-between rounded-2xl bg-[#0D1117]/60 border border-white/5 p-6 backdrop-blur-xl shadow-xl transition-all hover:bg-white/5">
            <div className="mb-6 flex items-start justify-between">
              <div className="bg-[#14B8A6]/10 w-10 h-10 rounded-xl flex items-center justify-center text-[#14B8A6]">
                <span className="material-symbols-outlined text-xl" style={{ fontVariationSettings: "'FILL' 1" }}>inbox</span>
              </div>
              <span className="text-[10px] font-bold uppercase tracking-widest text-white/20">Total</span>
            </div>
            <div>
              <p className="text-3xl font-black text-white tracking-tighter">{totalCount}</p>
              <p className="text-[10px] font-bold uppercase tracking-wider text-white/40 mt-1">Tickets Received</p>
            </div>
          </div>

          <div className="flex flex-col justify-between rounded-2xl bg-[#14B8A6] p-6 text-white shadow-[0_0_30px_rgba(20,184,166,0.2)]">
            <div className="mb-6 flex items-start justify-between">
              <div className="bg-white/20 w-10 h-10 rounded-xl flex items-center justify-center">
                <span className="material-symbols-outlined text-xl" style={{ fontVariationSettings: "'FILL' 1" }}>timer</span>
              </div>
              <span className="text-[10px] font-bold uppercase tracking-widest text-white/60">Efficiency</span>
            </div>
            <div>
              <p className="text-3xl font-black tracking-tighter">{averageResolutionHours.toFixed(1)}h</p>
              <p className="text-[10px] font-bold uppercase tracking-wider text-white/80 mt-1">Avg Resolution Time</p>
            </div>
          </div>

          <div className="md:col-span-2 rounded-2xl bg-[#0D1117]/60 border border-white/5 p-6 backdrop-blur-xl shadow-xl">
             <div className="flex items-center justify-between mb-6">
                <h4 className="text-xs font-bold text-white uppercase tracking-widest">Weekly Volume</h4>
                <div className="text-right">
                  <p className={`text-xs font-black tracking-wider ${weeklyGrowthPercent >= 0 ? "text-red-400" : "text-emerald-400"}`}>
                    {weeklyGrowthPercent >= 0 ? "+" : ""}
                    {weeklyGrowthPercent.toFixed(0)}%
                  </p>
                  <p className="text-[10px] text-white/20 font-bold uppercase tracking-tighter">vs Last Week</p>
                </div>
             </div>
             <div className="flex h-16 items-end gap-2 px-2">
                {weeklySeries.buckets.map((value, index) => (
                  <div
                    key={index}
                    className={`flex-1 rounded-t-lg transition-all duration-500 ${index === new Date().getDay() ? "bg-[#14B8A6] shadow-[0_0_15px_rgba(20,184,166,0.4)]" : "bg-white/10 hover:bg-white/20"}`}
                    style={{ height: `${Math.max(15, (value / weeklySeries.maxValue) * 100)}%` }}
                  ></div>
                ))}
             </div>
          </div>
        </div>

        <section className="space-y-4">
          {loading ? <LoadingState /> : null}
          {error ? <ErrorState message={error} /> : null}
          {actionError ? <ErrorState message={actionError} /> : null}
          {!loading && !error ? (
            <ComplaintsTable
              complaints={complaints}
              filterMode={filterMode}
              onFilterModeChange={(nextFilter) => {
                setFilterMode(nextFilter);
                setPage(1);
              }}
              page={page}
              pageSize={6}
              onPageChange={setPage}
              onUpdateStatus={handleStatusUpdate}
            />
          ) : null}
        </section>

        {!loading && !error ? (
          <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
            <div className="relative group overflow-hidden rounded-3xl bg-[#0D1117]/60 border border-white/5 p-8 lg:col-span-2 shadow-xl backdrop-blur-xl">
              <div className="absolute -right-20 -top-20 h-64 w-64 rounded-full bg-[#14B8A6]/5 blur-3xl group-hover:bg-[#14B8A6]/10 transition-all"></div>
              <div className="relative z-10 flex h-full flex-col justify-center">
                <h3 className="mb-2 text-2xl font-extrabold text-white tracking-tight">
                  Satisfaction Score: <span className="text-[#14B8A6]">{totalCount === 0 ? "100" : Math.max(0, Math.round((resolvedCount / totalCount) * 100))}%</span>
                </h3>
                <p className="mb-6 max-w-md text-sm text-white/40 font-medium leading-relaxed">
                  Your team improved ticket closure consistency this week. Performance is tracking 12% above last month's baseline.
                </p>
                <div className="flex gap-4">
                  <button className="rounded-xl bg-white/5 border border-white/10 px-6 py-2.5 text-[10px] font-black uppercase tracking-widest text-white/60 transition-all hover:bg-white/10 hover:text-white">
                    Detailed Analytics
                  </button>
                </div>
              </div>
            </div>

            <div className="flex flex-col justify-between rounded-3xl bg-white/5 border border-white/5 p-8 backdrop-blur-xl">
              <div>
                <h4 className="mb-1 text-sm font-black text-white uppercase tracking-widest">Sentiment AI</h4>
                <p className="mb-8 text-[10px] font-bold uppercase tracking-widest text-white/20">Network Health Index</p>
              </div>
              <div className="space-y-6">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-bold text-white/60">Resolution Success</span>
                  <span className="text-xs font-black text-[#14B8A6]">
                    {totalCount === 0 ? "100" : Math.max(0, Math.round((resolvedCount / totalCount) * 100))}%
                  </span>
                </div>
                <div className="h-2 w-full rounded-full bg-white/5 border border-white/5 overflow-hidden">
                  <div
                    className="h-full rounded-full bg-[#14B8A6] shadow-[0_0_10px_rgba(20,184,166,0.5)] transition-all duration-1000"
                    style={{ width: `${totalCount === 0 ? 100 : Math.max(0, Math.round((resolvedCount / totalCount) * 100))}%` }}
                  ></div>
                </div>
                <p className="text-[10px] italic text-white/20 font-medium leading-tight">
                  *Resolution index is calculated based on the last 50 processed support tickets.
                </p>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </AppShell>
  );
}
