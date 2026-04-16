import { useRouter } from "next/router";
import { ComplaintRecord } from "../../services/types";

interface ComplaintsTableProps {
  complaints: ComplaintRecord[];
  filterMode: "all" | "active" | "priority";
  onFilterModeChange: (mode: "all" | "active" | "priority") => void;
  page: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  onUpdateStatus: (complaint: ComplaintRecord) => Promise<void>;
}

function statusTone(status: string): string {
  const normalized = status.toLowerCase();
  if (normalized === "open") return "bg-cream text-brand-700";
  if (normalized === "in progress") return "bg-lilac/40 text-brand-700";
  if (normalized === "resolved") return "bg-brand-100 text-brand-700";
  return "bg-cream text-brand-600";
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
    return complaints.filter((item) => item.status.toLowerCase() !== "resolved");
  }
  if (filterMode === "priority") {
    return [...complaints].sort((a, b) => priorityRank(a.priority) - priorityRank(b.priority));
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
  const pageNumbers = Array.from({ length: Math.min(3, totalPages) }, (_, i) => i + 1);

  return (
    <div className="overflow-hidden rounded-3xl bg-white shadow-sm">
      <div className="flex items-center justify-between bg-cream p-6">
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => onFilterModeChange("all")}
            className={`rounded-lg px-4 py-2 text-sm transition-colors ${
              filterMode === "all"
                ? "bg-white font-bold text-brand-600 shadow-sm"
                : "font-medium text-brand-400 hover:bg-white/60"
            }`}
          >
            All Complaints
          </button>
          <button
            type="button"
            onClick={() => onFilterModeChange("active")}
            className={`rounded-lg px-4 py-2 text-sm transition-colors ${
              filterMode === "active"
                ? "bg-white font-bold text-brand-600 shadow-sm"
                : "font-medium text-brand-400 hover:bg-white/60"
            }`}
          >
            Active Only
          </button>
          <button
            type="button"
            onClick={() => onFilterModeChange("priority")}
            className={`rounded-lg px-4 py-2 text-sm transition-colors ${
              filterMode === "priority"
                ? "bg-white font-bold text-brand-600 shadow-sm"
                : "font-medium text-brand-400 hover:bg-white/60"
            }`}
          >
            By Priority
          </button>
        </div>
        <button className="flex items-center gap-2 text-sm font-bold text-brand-500 transition-colors hover:text-brand-600">
          <span className="material-symbols-outlined text-lg">filter_list</span>
          Advanced Filters
        </button>
      </div>

      <table className="w-full border-collapse">
        <thead>
          <tr className="bg-cream">
            <th className="px-8 py-4 text-left text-[11px] font-bold uppercase tracking-widest text-brand-400">Complaint ID</th>
            <th className="px-6 py-4 text-left text-[11px] font-bold uppercase tracking-widest text-brand-400">Order ID</th>
            <th className="px-6 py-4 text-left text-[11px] font-bold uppercase tracking-widest text-brand-400">User Name</th>
            <th className="px-6 py-4 text-left text-[11px] font-bold uppercase tracking-widest text-brand-400">Issue Type</th>
            <th className="px-6 py-4 text-left text-[11px] font-bold uppercase tracking-widest text-brand-400">Status</th>
            <th className="px-8 py-4 text-right text-[11px] font-bold uppercase tracking-widest text-brand-400">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-lilac/20">
          {visible.map((complaint) => (
            <tr key={complaint.id} className="group transition-colors duration-200 hover:bg-cream/70">
              <td className="px-8 py-5">
                <span className="font-bold text-brand-600">#{complaint.id}</span>
              </td>
              <td className="px-6 py-5">
                <span className="font-medium text-brand-400">#{complaint.orderId}</span>
              </td>
              <td className="px-6 py-5">
                <div className="flex items-center gap-3">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-lilac/30 text-xs font-bold text-brand-600">
                    {initials(complaint.customer)}
                  </div>
                  <span className="font-semibold text-brand-600">{complaint.customer}</span>
                </div>
              </td>
              <td className="px-6 py-5">
                <span className="rounded-full bg-cream px-3 py-1 text-xs font-bold uppercase text-brand-400">
                  {complaint.issueType}
                </span>
              </td>
              <td className="px-6 py-5">
                <span
                  className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold uppercase tracking-tight ${statusTone(
                    complaint.status,
                  )}`}
                >
                  <span className="h-1.5 w-1.5 rounded-full bg-brand-500"></span>
                  {complaint.status}
                </span>
              </td>
              <td className="px-8 py-5 text-right">
                <div className="flex justify-end gap-2 opacity-0 transition-opacity group-hover:opacity-100">
                  <button
                    type="button"
                    onClick={() => onUpdateStatus(complaint)}
                    className="rounded-lg bg-lilac/30 px-3 py-1.5 text-xs font-bold text-brand-600 transition-colors hover:bg-lilac/45"
                  >
                    Update Status
                  </button>
                  <button
                    type="button"
                    onClick={() => router.push(`/complaints?ticket=${encodeURIComponent(complaint.id)}`)}
                    className="rounded-lg bg-brand-500 px-3 py-1.5 text-xs font-bold text-white transition-colors hover:bg-brand-600"
                  >
                    View Details
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {visible.length === 0 ? (
        <div className="p-6 text-sm text-brand-400">No complaints found for selected filter.</div>
      ) : null}

      <div className="flex items-center justify-between bg-cream p-6">
        <p className="text-xs font-medium text-brand-400">
          Showing {filtered.length === 0 ? 0 : startIndex + 1} to {Math.min(startIndex + pageSize, filtered.length)} of {filtered.length} entries
        </p>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => onPageChange(Math.max(1, safePage - 1))}
            disabled={safePage === 1}
            className="flex h-8 w-8 items-center justify-center rounded-lg text-brand-400 transition-colors hover:bg-white disabled:opacity-30"
          >
            <span className="material-symbols-outlined text-sm">chevron_left</span>
          </button>
          {pageNumbers.map((pageNumber) => (
            <button
              key={pageNumber}
              type="button"
              onClick={() => onPageChange(pageNumber)}
              className={`flex h-8 w-8 items-center justify-center rounded-lg text-xs font-bold ${
                safePage === pageNumber
                  ? "bg-brand-500 text-white"
                  : "text-brand-400 hover:bg-white"
              }`}
            >
              {pageNumber}
            </button>
          ))}
          <button
            type="button"
            onClick={() => onPageChange(Math.min(totalPages, safePage + 1))}
            disabled={safePage === totalPages}
            className="flex h-8 w-8 items-center justify-center rounded-lg text-brand-400 transition-colors hover:bg-white disabled:opacity-30"
          >
            <span className="material-symbols-outlined text-sm">chevron_right</span>
          </button>
        </div>
      </div>
    </div>
  );
}
