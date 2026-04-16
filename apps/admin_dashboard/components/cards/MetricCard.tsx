interface MetricCardProps {
  title: string;
  value: string;
  subtitle?: string;
  icon?: string;
  trend?: { value: string; direction: "up" | "down" };
  isLive?: boolean;
}

export function MetricCard({
  title,
  value,
  subtitle,
  icon = "inventory_2",
  trend,
  isLive = false,
}: MetricCardProps) {
  return (
    <div className="bg-white rounded-xl border border-lilac/10 shadow-sm p-6 flex items-start justify-between">
      <div className="flex-1">
        {/* Label */}
        <p className="text-xs font-bold text-brand-400 uppercase tracking-widest mb-1">{title}</p>

        {/* Value */}
        <h3 className="text-3xl font-extrabold text-brand-600 mb-2">{value}</h3>

        {/* Subtitle or Trend */}
        {isLive ? (
          <div className="flex items-center gap-1 text-lilac text-xs font-bold">
            <span className="relative flex h-2 w-2 mr-1">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-lilac opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-lilac"></span>
            </span>
            <span>Live now</span>
          </div>
        ) : trend ? (
          <div className={`flex items-center gap-1 text-xs font-bold ${trend.direction === "up" ? "text-green-600" : "text-red-600"} bg-${trend.direction === "up" ? "green" : "red"}-50 px-2 py-0.5 rounded-full w-fit`}>
            <span className="material-symbols-outlined text-xs">
              {trend.direction === "up" ? "trending_up" : "trending_down"}
            </span>
            <span>{trend.value}</span>
          </div>
        ) : subtitle ? (
          <p className="text-xs text-brand-400 font-medium">{subtitle}</p>
        ) : null}
      </div>

      {/* Icon */}
      {icon && (
        <div className="bg-lilac/20 w-12 h-12 rounded-xl flex items-center justify-center text-brand-600 shrink-0">
          <span className="material-symbols-outlined text-2xl">{icon}</span>
        </div>
      )}
    </div>
  );
}
