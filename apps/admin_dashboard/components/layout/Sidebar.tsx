import Link from "next/link";
import { useRouter } from "next/router";

const navigation = [
  { href: "/", icon: "dashboard", label: "Overview" },
  { href: "/orders", icon: "shopping_cart", label: "Orders" },
  { href: "/sellers", icon: "storefront", label: "Sellers" },
  { href: "/payments", icon: "payments", label: "Payments" },
  { href: "/customers", icon: "group", label: "Customers" },
  { href: "/complaints", icon: "report_problem", label: "Complaints" },
];

const secondaryNav = [
  { href: "/customers", icon: "settings", label: "Settings" },
  { href: "/", icon: "logout", label: "Logout" },
];

export function Sidebar() {
  const router = useRouter();

  return (
    <aside className="fixed left-0 top-0 h-full w-64 flex flex-col bg-gradient-to-b from-brand-500 to-brand-600 text-white z-50">
      {/* Branding */}
      <div className="px-6 py-8">
        <div className="text-2xl font-bold tracking-tight mb-1">WaterBuddy</div>
        <div className="text-xs font-medium text-brand-100 tracking-wider uppercase">Admin Console</div>
      </div>

      {/* New Dispatch Button */}
      <div className="px-4 mb-6">
        <Link
          href="/orders"
          className="flex w-full items-center justify-center gap-2 rounded-lg bg-lilac py-3 font-bold text-brand-600 transition-all hover:opacity-90"
        >
          <span className="material-symbols-outlined text-lg">add_circle</span>
          <span>New Dispatch</span>
        </Link>
      </div>

      {/* Main Navigation */}
      <nav className="flex-1 space-y-1 px-2">
        {navigation.map((item) => {
          const isActive = router.pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 rounded-lg px-4 py-3 transition-all duration-200 ${
                isActive
                  ? "bg-lilac text-brand-600 font-bold border-l-4 border-brand-400"
                  : "text-white/80 hover:text-white hover:bg-white/10"
              }`}
            >
              <span className="material-symbols-outlined text-lg">{item.icon}</span>
              <span className="text-xs font-medium tracking-wide uppercase">{item.label}</span>
            </Link>
          );
        })}
      </nav>

      {/* Secondary Navigation */}
      <div className="pb-6 border-t border-white/10 pt-4 px-2">
        {secondaryNav.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            prefetch={false}
            className="flex items-center gap-3 text-white/80 hover:text-white px-4 py-3 rounded-lg hover:bg-white/10 transition-colors duration-200"
          >
            <span className="material-symbols-outlined text-lg">{item.icon}</span>
            <span className="text-xs font-medium tracking-wide uppercase">{item.label}</span>
          </Link>
        ))}
      </div>
    </aside>
  );
}
