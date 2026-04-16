export interface DashboardSummary {
  activeOrders: number | null;
  onlineSellers: number | null;
  openComplaints: number | null;
}

export class DashboardRepository {
  async getSummary(): Promise<DashboardSummary> {
    return {
      activeOrders: null,
      onlineSellers: null,
      openComplaints: null,
    };
  }
}
