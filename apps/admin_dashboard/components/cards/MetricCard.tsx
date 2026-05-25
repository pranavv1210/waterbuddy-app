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
    <div className="flex items-start justify-between rounded-2xl border border-sky-100 bg-white p-4 shadow-sm transition-colors hover:border-sky-200 sm:p-5">
      <div className="flex-1">
        {/* Label */}
        <p className="mb-1 text-[10px] font-bold uppercase tracking-widest text-sky-600">
          {title}
        </p>

        {/* Value */}
        <h3 className="mb-2 text-2xl font-extrabold text-slate-950 lg:text-3xl">{value}</h3>

        {/* Subtitle or Trend */}
        {isLive ? (
          <div className="flex items-center gap-1 text-xs font-bold text-red-400">
            <span className="relative flex h-2 w-2 mr-1">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-red-400"></span>
            </span>
            <span>Live now</span>
          </div>
        ) : trend ? (
          <div
            className={`flex w-fit items-center gap-1 rounded-full px-2 py-0.5 text-xs font-bold ${trend.direction === "up" ? "text-green-400" : "text-red-400"} bg-${trend.direction === "up" ? "green" : "red"}-500/10`}
          >
            <span className="material-symbols-outlined text-xs">
              {trend.direction === "up" ? "trending_up" : "trending_down"}
            </span>
            <span>{trend.value}</span>
          </div>
        ) : subtitle ? (
          <p className="text-xs font-medium text-slate-500">{subtitle}</p>
        ) : null}
      </div>

      {/* Icon */}
      {icon && (
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-sky-100 bg-sky-50 text-sky-600 sm:h-12 sm:w-12">
          <span
            className="material-symbols-outlined text-2xl"
            style={{ fontVariationSettings: "'FILL' 1" }}
          >
            {icon}
          </span>
        </div>
      )}
    </div>
  );
}
