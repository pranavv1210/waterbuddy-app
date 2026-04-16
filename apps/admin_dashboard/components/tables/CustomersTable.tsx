import { UserRecord } from "../../services/types";

interface CustomersTableProps {
  users: UserRecord[];
  page: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  onToggleBlocked: (user: UserRecord) => Promise<void>;
  onViewHistory: (user: UserRecord) => void;
}

function formatDate(value: number | string | undefined): string {
  if (!value) return "-";
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "2-digit",
    year: "numeric",
  }).format(new Date(value));
}

function getInitials(name: string): string {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part.charAt(0).toUpperCase())
    .join("");
}

export function CustomersTable({
  users,
  page,
  pageSize,
  onPageChange,
  onToggleBlocked,
  onViewHistory,
}: CustomersTableProps) {
  const totalPages = Math.max(1, Math.ceil(users.length / pageSize));
  const safePage = Math.min(page, totalPages);
  const startIndex = (safePage - 1) * pageSize;
  const visibleUsers = users.slice(startIndex, startIndex + pageSize);

  const maxVisiblePages = 4;
  const pageNumbers = Array.from(
    { length: Math.min(totalPages, maxVisiblePages) },
    (_, index) => index + 1,
  );

  return (
    <div className="overflow-hidden rounded-xl border border-lilac/15 bg-white shadow-sm">
      <table className="w-full border-collapse text-left">
        <thead>
          <tr className="bg-cream">
            <th className="px-8 py-5 text-xs font-black uppercase tracking-widest text-brand-400">Customer Name</th>
            <th className="px-8 py-5 text-xs font-black uppercase tracking-widest text-brand-400">Phone</th>
            <th className="px-8 py-5 text-xs font-black uppercase tracking-widest text-brand-400">Total Orders</th>
            <th className="px-8 py-5 text-xs font-black uppercase tracking-widest text-brand-400">Join Date</th>
            <th className="px-8 py-5 text-right text-xs font-black uppercase tracking-widest text-brand-400">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-lilac/20">
          {visibleUsers.map((user) => (
            <tr key={user.id} className="group transition-colors duration-200 hover:bg-cream/70">
              <td className="px-8 py-6">
                <div className="flex items-center gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-lilac/40 font-semibold text-brand-700">
                    {getInitials(user.name)}
                  </div>
                  <div>
                    <p className="font-bold text-brand-600">{user.name}</p>
                    <p className="text-xs text-brand-400">{user.email}</p>
                  </div>
                </div>
              </td>

              <td className="px-8 py-6">
                <span className="text-sm font-medium text-brand-500">{user.phone}</span>
              </td>

              <td className="px-8 py-6">
                <div className="flex items-center gap-2">
                  <span className="rounded-full bg-lilac/40 px-3 py-1 text-xs font-bold text-brand-700">
                    {user.totalOrders} Orders
                  </span>
                </div>
              </td>

              <td className="px-8 py-6">
                <p className="text-sm text-brand-400">{formatDate(user.joinDate)}</p>
              </td>

              <td className="px-8 py-6 text-right">
                <div className="flex justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => onViewHistory(user)}
                    className="rounded-lg bg-lilac/30 px-4 py-2 text-xs font-bold text-brand-600 transition-all hover:bg-lilac/45"
                  >
                    View History
                  </button>
                  <button
                    type="button"
                    onClick={() => onToggleBlocked(user)}
                    className={`rounded-lg px-4 py-2 text-xs font-bold transition-all ${
                      user.blocked
                        ? "bg-lilac/35 text-brand-700 hover:bg-lilac/50"
                        : "bg-cream text-brand-700 hover:bg-lilac/30"
                    }`}
                  >
                    {user.blocked ? "Unblock User" : "Block User"}
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {visibleUsers.length === 0 ? <div className="p-6 text-sm text-brand-400">No customers found.</div> : null}

      <div className="flex items-center justify-between bg-cream/50 px-8 py-6">
        <p className="text-xs font-medium text-brand-400">
          Showing {users.length === 0 ? 0 : startIndex + 1} to {Math.min(startIndex + pageSize, users.length)} of {users.length} customers
        </p>

        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => onPageChange(Math.max(1, safePage - 1))}
            disabled={safePage === 1}
            className="rounded-lg border border-lilac/40 p-2 text-brand-400 transition-all hover:bg-white disabled:opacity-30"
          >
            <span className="material-symbols-outlined">chevron_left</span>
          </button>

          {pageNumbers.map((pageNumber) => (
            <button
              key={pageNumber}
              type="button"
              onClick={() => onPageChange(pageNumber)}
              className={`flex h-10 w-10 items-center justify-center rounded-lg text-sm font-bold transition-all ${
                pageNumber === safePage
                  ? "bg-brand-500 text-white"
                  : "border border-lilac/40 bg-white text-brand-600 hover:bg-cream"
              }`}
            >
              {pageNumber}
            </button>
          ))}

          {totalPages > maxVisiblePages ? <span className="flex items-center px-2 text-brand-400">...</span> : null}

          {totalPages > maxVisiblePages ? (
            <button
              type="button"
              onClick={() => onPageChange(totalPages)}
              className={`flex h-10 w-10 items-center justify-center rounded-lg text-sm font-bold transition-all ${
                totalPages === safePage
                  ? "bg-brand-500 text-white"
                  : "border border-lilac/40 bg-white text-brand-600 hover:bg-cream"
              }`}
            >
              {totalPages}
            </button>
          ) : null}

          <button
            type="button"
            onClick={() => onPageChange(Math.min(totalPages, safePage + 1))}
            disabled={safePage === totalPages}
            className="rounded-lg border border-lilac/40 p-2 text-brand-600 transition-all hover:bg-white disabled:opacity-30"
          >
            <span className="material-symbols-outlined">chevron_right</span>
          </button>
        </div>
      </div>
    </div>
  );
}
