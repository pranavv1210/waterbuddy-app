import { useRouter } from "next/router";
import { SellerRecord } from "../../services/types";

interface SellersTableProps {
  sellers: SellerRecord[];
  activeFilter: "all" | "pending" | "inactive";
  onChangeFilter: (filter: "all" | "pending" | "inactive") => void;
  page: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  onToggleEnabled: (seller: SellerRecord) => Promise<void>;
  onApproveKyc: (seller: SellerRecord) => Promise<void>;
  onRejectKyc: (seller: SellerRecord) => Promise<void>;
}

function normalizeKycStatus(kycStatus: string): string {
  return kycStatus.trim().toLowerCase();
}

function getInitials(name: string): string {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part.charAt(0).toUpperCase())
    .join("");
}

function filterSellers(sellers: SellerRecord[], activeFilter: "all" | "pending" | "inactive") {
  if (activeFilter === "pending") {
    return sellers.filter((seller) => normalizeKycStatus(seller.kycStatus).includes("pending"));
  }
  if (activeFilter === "inactive") {
    return sellers.filter((seller) => !seller.enabled);
  }
  return sellers;
}

export function SellersTable({
  sellers,
  activeFilter,
  onChangeFilter,
  page,
  pageSize,
  onPageChange,
  onToggleEnabled,
  onApproveKyc,
  onRejectKyc,
}: SellersTableProps) {
  const router = useRouter();
  const filteredSellers = filterSellers(sellers, activeFilter);
  const totalPages = Math.max(1, Math.ceil(filteredSellers.length / pageSize));
  const safePage = Math.min(page, totalPages);
  const startIndex = (safePage - 1) * pageSize;
  const visibleSellers = filteredSellers.slice(startIndex, startIndex + pageSize);
  const pageNumbers = Array.from({ length: Math.min(3, totalPages) }, (_, index) => index + 1);

  const pendingCount = sellers.filter((seller) => normalizeKycStatus(seller.kycStatus).includes("pending")).length;
  const inactiveCount = sellers.filter((seller) => !seller.enabled).length;

  return (
    <div className="overflow-hidden rounded-3xl border border-lilac/10 bg-white shadow-sm">
      <div className="flex items-center justify-between bg-cream/60 p-6">
        <div className="flex gap-4">
          <button
            type="button"
            onClick={() => onChangeFilter("all")}
            className={`rounded-full px-6 py-2 text-sm font-semibold transition-colors ${
              activeFilter === "all"
                ? "bg-brand-500 text-white"
                : "text-brand-500 hover:bg-cream"
            }`}
          >
            All Sellers
          </button>
          <button
            type="button"
            onClick={() => onChangeFilter("pending")}
            className={`rounded-full px-6 py-2 text-sm font-semibold transition-colors ${
              activeFilter === "pending"
                ? "bg-lilac text-brand-700"
                : "text-brand-500 hover:bg-cream"
            }`}
          >
            Pending Approval ({pendingCount})
          </button>
          <button
            type="button"
            onClick={() => onChangeFilter("inactive")}
            className={`rounded-full px-6 py-2 text-sm font-semibold transition-colors ${
              activeFilter === "inactive"
                ? "bg-lilac text-brand-700"
                : "text-brand-500 hover:bg-cream"
            }`}
          >
            Inactive ({inactiveCount})
          </button>
        </div>

        <button
          type="button"
          className="flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-bold text-brand-600 transition-all hover:bg-lilac/30"
        >
          <span className="material-symbols-outlined text-lg">filter_list</span>
          Advanced Filters
        </button>
      </div>

      <table className="min-w-full border-collapse text-left">
        <thead className="bg-cream text-[11px] uppercase tracking-[0.15em] text-brand-400">
          <tr>
            <th className="px-8 py-5 font-bold">Seller Details</th>
            <th className="px-6 py-5 font-bold">KYC Status</th>
            <th className="px-6 py-5 font-bold">Platform Status</th>
            <th className="px-6 py-5 text-center font-bold">Avg Rating</th>
            <th className="px-8 py-5 text-right font-bold">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-lilac/20 text-sm">
          {visibleSellers.map((seller) => {
            const normalizedKyc = normalizeKycStatus(seller.kycStatus);
            const isPending = normalizedKyc.includes("pending");

            return (
              <tr key={seller.id} className="group transition-colors duration-200 hover:bg-cream/60">
                <td className="px-8 py-6">
                  <div className="flex items-center gap-4">
                    <div className="flex h-12 w-12 items-center justify-center overflow-hidden rounded-2xl bg-lilac/40 font-bold text-brand-700">
                      {getInitials(seller.name)}
                    </div>
                    <div>
                      <p className="text-base font-bold text-brand-600">{seller.name}</p>
                      <p className="text-sm text-brand-400">{seller.phone !== "-" ? seller.phone : seller.id}</p>
                    </div>
                  </div>
                </td>

                <td className="px-6 py-6">
                  <span
                    className={`inline-flex items-center gap-2 rounded-full px-4 py-1.5 text-xs font-bold ${
                      isPending ? "bg-lilac/40 text-brand-700" : "bg-cream text-brand-700"
                    }`}
                  >
                    <span
                      className={`h-2 w-2 rounded-full ${
                        isPending ? "bg-brand-500" : "bg-brand-600"
                      }`}
                    ></span>
                    {seller.kycStatus}
                  </span>
                </td>

                <td className="px-6 py-6">
                  <div className="flex items-center gap-3">
                    <button
                      type="button"
                      onClick={() => onToggleEnabled(seller)}
                      className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                        seller.enabled ? "bg-lilac" : "bg-cream"
                      }`}
                    >
                      <span
                        className={`inline-block h-4 w-4 transform rounded-full bg-white transition duration-200 ease-in-out ${
                          seller.enabled ? "translate-x-6" : "translate-x-1"
                        }`}
                      ></span>
                    </button>
                    <span className="text-sm font-semibold text-brand-500">
                      {seller.enabled ? "Online" : "Offline"}
                    </span>
                  </div>
                </td>

                <td className="px-6 py-6 text-center">
                  {typeof seller.rating === "number" ? (
                    <div className="flex items-center justify-center gap-1 text-brand-500">
                      <span className="material-symbols-outlined text-lg">star</span>
                      <span className="text-sm font-black text-brand-600">{seller.rating.toFixed(1)}</span>
                    </div>
                  ) : (
                    <div className="flex items-center justify-center gap-1 text-brand-300">
                      <span className="material-symbols-outlined text-lg">star</span>
                      <span className="text-sm font-black">N/A</span>
                    </div>
                  )}
                </td>

                <td className="px-8 py-6 text-right">
                  <div className="flex justify-end gap-3">
                    {isPending ? (
                      <>
                        <button
                          type="button"
                          onClick={() => onApproveKyc(seller)}
                          className="rounded-xl bg-brand-500 px-4 py-2 text-xs font-bold text-white transition-all hover:opacity-90"
                        >
                          Approve KYC
                        </button>
                        <button
                          type="button"
                          onClick={() => onRejectKyc(seller)}
                          className="rounded-xl border-2 border-brand-300 px-4 py-2 text-xs font-bold text-brand-600 transition-all hover:bg-brand-500 hover:text-white"
                        >
                          Reject
                        </button>
                      </>
                    ) : (
                      <button
                        type="button"
                        onClick={() => router.push(`/sellers?seller=${encodeURIComponent(seller.name)}`)}
                        className="rounded-xl border-2 border-brand-300 px-4 py-2 text-xs font-bold text-brand-600 transition-all hover:bg-brand-500 hover:text-white"
                      >
                        View Details
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>

      {visibleSellers.length === 0 ? (
        <div className="p-8 text-sm text-brand-400">No sellers found for this filter.</div>
      ) : null}

      <div className="flex items-center justify-between bg-cream/30 px-8 py-6">
        <p className="text-sm font-medium text-brand-400">
          Showing <span className="font-bold text-brand-600">{filteredSellers.length === 0 ? 0 : startIndex + 1}-{Math.min(startIndex + pageSize, filteredSellers.length)}</span> of <span className="font-bold text-brand-600">{filteredSellers.length}</span> sellers
        </p>

        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => onPageChange(Math.max(1, safePage - 1))}
            disabled={safePage === 1}
            className="rounded-lg bg-cream p-2 text-brand-500 transition-colors hover:bg-lilac/30 disabled:opacity-40"
          >
            <span className="material-symbols-outlined">chevron_left</span>
          </button>

          {pageNumbers.map((pageNumber) => (
            <button
              key={pageNumber}
              type="button"
              onClick={() => onPageChange(pageNumber)}
              className={`h-10 w-10 rounded-lg text-sm font-bold ${
                pageNumber === safePage
                  ? "bg-brand-500 text-white"
                  : "text-brand-500 hover:bg-cream"
              }`}
            >
              {pageNumber}
            </button>
          ))}

          <button
            type="button"
            onClick={() => onPageChange(Math.min(totalPages, safePage + 1))}
            disabled={safePage === totalPages}
            className="rounded-lg bg-cream p-2 text-brand-500 transition-colors hover:bg-lilac/30 disabled:opacity-40"
          >
            <span className="material-symbols-outlined">chevron_right</span>
          </button>
        </div>
      </div>
    </div>
  );
}
