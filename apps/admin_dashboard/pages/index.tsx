import { DashboardHome } from "../modules/dashboard/DashboardHome";
import { DashboardRepository } from "../services/repositories/dashboardRepository";

interface HomePageProps {
  summary: Awaited<ReturnType<DashboardRepository["getSummary"]>>;
}

export default function HomePage({ summary }: HomePageProps) {
  return <DashboardHome summary={summary} />;
}

export async function getServerSideProps() {
  const repository = new DashboardRepository();
  const summary = await repository.getSummary();

  return {
    props: {
      summary,
    },
  };
}
