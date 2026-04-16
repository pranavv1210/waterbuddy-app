import { useState } from "react";

import { AppShell } from "../components/layout/AppShell";
import { SellersTable } from "../components/tables/SellersTable";
import { ErrorState } from "../components/ui/ErrorState";
import { LoadingState } from "../components/ui/LoadingState";
import { useSellers } from "../hooks/useSellers";
import { SellerRecord } from "../services/types";

export default function SellersPage() {
  const { sellers, loading, error, toggleSellerEnabled, approveSellerKyc, rejectSellerKyc } = useSellers();
  const [actionError, setActionError] = useState<string | null>(null);
  const [activeFilter, setActiveFilter] = useState<"all" | "pending" | "inactive">("all");
  const [page, setPage] = useState(1);

  const handleToggleEnabled = async (seller: SellerRecord) => {
    setActionError(null);
    try {
      await toggleSellerEnabled(seller);
    } catch (toggleError) {
      const message = toggleError instanceof Error ? toggleError.message : "Unable to update seller.";
      setActionError(message);
    }
  };

  const handleApproveKyc = async (seller: SellerRecord) => {
    setActionError(null);
    try {
      await approveSellerKyc(seller);
    } catch (approveError) {
      const message = approveError instanceof Error ? approveError.message : "Unable to approve KYC.";
      setActionError(message);
    }
  };

  const handleRejectKyc = async (seller: SellerRecord) => {
    setActionError(null);
    try {
      await rejectSellerKyc(seller);
    } catch (rejectError) {
      const message = rejectError instanceof Error ? rejectError.message : "Unable to reject KYC.";
      setActionError(message);
    }
  };

  const activeSellersCount = sellers.filter((seller) => seller.enabled).length;
  const pendingKycCount = sellers.filter((seller) => seller.kycStatus.toLowerCase().includes("pending")).length;
  const approvedCount = sellers.filter((seller) => seller.kycStatus.toLowerCase().includes("approved")).length;
  const growthPercent = sellers.length === 0 ? 0 : (approvedCount / sellers.length) * 100;

  return (
    <AppShell>
      <section className="space-y-8">
        <div className="flex flex-col items-end gap-6 lg:flex-row">
          <div className="flex-1">
            <nav className="mb-2 flex gap-2 text-xs font-semibold uppercase tracking-widest text-brand-300">
              <span>Management</span>
              <span>/</span>
              <span className="text-lilac">Seller Network</span>
            </nav>
            <h2 className="text-4xl font-extrabold leading-tight text-brand-600">Seller Management</h2>
            <p className="mt-2 max-w-xl text-brand-400">
              Oversee your water distribution partners, monitor compliance, and manage service availability across the network.
            </p>
          </div>

          <div className="flex gap-4">
            <div className="flex min-w-[200px] items-center gap-4 rounded-2xl bg-white p-5">
              <div className="rounded-xl bg-lilac/30 p-3">
                <span className="material-symbols-outlined text-brand-600">storefront</span>
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-brand-400">Active Sellers</p>
                <p className="text-2xl font-black text-brand-600">{activeSellersCount}</p>
              </div>
            </div>

            <div className="flex min-w-[200px] items-center gap-4 rounded-2xl bg-white p-5">
              <div className="rounded-xl bg-cream p-3">
                <span className="material-symbols-outlined text-brand-500">verified_user</span>
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-brand-400">Pending KYC</p>
                <p className="text-2xl font-black text-brand-500">{pendingKycCount}</p>
              </div>
            </div>
          </div>
        </div>

        {loading ? <LoadingState /> : null}
        {error ? <ErrorState message={error} /> : null}
        {actionError ? <ErrorState message={actionError} /> : null}

        {!loading && !error ? (
          <SellersTable
            sellers={sellers}
            activeFilter={activeFilter}
            onChangeFilter={(filter) => {
              setActiveFilter(filter);
              setPage(1);
            }}
            page={page}
            pageSize={10}
            onPageChange={setPage}
            onToggleEnabled={handleToggleEnabled}
            onApproveKyc={handleApproveKyc}
            onRejectKyc={handleRejectKyc}
          />
        ) : null}

        {!loading && !error ? (
          <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
            <div className="relative overflow-hidden rounded-3xl bg-brand-500 p-6 text-white md:col-span-2">
              <div className="relative z-10">
                <h3 className="mb-1 text-xl font-bold">Growth Forecast</h3>
                <p className="mb-6 text-sm text-lilac">
                  Estimated {growthPercent.toFixed(0)}% seller approval strength based on current compliance trend.
                </p>
                <div className="flex items-end gap-4">
                  <div className="relative h-32 w-full overflow-hidden rounded-2xl bg-white/10">
                    <div className="absolute bottom-0 left-0 h-[55%] w-full rounded-t-xl bg-lilac"></div>
                  </div>
                  <div className="relative h-32 w-full overflow-hidden rounded-2xl bg-white/10">
                    <div className="absolute bottom-0 left-0 h-[65%] w-full rounded-t-xl bg-lilac"></div>
                  </div>
                  <div className="relative h-32 w-full overflow-hidden rounded-2xl bg-white/10">
                    <div className="absolute bottom-0 left-0 h-[80%] w-full rounded-t-xl bg-lilac"></div>
                  </div>
                  <div className="relative h-32 w-full overflow-hidden rounded-2xl bg-white/10">
                    <div className="absolute bottom-0 left-0 h-[92%] w-full rounded-t-xl border-t-2 border-dashed border-white bg-lilac/40"></div>
                  </div>
                </div>
              </div>
              <div className="absolute -right-8 -top-8 h-48 w-48 rounded-full bg-white/5 blur-3xl"></div>
            </div>

            <div className="flex flex-col justify-between rounded-3xl bg-lilac p-6 text-brand-700">
              <div>
                <span className="material-symbols-outlined mb-4 text-4xl">map</span>
                <h3 className="mb-1 text-xl font-black leading-tight">Expansion Target</h3>
                <p className="text-sm font-medium text-brand-600/80">
                  New seller clusters identified in high-demand zones from recent order flow.
                </p>
              </div>
              <button
                type="button"
                className="mt-6 flex w-full items-center justify-center gap-2 rounded-xl bg-brand-500 py-3 font-bold text-white"
              >
                View Map
                <span className="material-symbols-outlined text-lg">arrow_right_alt</span>
              </button>
            </div>
          </div>
        ) : null}
      </section>
    </AppShell>
  );
}
