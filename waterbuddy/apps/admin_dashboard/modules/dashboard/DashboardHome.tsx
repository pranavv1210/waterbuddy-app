import { AppShell } from "../../components/layout/AppShell";
import { ModuleCard } from "../../components/ui/ModuleCard";
import { DashboardRepository } from "../../services/repositories/dashboardRepository";

interface DashboardHomeProps {
  summary: Awaited<ReturnType<DashboardRepository["getSummary"]>>;
}

export function DashboardHome({ summary }: DashboardHomeProps) {
  return (
    <AppShell>
      <ModuleCard
        title="System Summary"
        description={`Active orders: ${summary.activeOrders ?? "pending"}, online sellers: ${summary.onlineSellers ?? "pending"}, open complaints: ${summary.openComplaints ?? "pending"}.`}
      />
    </AppShell>
  );
}
