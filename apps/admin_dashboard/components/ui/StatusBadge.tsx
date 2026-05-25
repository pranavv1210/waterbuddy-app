interface StatusBadgeProps {
  value: string;
}

export function StatusBadge({ value }: StatusBadgeProps) {
  const normalized = value.toLowerCase();

  const styles =
    normalized === "searching"
      ? "bg-sky-50 text-sky-700 border-sky-200"
      : normalized === "assigned"
        ? "bg-indigo-50 text-indigo-700 border-indigo-200"
        : normalized === "on the way"
          ? "bg-amber-50 text-amber-700 border-amber-200"
          : normalized === "delivered" ||
              normalized === "resolved" ||
              normalized === "online" ||
              normalized === "completed" ||
              normalized === "approved" ||
              normalized === "active"
            ? "bg-emerald-50 text-emerald-700 border-emerald-200"
            : normalized === "cancelled" ||
                normalized === "rejected" ||
                normalized === "blocked" ||
                normalized === "critical"
              ? "bg-red-50 text-red-700 border-red-200"
              : "bg-slate-50 text-slate-600 border-slate-200";

  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-lg border px-2.5 py-1 text-[10px] font-black uppercase tracking-widest ${styles}`}
    >
      <span className="h-1 w-1 rounded-full bg-current"></span>
      {value}
    </span>
  );
}
