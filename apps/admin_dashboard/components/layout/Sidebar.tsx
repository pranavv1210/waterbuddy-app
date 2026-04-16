import { useRouter } from "next/router";
import { useAdminAuth } from "../auth/AdminAuthProvider";

const navigation = [
  { href: "/", icon: "dashboard", label: "Overview" },
  { href: "/orders", icon: "shopping_cart", label: "Orders" },
  { href: "/sellers", icon: "storefront", label: "Sellers" },
  { href: "/payments", icon: "payments", label: "Payments" },
  { href: "/customers", icon: "group", label: "Customers" },
  { href: "/complaints", icon: "report_problem", label: "Complaints" },
];

const secondaryNav = [
  { href: "/settings", icon: "settings", label: "Settings" },
];

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export function Sidebar({ isOpen, onClose }: SidebarProps) {
  const router = useRouter();
  const { signOut } = useAdminAuth();

  const navigateWithClose = async (href: string) => {
    await router.push(href);
    onClose();
  };

  const handleLogout = async () => {
    await signOut();
    onClose();
    await router.replace("/login");
  };

  return (
    <>
      <button
        type="button"
        aria-hidden={!isOpen}
        onClick={onClose}
        className={`fixed inset-0 z-40 bg-black/35 transition-opacity lg:hidden ${
          isOpen ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
        }`}
      />

      <aside
        className={`fixed left-0 top-0 z-50 flex h-full w-64 flex-col bg-primary-container text-white transition-transform duration-300 lg:translate-x-0 ${
          isOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        {/* Branding */}
        <div className="px-6 py-8">
          <div className="mb-1 text-2xl font-bold tracking-tight">WaterBuddy</div>
          <div className="text-xs font-medium uppercase tracking-wider text-secondary-container/90">Admin Console</div>
        </div>

        {/* New Dispatch Button */}
        <div className="mb-6 px-4">
          <button
            type="button"
            onClick={() => void navigateWithClose("/orders")}
            className="flex w-full items-center justify-center gap-2 rounded-lg bg-secondary-container py-3 font-bold text-primary-container transition-all hover:opacity-90"
          >
            <span className="material-symbols-outlined text-lg">add_circle</span>
            <span>New Dispatch</span>
          </button>
        </div>

        {/* Main Navigation */}
        <nav className="flex-1 space-y-1 px-2">
          {navigation.map((item) => {
            const isActive = router.pathname === item.href;
            return (
              <button
                key={item.href}
                type="button"
                onClick={() => void navigateWithClose(item.href)}
                className={`flex w-full items-center gap-3 rounded-lg px-4 py-3 text-left transition-all duration-200 ${
                  isActive
                    ? "border-l-4 border-secondary-container bg-secondary-container font-bold text-primary-container"
                    : "text-white/80 hover:bg-white/10 hover:text-white"
                }`}
              >
                <span className="material-symbols-outlined text-lg">{item.icon}</span>
                <span className="text-xs font-medium uppercase tracking-wide">{item.label}</span>
              </button>
            );
          })}
        </nav>

        {/* Secondary Navigation */}
        <div className="border-t border-white/10 px-2 pb-6 pt-4">
          {secondaryNav.map((item) => (
            <button
              key={item.href}
              type="button"
              onClick={() => void navigateWithClose(item.href)}
              className="flex w-full items-center gap-3 rounded-lg px-4 py-3 text-left text-white/80 transition-colors duration-200 hover:bg-white/10 hover:text-white"
            >
              <span className="material-symbols-outlined text-lg">{item.icon}</span>
              <span className="text-xs font-medium uppercase tracking-wide">{item.label}</span>
            </button>
          ))}
          <button
            type="button"
            onClick={handleLogout}
            className="flex w-full items-center gap-3 rounded-lg px-4 py-3 text-left text-white/80 transition-colors duration-200 hover:bg-white/10 hover:text-white"
          >
            <span className="material-symbols-outlined text-lg">logout</span>
            <span className="text-xs font-medium uppercase tracking-wide">Logout</span>
          </button>
        </div>
      </aside>
    </>
  );
}
