import { useState } from "react";
import { useRouter } from "next/router";
import { useAdminAuth } from "../auth/AdminAuthProvider";

interface HeaderProps {
  onToggleSidebar: () => void;
}

const routeTitleMap: Record<string, string> = {
  "/": "WaterBuddy Admin",
  "/orders": "Orders Management",
  "/sellers": "Sellers Management",
  "/customers": "Customers Management",
  "/payments": "Payments Analytics",
  "/complaints": "Complaints Center",
  "/settings": "Settings",
};

const routeSearchPlaceholderMap: Record<string, string> = {
  "/": "Search orders, sellers, or customers...",
  "/orders": "Search orders, customers...",
  "/sellers": "Search sellers by name, ID or location...",
  "/customers": "Search customers by name or phone...",
  "/payments": "Search transactions or sellers...",
  "/complaints": "Search complaints by customer or status...",
};

export function Header({ onToggleSidebar }: HeaderProps) {
  const router = useRouter();
  const { currentUser } = useAdminAuth();
  const [searchQuery, setSearchQuery] = useState("");
  const pageTitle = routeTitleMap[router.pathname] ?? "WaterBuddy Admin";
  const searchPlaceholder =
    routeSearchPlaceholderMap[router.pathname] ??
    "Search orders, sellers, or customers...";

  const displayName =
    currentUser?.displayName ||
    currentUser?.email?.split("@")[0] ||
    "Signed-in Admin";
  const roleLabel = currentUser?.email ? "Super Admin" : "System Admin";
  const profileInitial = (displayName || "A").charAt(0).toUpperCase();

  return (
    <header className="sticky top-0 z-40 flex min-h-16 w-full items-center justify-between gap-3 border-b border-sky-100 bg-white/95 px-4 shadow-sm backdrop-blur-xl sm:px-6 lg:px-8">
      <div className="flex min-w-0 flex-1 items-center gap-3 sm:gap-4 lg:gap-8">
        <button
          type="button"
          onClick={onToggleSidebar}
          className="inline-flex rounded-full p-2 text-slate-700 transition-colors hover:bg-sky-50 lg:hidden"
          aria-label="Toggle navigation menu"
        >
          <span className="material-symbols-outlined">menu</span>
        </button>
        <div className="hidden shrink-0 text-lg font-bold text-slate-950 md:block lg:text-xl">
          {pageTitle}
        </div>
        <div className="relative hidden w-full max-w-xs sm:block sm:max-w-md">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-sm">
            search
          </span>
          <input
            className="w-full rounded-full border border-sky-100 bg-sky-50 py-2 pl-10 pr-4 text-sm text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-sky-300 focus:bg-white focus:ring-2 focus:ring-sky-100"
            placeholder={searchPlaceholder}
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      <div className="flex shrink-0 items-center gap-3">
        <div className="flex items-center gap-3 rounded-full border border-sky-100 bg-sky-50 px-2 py-1">
          <div className="hidden text-right sm:block">
            <p className="text-sm font-bold text-slate-950">{displayName}</p>
            <p className="text-[10px] uppercase tracking-wider text-sky-600">
              {roleLabel}
            </p>
          </div>
          <div className="flex h-10 w-10 items-center justify-center rounded-full border border-sky-200 bg-white font-bold text-sky-700">
            {profileInitial}
          </div>
        </div>
      </div>
    </header>
  );
}
