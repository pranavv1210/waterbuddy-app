import { onAuthStateChanged } from "firebase/auth";
import { useEffect, useState } from "react";
import { useRouter } from "next/router";
import { auth } from "../../services/firebase/client";

const routeTitleMap: Record<string, string> = {
  "/": "WaterBuddy Admin",
  "/orders": "Orders Management",
  "/sellers": "Sellers Management",
  "/customers": "Customers Management",
  "/payments": "Payments Analytics",
  "/complaints": "Complaints Center",
};

const routeSearchPlaceholderMap: Record<string, string> = {
  "/": "Search orders, sellers, or customers...",
  "/orders": "Search orders, customers...",
  "/sellers": "Search sellers by name, ID or location...",
  "/customers": "Search customers by name or phone...",
  "/payments": "Search transactions or sellers...",
  "/complaints": "Search complaints by customer or status...",
};

export function Header() {
  const router = useRouter();
  const [searchQuery, setSearchQuery] = useState("");
  const [hasNotification] = useState(true);
  const [adminUser, setAdminUser] = useState<{ displayName?: string | null; email?: string | null } | null>(null);
  const pageTitle = routeTitleMap[router.pathname] ?? "WaterBuddy Admin";
  const searchPlaceholder =
    routeSearchPlaceholderMap[router.pathname] ?? "Search orders, sellers, or customers...";

  useEffect(() => {
    if (!auth) {
      return;
    }

    return onAuthStateChanged(auth, (nextUser: { displayName?: string | null; email?: string | null } | null) => {
      setAdminUser(nextUser);
    });
  }, []);

  const displayName = adminUser?.displayName || adminUser?.email?.split("@")[0] || "Signed-in Admin";
  const roleLabel = adminUser?.email ? "Admin" : "System Admin";
  const profileInitial = (displayName || "A").charAt(0).toUpperCase();

  return (
    <header className="sticky top-0 z-40 flex justify-between items-center px-8 w-full ml-64 bg-white/80 backdrop-blur-xl h-16 shadow-sm border-b border-lilac/20">
      {/* Left Section - Title and Search */}
      <div className="flex items-center gap-8 flex-1">
        <div className="hidden md:block text-xl font-black text-brand-600">{pageTitle}</div>
        <div className="relative w-full max-w-md">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-brand-400 text-sm">
            search
          </span>
          <input
            className="w-full bg-cream border border-lilac/20 rounded-full py-2 pl-10 pr-4 text-sm focus:ring-2 focus:ring-brand-500/20 focus:border-brand-400 placeholder-brand-300/60 outline-none transition-all"
            placeholder={searchPlaceholder}
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      {/* Right Section - Notifications and User */}
      <div className="flex items-center gap-4">
        {/* Notification Button */}
        <button className="hover:bg-cream rounded-full p-2 relative transition-colors">
          <span className="material-symbols-outlined text-brand-600">notifications</span>
          {hasNotification && (
            <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full animate-pulse"></span>
          )}
        </button>

        {/* Help Button */}
        <button className="hover:bg-cream rounded-full p-2 transition-colors">
          <span className="material-symbols-outlined text-brand-600">help_outline</span>
        </button>

        {/* Divider */}
        <div className="h-8 w-[1px] bg-lilac/30 mx-2"></div>

        {/* User Profile */}
        <div className="flex items-center gap-3">
          <div className="text-right hidden sm:block">
            <p className="text-sm font-bold text-brand-600">{displayName}</p>
            <p className="text-[10px] uppercase tracking-tighter text-brand-400">{roleLabel}</p>
          </div>
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-lilac border-2 border-cream font-bold text-brand-700">
            {profileInitial}
          </div>
        </div>
      </div>
    </header>
  );
}
