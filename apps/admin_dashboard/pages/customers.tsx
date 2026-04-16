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
      <div className="space-y-8">
        <div className="flex items-end justify-between">
          <div>
            <h2 className="mb-2 text-4xl font-extrabold tracking-tight text-brand-600">Customer Management</h2>
            <p className="flex items-center gap-2 text-brand-400">
              <span className="material-symbols-outlined text-sm text-lilac">stars</span>
              Managing {activeUsersCount} active liquid-subscription customers
            </p>
          </div>

          <div className="flex gap-3">
            <button
              type="button"
              className="flex items-center gap-2 rounded-xl border border-lilac/40 bg-white px-6 py-2.5 text-sm font-semibold text-brand-600 transition-all hover:bg-cream"
            >
              <span className="material-symbols-outlined text-lg">filter_list</span>
              Filters
            </button>
            <button
              type="button"
              onClick={exportCsv}
              className="flex items-center gap-2 rounded-xl bg-lilac px-6 py-2.5 text-sm font-bold text-brand-700 shadow-md transition-all hover:shadow-lg"
            >
              <span className="material-symbols-outlined text-lg">download</span>
              Export CSV
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-xl bg-white p-6">
            <span className="mb-2 block text-xs font-bold uppercase tracking-widest text-brand-400">Active Users</span>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-black text-brand-600">{activeUsersCount}</span>
              <span className="text-xs font-bold text-brand-500">+12%</span>
            </div>
            <div className="mt-4 h-1.5 w-full overflow-hidden rounded-full bg-cream">
              <div
                className="h-full rounded-full bg-lilac"
                style={{ width: `${users.length === 0 ? 0 : Math.round((activeUsersCount / users.length) * 100)}%` }}
              ></div>
            </div>
          </div>

          <div className="rounded-xl bg-white p-6">
            <span className="mb-2 block text-xs font-bold uppercase tracking-widest text-brand-400">New This Month</span>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-black text-brand-600">{newThisMonth}</span>
              <span className="material-symbols-outlined text-sm text-brand-500">trending_up</span>
            </div>
            <p className="mt-4 text-[10px] text-brand-400">Growth rate based on current month sign-ups</p>
          </div>

          <div className="rounded-xl bg-white p-6">
            <span className="mb-2 block text-xs font-bold uppercase tracking-widest text-brand-400">Churn Rate</span>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-black text-brand-600">{churnRate.toFixed(1)}%</span>
              <span className="text-xs font-bold text-brand-500">Stable</span>
            </div>
            <p className="mt-4 text-[10px] text-brand-400">Industry benchmark: 2.1%</p>
          </div>

          <div className="relative overflow-hidden rounded-xl bg-brand-500 p-6 text-white">
            <div className="relative z-10">
              <span className="mb-2 block text-xs font-bold uppercase tracking-widest text-lilac">Lifetime Value</span>
              <div className="flex items-baseline gap-2">
                <span className="text-3xl font-black">${averageLtv.toFixed(2)}</span>
              </div>
              <p className="mt-4 text-[10px] text-lilac/80">Average per active customer account</p>
            </div>
            <div className="absolute -bottom-4 -right-4 opacity-20">
              <span className="material-symbols-outlined text-[100px]">payments</span>
            </div>
          </div>
        </div>

        <section className="space-y-4">
          {loading ? <LoadingState /> : null}
          {error ? <ErrorState message={error} /> : null}
          {actionError ? <ErrorState message={actionError} /> : null}
          {!loading && !error ? (
            <CustomersTable
              users={users}
              page={page}
              pageSize={5}
              onPageChange={setPage}
              onToggleBlocked={handleToggleBlocked}
              onViewHistory={(user) => router.push(`/orders?customer=${encodeURIComponent(user.name)}`)}
            />
          ) : null}
        </section>
      </div>
    </AppShell>
  );
}
