import { AppShell } from "../components/layout/AppShell";
import { MetricCard } from "../components/cards/MetricCard";
import { RecentLiveOrders } from "../components/cards/RecentLiveOrders";
import { OrderTrends } from "../components/charts/OrderTrends";
import { ErrorState } from "../components/ui/ErrorState";
import { LoadingState } from "../components/ui/LoadingState";
import { useComplaints } from "../hooks/useComplaints";
import { useOrders } from "../hooks/useOrders";
import { useSellers } from "../hooks/useSellers";
import { usePayments } from "../hooks/usePayments";

export default function HomePage() {
  const { orders, loading: ordersLoading, error: ordersError } = useOrders("all");
  const { sellers, loading: sellersLoading, error: sellersError } = useSellers();
  const { complaints, loading: complaintsLoading } = useComplaints();
  const { dashboard, loading: paymentsLoading } = usePayments();

  const loading = ordersLoading || sellersLoading || complaintsLoading || paymentsLoading;
  const error = ordersError || sellersError;

  const onlineSellersCount = sellers.filter((seller) => seller.onlineStatus).length;
  const activeOrdersCount = orders.filter((o) => o.status === "in_progress" || o.status === "assigned").length;
  const totalRevenue = dashboard.summary.totalRevenue || 0;
  const verifiedSellersPercent = sellers.length > 0 ? Math.round((sellers.filter((s) => s.kycStatus === "verified").length / sellers.length) * 100) : 0;

  return (
    <AppShell>
      <div className="space-y-8">
        {/* Page Header */}
        <div className="mb-10">
          <h1 className="text-3xl font-extrabold text-brand-600 tracking-tight mb-1">Overview</h1>
          <p className="text-brand-400 font-medium">Monitoring real-time liquidity and delivery performance.</p>
        </div>

        {loading ? <LoadingState /> : null}
        {error ? <ErrorState message={error} /> : null}

        {!loading && !error ? (
          <>
            {/* Metrics Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <MetricCard
                title="Total Orders"
                value={String(orders.length)}
                icon="inventory_2"
                trend={{ value: "+12%", direction: "up" }}
              />
              <MetricCard
                title="Active Orders"
                value={String(activeOrdersCount)}
                icon="local_shipping"
                isLive={true}
              />
              <MetricCard
                title="Total Revenue"
                value={`₹${(totalRevenue / 100000).toFixed(1)}L`}
                icon="payments"
                trend={{ value: "+8.4%", direction: "up" }}
              />
              <MetricCard
                title="Active Sellers"
                value={String(onlineSellersCount)}
                icon="storefront"
                subtitle={`${verifiedSellersPercent}% verified`}
              />
            </div>

            {/* Charts and Orders Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              <div className="lg:col-span-2">
                <OrderTrends orders={orders} />
              </div>
              <RecentLiveOrders orders={orders} />
            </div>
          </>
        ) : null}
      </div>
    </AppShell>
  );
}
