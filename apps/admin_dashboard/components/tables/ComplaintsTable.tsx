import { useRouter } from "next/router";
import { ComplaintRecord } from "../../services/types";
import { StatusBadge } from "../ui/StatusBadge";

interface ComplaintsTableProps {
  complaints: ComplaintRecord[];
  filterMode: "all" | "active" | "priority";
  onFilterModeChange: (mode: "all" | "active" | "priority") => void;
  page: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  onUpdateStatus: (complaint: ComplaintRecord) => Promise<void>;
}

function priorityRank(priority: string): number {
  const normalized = priority.toLowerCase();
  if (normalized === "critical") return 0;
  if (normalized === "high") return 1;
  if (normalized === "medium") return 2;
  return 3;
}

function filteredComplaints(
  complaints: ComplaintRecord[],
  filterMode: "all" | "active" | "priority",
): ComplaintRecord[] {
  if (filterMode === "active") {
    return complaints.filter(
      (item) => item.status.toLowerCase() !== "resolved",
    );
  }
  if (filterMode === "priority") {
    return [...complaints].sort(
      (a, b) => priorityRank(a.priority) - priorityRank(b.priority),
    );
  }
  return complaints;
}

function initials(name: string): string {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part.charAt(0).toUpperCase())
    .join("");
}

export function ComplaintsTable({
  complaints,
  filterMode,
  onFilterModeChange,
  page,
  pageSize,
  onPageChange,
  onUpdateStatus,
}: ComplaintsTableProps) {
  const router = useRouter();
  const filtered = filteredComplaints(complaints, filterMode);
  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const safePage = Math.min(page, totalPages);
  const startIndex = (safePage - 1) * pageSize;
  const visible = filtered.slice(startIndex, startIndex + pageSize);
  const pageNumbers = Array.from(
    { length: Math.min(3, totalPages) },
    (_, i) => i + 1,
  );

  return (
    <div className="overflow-hidden rounded-3xl border border-white/5 bg-[#0D1117]/60 shadow-xl backdrop-blur-xl">
      <div className="flex flex-wrap items-center justify-between bg-white/[0.03] p-6 gap-4">
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => onFilterModeChange("all")}
            className={`rounded-xl px-5 py-2 text-xs font-bold transition-all ${
              filterMode === "all"
                ? "bg-[#14B8A6] text-white shadow-[0_0_15px_rgba(20,184,166,0.4)]"
                : "bg-white/5 text-white/60 hover:bg-white/10"
            }`}
          >
            All Tickets
          </button>
          <button
            type="button"
            onClick={() => onFilterModeChange("active")}
            className={`rounded-xl px-5 py-2 text-xs font-bold transition-all ${
              filterMode === "active"
                ? "bg-amber-500 text-white shadow-[0_0_15px_rgba(245,158,11,0.4)]"
                : "bg-white/5 text-white/60 hover:bg-white/10"
            }`}
          >
            Active Only
          </button>
          <button
            type="button"
            onClick={() => onFilterModeChange("priority")}
            className={`rounded-xl px-5 py-2 text-xs font-bold transition-all ${
              filterMode === "priority"
                ? "bg-red-500 text-white shadow-[0_0_15px_rgba(239,68,68,0.4)]"
                : "bg-white/5 text-white/60 hover:bg-white/10"
            }`}
          >
            By Priority
          </button>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full border-collapse">
          <thead>
            <tr className="bg-white/5 text-[10px] uppercase tracking-[0.2em] text-white/40">
              <th className="px-8 py-5 text-left font-bold">Complaint ID</th>
              <th className="px-6 py-5 text-left font-bold">Order ID</th>
              <th className="px-6 py-5 text-left font-bold">User</th>
              <th className="px-6 py-5 text-left font-bold">Issue Type</th>
              <th className="px-6 py-5 text-left font-bold">Status</th>
              <th className="px-8 py-5 text-right font-bold">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5 text-sm">
            {visible.map((complaint) => (
              <tr
                key={complaint.id}
                className="group transition-colors duration-200 hover:bg-white/5"
              >
                <td className="px-8 py-6">
                  <span className="font-bold text-[#14B8A6]">
                    #{complaint.id}
                  </span>
                </td>
                <td className="px-6 py-6">
                  <span className="font-bold text-white/40">
                    #{complaint.orderId}
                  </span>
                </td>
                <td className="px-6 py-6">
                  <div className="flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#0F766E]/20 text-xs font-bold text-[#14B8A6] border border-[#14B8A6]/10">
                      {initials(complaint.customer)}
                    </div>
                    <span className="font-bold text-white/90">
                      {complaint.customer}
                    </span>
                  </div>
                </td>
                <td className="px-6 py-6">
                  <span className="rounded-lg bg-white/5 px-3 py-1 text-[10px] font-bold uppercase tracking-wider text-white/60 border border-white/5">
                    {complaint.issueType}
                  </span>
                </td>
                <td className="px-6 py-6">
                  <StatusBadge value={complaint.status} />
                </td>
                <td className="px-8 py-6 text-right">
                  <div className="flex justify-end gap-2 opacity-0 transition-opacity group-hover:opacity-100">
                    <button
                      type="button"
                      onClick={() => onUpdateStatus(complaint)}
                      className="rounded-xl border border-white/10 bg-white/5 px-4 py-2 text-xs font-bold text-white/60 transition-all hover:bg-white/10 hover:text-white"
                    >
                      Update
                    </button>
                    <button
                      type="button"
                      onClick={() =>
                        router.push(
                          `/complaints?ticket=${encodeURIComponent(complaint.id)}`,
                        )
                      }
                      className="rounded-xl bg-[#14B8A6] px-4 py-2 text-xs font-bold text-white transition-all hover:bg-[#14B8A6]/80 shadow-[0_0_15px_rgba(20,184,166,0.3)]"
                    >
                      Details
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {visible.length === 0 && (
        <div className="p-16 text-center text-sm text-white/20">
          No complaints found.
        </div>
      )}

      <div className="flex items-center justify-between bg-white/[0.02] border-t border-white/5 px-8 py-6">
        <p className="text-xs font-medium text-white/40">
          Showing{" "}
          <span className="text-white/80">
            {filtered.length === 0 ? 0 : startIndex + 1} to{" "}
            {Math.min(startIndex + pageSize, filtered.length)}
          </span>{" "}
          of <span className="text-white/80">{filtered.length}</span> entries
        </p>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => onPageChange(Math.max(1, safePage - 1))}
            disabled={safePage === 1}
            className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/5 bg-white/5 text-white/40 transition-colors hover:bg-white/10 hover:text-white disabled:opacity-20"
          >
            <span className="material-symbols-outlined text-sm">
              chevron_left
            </span>
          </button>
          {pageNumbers.map((pageNumber) => (
            <button
              key={pageNumber}
              type="button"
              onClick={() => onPageChange(pageNumber)}
              className={`h-10 w-10 rounded-xl text-xs font-bold transition-all ${
                safePage === pageNumber
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
            className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/5 bg-white/5 text-white/40 transition-colors hover:bg-white/10 hover:text-white disabled:opacity-20"
          >
            <span className="material-symbols-outlined text-sm">
              chevron_right
            </span>
          </button>
        </div>
      </div>
    </div>
  );
}
