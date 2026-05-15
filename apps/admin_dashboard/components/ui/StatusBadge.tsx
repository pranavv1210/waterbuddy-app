interface StatusBadgeProps {
  value: string;
}

export function StatusBadge({ value }: StatusBadgeProps) {
  const normalized = value.toLowerCase();

  const styles =
    normalized === "searching"
      ? "bg-blue-500/10 text-blue-400 border-blue-500/20"
      : normalized === "assigned"
      ? "bg-purple-500/10 text-purple-400 border-purple-500/20"
      : normalized === "on the way"
      ? "bg-amber-500/10 text-amber-400 border-amber-500/20"
      : normalized === "delivered" || normalized === "resolved" || normalized === "online" || normalized === "completed" || normalized === "approved" || normalized === "active"
      ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
      : normalized === "cancelled" || normalized === "rejected" || normalized === "blocked" || normalized === "critical"
      ? "bg-red-500/10 text-red-400 border-red-500/20"
      : "bg-white/5 text-white/40 border-white/10";

  return (
    <span className={`inline-flex items-center gap-1.5 rounded-lg border px-2.5 py-1 text-[10px] font-black uppercase tracking-widest ${styles}`}>
      <span className="h-1 w-1 rounded-full bg-current"></span>
      {value}
    </span>
  );
}
