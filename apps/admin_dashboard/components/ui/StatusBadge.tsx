interface StatusBadgeProps {
  value: string;
}

export function StatusBadge({ value }: StatusBadgeProps) {
  const normalized = value.toLowerCase();

  const tone =
    normalized === "searching"
      ? "bg-lilac/35 text-brand-700"
      : normalized === "assigned"
      ? "bg-lilac/50 text-brand-700"
      : normalized === "on the way"
      ? "bg-brand-100 text-brand-700"
      : normalized === "delivered" || normalized === "resolved" || normalized === "online"
      ? "bg-brand-50 text-brand-600"
      : normalized === "cancelled" || normalized === "rejected"
      ? "bg-brand-100/70 text-brand-700"
      : "bg-brand-50 text-brand-700";

  return (
    <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${tone}`}>
      {value}
    </span>
  );
}
