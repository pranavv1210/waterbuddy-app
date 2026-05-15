import { useMemo, useState } from "react";
import { useRouter } from "next/router";

import { AppShell } from "../components/layout/AppShell";
import { CustomersTable } from "../components/tables/CustomersTable";
import { ErrorState } from "../components/ui/ErrorState";
import { LoadingState } from "../components/ui/LoadingState";
import { useUsers } from "../hooks/useUsers";
import { UserRecord } from "../services/types";

function isCurrentMonth(value: number | string | undefined): boolean {
  if (!value) return false;
  const date = new Date(value);
  const now = new Date();
  return date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear();
}

export default function CustomersPage() {
  const router = useRouter();
  const { users, loading, error, toggleUserBlocked } = useUsers();
  const [actionError, setActionError] = useState<string | null>(null);
  const [page, setPage] = useState(1);

  const activeUsersCount = users.filter((user) => !user.blocked).length;
  const newThisMonth = users.filter((user) => isCurrentMonth(user.joinDate)).length;
  const churnRate = users.length === 0 ? 0 : (users.filter((user) => user.blocked).length / users.length) * 100;
  const averageLtv = useMemo(() => {
    const total = users.reduce((sum, user) => sum + (user.lifetimeValue ?? 0), 0);
    return users.length === 0 ? 0 : total / users.length;
  }, [users]);

  const exportCsv = () => {
    const rows = [
      ["id", "name", "email", "phone", "role", "totalOrders", "joinDate", "blocked", "lifetimeValue"],
      ...users.map((user) => [
        user.id,
        user.name,
        user.email,
        user.phone,
        user.role,
        String(user.totalOrders),
        String(user.joinDate ?? ""),
        String(user.blocked),
        String(user.lifetimeValue ?? ""),
      ]),
    ];
    const csv = rows.map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "waterbuddy-customers.csv";
    anchor.click();
    URL.revokeObjectURL(url);
  };

  const handleToggleBlocked = async (user: UserRecord) => {
    setActionError(null);
    try {
      await toggleUserBlocked(user);
    } catch (toggleError) {
      const message = toggleError instanceof Error ? toggleError.message : "Unable to update customer status.";
      setActionError(message);
    }
  };

  return (
    <AppShell>
      <div className="space-y-10">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <nav className="mb-2 flex gap-2 text-[10px] font-bold uppercase tracking-[0.2em] text-[#14B8A6]">
              <span>Management</span>
              <span className="text-white/20">/</span>
              <span className="text-white/60">Customer Base</span>
            </nav>
            <h2 className="text-4xl font-extrabold tracking-tight text-white">Customer Hub</h2>
            <p className="mt-1 flex items-center gap-2 text-white/40 font-medium">
               <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#14B8A6] opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-[#14B8A6]"></span>
              </span>
              Managing {activeUsersCount} active liquid-subscription customers
            </p>
          </div>

          <div className="flex gap-3">
            <button
              type="button"
              className="flex items-center gap-2 rounded-xl bg-white/5 border border-white/10 px-6 py-2.5 text-xs font-bold text-white/60 transition-all hover:bg-white/10 hover:text-white"
            >
              <span className="material-symbols-outlined text-lg">filter_list</span>
              Filters
            </button>
            <button
              type="button"
              onClick={exportCsv}
              className="flex items-center gap-2 rounded-xl bg-[#14B8A6] px-6 py-2.5 text-xs font-black text-white shadow-[0_0_20px_rgba(20,184,166,0.3)] transition-all hover:scale-[1.02] active:scale-[0.98] uppercase tracking-widest"
            >
              <span className="material-symbols-outlined text-lg">download</span>
              Export List
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-2xl bg-[#0D1117]/60 border border-white/5 p-6 backdrop-blur-xl shadow-xl transition-all hover:bg-white/5 group">
            <span className="mb-4 block text-[10px] font-bold uppercase tracking-widest text-[#14B8A6]">Active Users</span>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-black text-white tracking-tighter">{activeUsersCount}</span>
              <span className="text-xs font-bold text-emerald-400">+12.4%</span>
            </div>
            <div className="mt-6 h-1.5 w-full overflow-hidden rounded-full bg-white/5 border border-white/5">
              <div
                className="h-full rounded-full bg-[#14B8A6] shadow-[0_0_10px_rgba(20,184,166,0.5)]"
                style={{ width: `${users.length === 0 ? 0 : Math.round((activeUsersCount / users.length) * 100)}%` }}
              ></div>
            </div>
          </div>

          <div className="rounded-2xl bg-[#0D1117]/60 border border-white/5 p-6 backdrop-blur-xl shadow-xl transition-all hover:bg-white/5">
            <span className="mb-4 block text-[10px] font-bold uppercase tracking-widest text-[#14B8A6]">Acquisition</span>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-black text-white tracking-tighter">{newThisMonth}</span>
              <span className="material-symbols-outlined text-xl text-emerald-400" style={{ fontVariationSettings: "'FILL' 1" }}>trending_up</span>
            </div>
            <p className="mt-4 text-[10px] text-white/40 font-bold uppercase tracking-wider">New Sign-ups This Month</p>
          </div>

          <div className="rounded-2xl bg-[#0D1117]/60 border border-white/5 p-6 backdrop-blur-xl shadow-xl transition-all hover:bg-white/5">
            <span className="mb-4 block text-[10px] font-bold uppercase tracking-widest text-red-400">Churn Rate</span>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-black text-white tracking-tighter">{churnRate.toFixed(1)}%</span>
              <span className="text-xs font-bold text-white/20 ml-1 tracking-widest">STABLE</span>
            </div>
            <p className="mt-4 text-[10px] text-white/40 font-bold uppercase tracking-wider">Industry Avg: 2.1%</p>
          </div>

          <div className="relative overflow-hidden rounded-2xl bg-[#14B8A6] p-6 text-white shadow-[0_0_30px_rgba(20,184,166,0.2)]">
            <div className="relative z-10 h-full flex flex-col justify-between">
              <span className="block text-[10px] font-black uppercase tracking-[0.2em] text-white/60">Lifetime Value</span>
              <div>
                <div className="flex items-baseline gap-2">
                  <span className="text-3xl font-black tracking-tighter">₹{averageLtv.toFixed(0)}</span>
                  <span className="text-[10px] font-bold uppercase opacity-60">Avg</span>
                </div>
                <p className="mt-1 text-[10px] text-white/80 font-medium">Per Active Customer Account</p>
              </div>
            </div>
            <div className="absolute -bottom-8 -right-8 opacity-20">
              <span className="material-symbols-outlined text-[120px]" style={{ fontVariationSettings: "'FILL' 1" }}>payments</span>
            </div>
          </div>
        </div>

        <section className="space-y-4">
          {loading ? <LoadingState /> : null}
          {error ? <ErrorState message={error} /> : null}
          {actionError ? <ErrorState message={actionError} /> : null}
          {!loading && !error ? (
            <CustomersTable
              customers={users}
              page={page}
              pageSize={8}
              onPageChange={setPage}
              onToggleBlocked={handleToggleBlocked}
            />
          ) : null}
        </section>
      </div>
    </AppShell>
  );
}
