import { useState } from "react";

import { AppShell } from "../components/layout/AppShell";
import { SellersTable } from "../components/tables/SellersTable";
import { ErrorState } from "../components/ui/ErrorState";
import { LoadingState } from "../components/ui/LoadingState";
import { useSellers } from "../hooks/useSellers";
import { SellerRecord } from "../services/types";

export default function SellersPage() {
  const {
    sellers,
    loading,
    error,
    toggleSellerEnabled,
    approveSellerKyc,
    rejectSellerKyc,
  } = useSellers();
  const [actionError, setActionError] = useState<string | null>(null);
  const [activeFilter, setActiveFilter] = useState<
    "all" | "pending" | "inactive"
  >("all");
  const [page, setPage] = useState(1);

  const handleToggleEnabled = async (seller: SellerRecord) => {
    setActionError(null);
    try {
      await toggleSellerEnabled(seller);
    } catch (toggleError) {
      const message =
        toggleError instanceof Error
          ? toggleError.message
          : "Unable to update seller.";
      setActionError(message);
    }
  };

  const handleApproveKyc = async (seller: SellerRecord) => {
    setActionError(null);
    try {
      await approveSellerKyc(seller);
    } catch (approveError) {
      const message =
        approveError instanceof Error
          ? approveError.message
          : "Unable to approve KYC.";
      setActionError(message);
    }
  };

  const handleRejectKyc = async (seller: SellerRecord) => {
    setActionError(null);
    try {
      await rejectSellerKyc(seller);
    } catch (rejectError) {
      const message =
        rejectError instanceof Error
          ? rejectError.message
          : "Unable to reject KYC.";
      setActionError(message);
    }
  };

  const activeSellersCount = sellers.filter((seller) => seller.enabled).length;
  const pendingKycCount = sellers.filter((seller) =>
    seller.kycStatus.toLowerCase().includes("pending"),
  ).length;
  const approvedCount = sellers.filter((seller) =>
    seller.kycStatus.toLowerCase().includes("approved"),
  ).length;
  const growthPercent =
    sellers.length === 0 ? 0 : (approvedCount / sellers.length) * 100;

  return (
    <AppShell>
      <section className="space-y-10">
        <div className="flex flex-col items-end gap-6 lg:flex-row">
          <div className="flex-1">
            <nav className="mb-2 flex gap-2 text-[10px] font-bold uppercase tracking-[0.2em] text-[#14B8A6]">
              <span>Management</span>
              <span className="text-white/20">/</span>
              <span className="text-white/60">Seller Network</span>
            </nav>
            <h2 className="text-4xl font-extrabold leading-tight text-white tracking-tight">
              Seller Management
            </h2>
            <p className="mt-2 max-w-xl text-white/40 font-medium">
              Oversee your water distribution partners, monitor compliance, and
              manage service availability across the network.
            </p>
          </div>

          <div className="flex gap-4">
            <div className="flex min-w-[180px] items-center gap-4 rounded-2xl bg-white/5 border border-white/5 p-5 backdrop-blur-xl">
              <div className="rounded-xl bg-[#14B8A6]/20 p-3 text-[#14B8A6]">
                <span
                  className="material-symbols-outlined text-2xl"
                  style={{ fontVariationSettings: "'FILL' 1" }}
                >
                  storefront
                </span>
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-white/40">
                  Active Sellers
                </p>
                <p className="text-2xl font-black text-white">
                  {activeSellersCount}
                </p>
              </div>
            </div>

            <div className="flex min-w-[180px] items-center gap-4 rounded-2xl bg-white/5 border border-white/5 p-5 backdrop-blur-xl">
              <div className="rounded-xl bg-amber-500/20 p-3 text-amber-400">
                <span
                  className="material-symbols-outlined text-2xl"
                  style={{ fontVariationSettings: "'FILL' 1" }}
                >
                  verified_user
                </span>
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-white/40">
                  Pending KYC
                </p>
                <p className="text-2xl font-black text-white">
                  {pendingKycCount}
                </p>
              </div>
            </div>
          </div>
        </div>

        {loading ? <LoadingState /> : null}
        {error ? <ErrorState message={error} /> : null}
        {actionError ? <ErrorState message={actionError} /> : null}

        {!loading && !error ? (
          <div className="space-y-10">
            <SellersTable
              sellers={sellers}
              activeFilter={activeFilter}
              onChangeFilter={(filter) => {
                setActiveFilter(filter);
                setPage(1);
              }}
              page={page}
              pageSize={8}
              onPageChange={setPage}
              onToggleEnabled={handleToggleEnabled}
              onApproveKyc={handleApproveKyc}
              onRejectKyc={handleRejectKyc}
            />

            <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
              <div className="relative overflow-hidden rounded-3xl bg-[#0D1117]/60 border border-white/5 p-8 text-white md:col-span-2 shadow-xl backdrop-blur-xl group">
                <div className="relative z-10">
                  <h3 className="mb-1 text-xl font-bold tracking-tight">
                    Growth Forecast
                  </h3>
                  <p className="mb-8 text-sm text-white/40 font-medium">
                    Estimated {growthPercent.toFixed(0)}% seller approval
                    strength based on compliance trends.
                  </p>
                  <div className="flex items-end gap-3 h-32">
                    {[45, 60, 55, 80, 75, 95].map((h, i) => (
                      <div key={i} className="relative flex-1 group/bar">
                        <div
                          className="w-full rounded-t-xl bg-[#14B8A6]/20 transition-all duration-500 group-hover:bg-[#14B8A6]/40"
                          style={{ height: `${h}%` }}
                        ></div>
                        {i === 5 && (
                          <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-6 opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap bg-white text-black text-[10px] font-bold px-2 py-1 rounded">
                            +12% Forecast
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
                <div className="absolute -right-20 -top-20 h-64 w-64 rounded-full bg-[#14B8A6]/5 blur-3xl group-hover:bg-[#14B8A6]/10 transition-colors"></div>
              </div>

              <div className="flex flex-col justify-between rounded-3xl bg-[#14B8A6] p-8 text-white shadow-[0_0_30px_rgba(20,184,166,0.2)]">
                <div>
                  <div className="bg-white/20 w-12 h-12 rounded-2xl flex items-center justify-center mb-6">
                    <span className="material-symbols-outlined text-2xl">
                      map
                    </span>
                  </div>
                  <h3 className="mb-2 text-xl font-extrabold tracking-tight">
                    Expansion Target
                  </h3>
                  <p className="text-sm font-medium text-white/80 leading-relaxed">
                    New seller clusters identified in high-demand zones from
                    recent order flow.
                  </p>
                </div>
              </div>
            </div>
          </div>
        ) : null}
      </section>
    </AppShell>
  );
}
