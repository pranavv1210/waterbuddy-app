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
  const [hasNotification] = useState(true);
  const pageTitle = routeTitleMap[router.pathname] ?? "WaterBuddy Admin";
  const searchPlaceholder =
    routeSearchPlaceholderMap[router.pathname] ?? "Search orders, sellers, or customers...";

  const displayName = currentUser?.displayName || currentUser?.email?.split("@")[0] || "Signed-in Admin";
  const roleLabel = currentUser?.email ? "Super Admin" : "System Admin";
  const profileInitial = (displayName || "A").charAt(0).toUpperCase();

  return (
    <header className="sticky top-0 z-40 flex h-16 w-full items-center justify-between border-b border-outline-variant/20 bg-white/80 px-4 shadow-sm backdrop-blur-xl sm:px-6 lg:ml-64 lg:px-8">
      {/* Left Section - Title and Search */}
      <div className="flex flex-1 items-center gap-3 sm:gap-4 lg:gap-8">
        <button
          type="button"
          onClick={onToggleSidebar}
          className="inline-flex rounded-full p-2 text-primary transition-colors hover:bg-surface-container-low lg:hidden"
          aria-label="Toggle navigation menu"
        >
          <span className="material-symbols-outlined">menu</span>
        </button>
        <div className="hidden md:block text-lg font-black text-primary lg:text-xl">{pageTitle}</div>
        <div className="relative w-full max-w-xs sm:max-w-md">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-sm">
            search
          </span>
          <input
            className="w-full rounded-full border border-outline-variant/40 bg-surface-container-low py-2 pl-10 pr-4 text-sm outline-none transition-all placeholder:text-on-surface-variant/60 focus:border-secondary focus:ring-2 focus:ring-secondary/15"
            placeholder={searchPlaceholder}
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      {/* Right Section - Notifications and User */}
      <div className="flex items-center gap-1 sm:gap-2 lg:gap-4">
        {/* Notification Button */}
        <button className="relative rounded-full p-2 transition-colors hover:bg-surface-container-low">
          <span className="material-symbols-outlined text-primary">notifications</span>
          {hasNotification && (
            <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full animate-pulse"></span>
          )}
        </button>

        {/* Help Button */}
        <button className="rounded-full p-2 transition-colors hover:bg-surface-container-low">
          <span className="material-symbols-outlined text-primary">help_outline</span>
        </button>

        {/* Divider */}
        <div className="mx-1 hidden h-8 w-[1px] bg-outline-variant/30 sm:mx-2 sm:block"></div>

        {/* User Profile */}
        <div className="flex items-center gap-3">
          <div className="hidden text-right sm:block">
            <p className="text-sm font-bold text-primary">{displayName}</p>
            <p className="text-[10px] uppercase tracking-tighter text-on-surface-variant">{roleLabel}</p>
          </div>
          <div className="flex h-10 w-10 items-center justify-center rounded-full border-2 border-surface-container-low bg-secondary-container font-bold text-primary-container">
            {profileInitial}
          </div>
        </div>
      </div>
    </header>
  );
}
