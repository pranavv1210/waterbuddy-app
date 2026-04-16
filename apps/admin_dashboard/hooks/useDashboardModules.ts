export interface DashboardModuleState {
  title: string;
  description: string;
}

export function useDashboardModules(): DashboardModuleState[] {
  return [
    {
      title: "Live data integration",
      description: "Connect repository-backed metrics and tables for this module.",
    },
  ];
}
