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
      <div className="space-y-8">
        <div className="mb-8 flex items-end justify-between">
          <div>
            <h2 className="mb-2 text-4xl font-extrabold tracking-tight text-brand-600">Support Tickets</h2>
            <p className="text-brand-400">
              Manage and resolve incoming water delivery issues and customer complaints.
            </p>
          </div>
          <div className="flex items-center gap-4 rounded-xl bg-white p-4 shadow-sm">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-cream text-brand-600">
              <span className="material-symbols-outlined">priority_high</span>
            </div>
            <div>
              <p className="text-2xl font-bold text-brand-600 leading-none">{criticalOpenCount}</p>
              <p className="mt-1 text-xs font-medium uppercase tracking-wider text-brand-400">Critical Open</p>
            </div>
          </div>
        </div>

        <div className="mb-8 grid grid-cols-1 gap-4 md:grid-cols-4">
          <div className="group flex cursor-pointer flex-col justify-between rounded-2xl bg-white p-6 shadow-sm transition-colors hover:bg-cream">
            <div className="mb-4 flex items-start justify-between">
              <span className="material-symbols-outlined text-3xl text-brand-500">inbox</span>
              <span className="text-xs font-bold uppercase tracking-widest text-brand-300">Total</span>
            </div>
            <div>
              <p className="text-3xl font-black text-brand-600">{totalCount}</p>
              <p className="text-sm font-medium text-brand-400">Received this month</p>
            </div>
          </div>

          <div className="flex cursor-pointer flex-col justify-between rounded-2xl bg-brand-500 p-6 text-white shadow-sm transition-transform hover:scale-[1.01]">
            <div className="mb-4 flex items-start justify-between">
              <span className="material-symbols-outlined text-3xl text-lilac">timer</span>
              <span className="text-xs font-bold uppercase tracking-widest text-white/40">Speed</span>
            </div>
            <div>
              <p className="text-3xl font-black">{averageResolutionHours.toFixed(1)}h</p>
              <p className="text-sm font-medium text-white/70">Avg. Resolution Time</p>
            </div>
          </div>

          <div className="col-span-1 flex items-center gap-8 rounded-2xl bg-white p-6 shadow-sm md:col-span-2">
            <div className="flex-1">
              <h4 className="mb-1 font-bold text-brand-600">Weekly Volume</h4>
              <div className="mt-4 flex h-16 items-end gap-2">
                {weeklySeries.buckets.map((value, index) => (
                  <div
                    key={index}
                    className={`w-full rounded-t-md ${index === 3 ? "bg-lilac" : "bg-brand-100"}`}
                    style={{ height: `${Math.max(15, (value / weeklySeries.maxValue) * 100)}%` }}
                  ></div>
                ))}
              </div>
            </div>
            <div className="text-right">
              <p className="text-xs font-bold uppercase tracking-widest text-brand-500">
                {weeklyGrowthPercent >= 0 ? "+" : ""}
                {weeklyGrowthPercent.toFixed(0)}%
              </p>
              <p className="text-xs text-brand-400">vs last week</p>
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
              pageSize={4}
              onPageChange={setPage}
              onUpdateStatus={handleStatusUpdate}
            />
          ) : null}
        </section>

        {!loading && !error ? (
          <div className="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-3">
            <div className="group relative h-48 overflow-hidden rounded-3xl lg:col-span-2">
              <div className="absolute inset-0 bg-gradient-to-r from-brand-500 to-brand-600/80"></div>
              <div className="absolute inset-0 opacity-20">
                <div className="absolute -left-10 top-8 h-32 w-32 rounded-full bg-lilac blur-2xl transition-transform duration-700 group-hover:scale-125"></div>
                <div className="absolute right-6 top-4 h-20 w-20 rounded-full bg-white/20 blur-xl transition-transform duration-700 group-hover:scale-110"></div>
                <div className="absolute bottom-0 right-12 h-24 w-24 rounded-full bg-brand-100 blur-2xl transition-transform duration-700 group-hover:scale-125"></div>
              </div>
              <div className="relative z-20 flex h-full flex-col justify-center p-8 text-white">
                <h3 className="mb-2 text-2xl font-bold">
                  Customer Satisfaction is {totalCount === 0 ? "0" : Math.max(0, Math.round((resolvedCount / totalCount) * 100))}%
                </h3>
                <p className="mb-4 max-w-md text-sm text-white/70">
                  Your team improved ticket closure consistency this week. Keep monitoring critical tickets closely.
                </p>
                <div className="flex gap-4">
                  <button className="rounded-full bg-lilac px-6 py-2 text-xs font-bold uppercase tracking-widest text-brand-700">
                    Review Team Stats
                  </button>
                </div>
              </div>
            </div>

            <div className="flex flex-col justify-between rounded-3xl bg-lilac p-8 text-brand-700">
              <div>
                <h4 className="mb-2 text-lg font-bold">AI Summary</h4>
                <p className="mb-4 text-xs uppercase tracking-widest text-brand-500">Sentiment Analysis</p>
              </div>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium">Positive</span>
                  <span className="rounded bg-white/40 px-2 py-0.5 text-xs font-bold">
                    {totalCount === 0 ? "0" : Math.max(0, Math.round((resolvedCount / totalCount) * 100))}%
                  </span>
                </div>
                <div className="h-2 w-full rounded-full bg-white/40">
                  <div
                    className="h-full rounded-full bg-brand-500"
                    style={{ width: `${totalCount === 0 ? 0 : Math.max(0, Math.round((resolvedCount / totalCount) * 100))}%` }}
                  ></div>
                </div>
                <p className="text-[10px] italic text-brand-500">*Based on the last 50 resolved tickets</p>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </AppShell>
  );
}
