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
    <div className="bg-[#0D1117]/60 backdrop-blur-xl rounded-2xl border border-white/5 shadow-lg p-6 flex items-start justify-between hover:bg-white/5 transition-colors">
      <div className="flex-1">
        {/* Label */}
        <p className="text-xs font-bold text-[#14B8A6] uppercase tracking-widest mb-1">{title}</p>

        {/* Value */}
        <h3 className="text-3xl font-extrabold text-white mb-2">{value}</h3>

        {/* Subtitle or Trend */}
        {isLive ? (
          <div className="flex items-center gap-1 text-red-400 text-xs font-bold">
            <span className="relative flex h-2 w-2 mr-1">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-red-400"></span>
            </span>
            <span>Live now</span>
          </div>
        ) : trend ? (
          <div className={`flex items-center gap-1 text-xs font-bold ${trend.direction === "up" ? "text-green-400" : "text-red-400"} bg-${trend.direction === "up" ? "green" : "red"}-500/10 px-2 py-0.5 rounded-full w-fit`}>
            <span className="material-symbols-outlined text-xs">
              {trend.direction === "up" ? "trending_up" : "trending_down"}
            </span>
            <span>{trend.value}</span>
          </div>
        ) : subtitle ? (
          <p className="text-xs text-white/60 font-medium">{subtitle}</p>
        ) : null}
      </div>

      {/* Icon */}
      {icon && (
        <div className="bg-[#0F766E]/20 w-12 h-12 rounded-xl flex items-center justify-center text-[#14B8A6] shrink-0 border border-[#14B8A6]/10">
          <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>{icon}</span>
        </div>
      )}
    </div>
  );
}
