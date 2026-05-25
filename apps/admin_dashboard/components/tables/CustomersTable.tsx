import { useRouter } from "next/router";
import { UserRecord } from "../../services/types";

interface CustomersTableProps {
  customers: UserRecord[];
  page: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  onToggleBlocked: (user: UserRecord) => Promise<void>;
}

export function CustomersTable({ customers, page, pageSize, onPageChange, onToggleBlocked }: CustomersTableProps) {
  const router = useRouter();
  const totalPages = Math.max(1, Math.ceil(customers.length / pageSize));
  const safePage = Math.min(page, totalPages);
  const startIndex = (safePage - 1) * pageSize;
  const visibleUsers = customers.slice(startIndex, startIndex + pageSize);
  const pageNumbers = Array.from({ length: Math.min(5, totalPages) }, (_, index) => index + 1);

  return (
    <div className="overflow-hidden rounded-3xl border border-white/5 bg-[#0D1117]/60 shadow-xl backdrop-blur-xl">
      <div className="overflow-x-auto">
        <table className="min-w-full border-collapse text-left">
          <thead className="bg-white/5 text-[10px] uppercase tracking-[0.2em] text-white/40">
            <tr>
              <th className="px-6 py-4 font-bold">User Details</th>
              <th className="px-5 py-4 font-bold">Registration Date</th>
              <th className="px-5 py-4 font-bold">Platform Status</th>
              <th className="px-6 py-4 text-right font-bold">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5 text-sm">
            {visibleUsers.map((user) => (
              <tr key={user.id} className="group transition-colors duration-200 hover:bg-white/5">
                <td className="px-6 py-5">
                  <div>
                    <p className="text-base font-bold text-white/90">{user.name}</p>
                    <p className="text-sm text-white/40 font-medium">{user.phone || user.id}</p>
                  </div>
                </td>

                <td className="px-5 py-5 text-white/60 font-medium">
                  {user.joinDate || "N/A"}
                </td>

                <td className="px-5 py-5">
                  <div className="flex items-center gap-2">
                    <span className={`h-2 w-2 rounded-full ${user.blocked ? "bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.5)]" : "bg-[#14B8A6] shadow-[0_0_8px_rgba(20,184,166,0.5)]"}`}></span>
                    <span className={`text-xs font-bold uppercase tracking-wider ${user.blocked ? "text-red-400" : "text-[#14B8A6]"}`}>
                      {user.blocked ? "Blocked" : "Active"}
                    </span>
                  </div>
                </td>

                <td className="px-6 py-5 text-right">
                  <div className="flex justify-end gap-3">
                    <button
                      type="button"
                      onClick={() => router.push(`/customers?id=${user.id}`)}
                      className="rounded-xl border border-white/10 bg-white/5 px-4 py-2 text-xs font-bold text-white/60 transition-all hover:bg-white/10 hover:text-white"
                    >
                      View
                    </button>
                    <button
                      type="button"
                      onClick={() => onToggleBlocked(user)}
                      className={`rounded-xl px-4 py-2 text-xs font-bold transition-all ${
                        user.blocked
                          ? "bg-amber-500/10 text-amber-400 border border-amber-500/20 hover:bg-amber-500/20"
                          : "bg-red-500/10 text-red-400 border border-red-500/20 hover:bg-red-500/20"
                      }`}
                    >
                      {user.blocked ? "Unblock" : "Block User"}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {visibleUsers.length === 0 && (
        <div className="p-8 text-center text-sm text-white/20">No customers found.</div>
      )}

      <div className="flex items-center justify-between border-t border-white/5 bg-white/[0.02] px-6 py-4">
        <p className="text-xs font-medium text-white/40">
          Showing <span className="text-white/80">{customers.length === 0 ? 0 : startIndex + 1}-{Math.min(startIndex + pageSize, customers.length)}</span> of <span className="text-white/80">{customers.length}</span> customers
        </p>

        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => onPageChange(Math.max(1, safePage - 1))}
            disabled={safePage === 1}
            className="flex h-9 w-9 items-center justify-center rounded-xl border border-white/5 bg-white/5 text-white/40 transition-colors hover:bg-white/10 hover:text-white disabled:opacity-20"
          >
            <span className="material-symbols-outlined">chevron_left</span>
          </button>

          {pageNumbers.map((pageNumber) => (
            <button
              key={pageNumber}
              type="button"
              onClick={() => onPageChange(pageNumber)}
              className={`h-9 w-9 rounded-xl text-xs font-bold transition-all ${
                pageNumber === safePage
                  ? "bg-[#14B8A6] text-white shadow-[0_0_15px_rgba(20,184,166,0.4)]"
                  : "bg-white/5 text-white/60 hover:bg-white/10"
              }`}
            >
              {pageNumber}
            </button>
          ))}

          <button
            type="button"
            onClick={() => onPageChange(Math.min(totalPages, safePage + 1))}
            disabled={safePage === totalPages}
            className="flex h-9 w-9 items-center justify-center rounded-xl border border-white/5 bg-white/5 text-white/40 transition-colors hover:bg-white/10 hover:text-white disabled:opacity-20"
          >
            <span className="material-symbols-outlined">chevron_right</span>
          </button>
        </div>
      </div>
    </div>
  );
}
