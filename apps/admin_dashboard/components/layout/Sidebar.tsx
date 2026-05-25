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
        className={`fixed inset-0 z-40 bg-slate-950/40 backdrop-blur-sm transition-opacity lg:hidden ${
          isOpen
            ? "pointer-events-auto opacity-100"
            : "pointer-events-none opacity-0"
        }`}
      />

      <aside
        className={`fixed left-0 top-0 z-50 flex h-full w-64 flex-col border-r border-sky-100 bg-white text-slate-950 shadow-xl transition-transform duration-300 lg:translate-x-0 ${
          isOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        {/* Branding */}
        <div className="px-6 py-8 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-sky-200 bg-sky-50 text-sky-600">
            <span
              className="material-symbols-outlined text-2xl"
              style={{ fontVariationSettings: "'FILL' 1" }}
            >
              water_drop
            </span>
          </div>
          <div>
            <div className="text-xl font-bold tracking-tight text-slate-950">
              WaterBuddy
            </div>
            <div className="text-[10px] font-medium uppercase tracking-wider text-sky-600">
              Admin Console
            </div>
          </div>
        </div>

        {/* New Dispatch Button */}
        <div className="mb-6 px-4">
          <button
            type="button"
            onClick={() => void navigateWithClose("/orders")}
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-sky-600 py-3 font-bold text-white shadow-sm transition-all hover:bg-sky-700"
          >
            <span className="material-symbols-outlined text-lg">
              add_circle
            </span>
            <span>New Dispatch</span>
          </button>
        </div>

        {/* Main Navigation */}
        <nav className="flex-1 space-y-1 px-3">
          {navigation.map((item) => {
            const isActive = router.pathname === item.href;
            return (
              <button
                key={item.href}
                type="button"
                onClick={() => void navigateWithClose(item.href)}
                className={`flex w-full items-center gap-3 rounded-xl px-4 py-3 text-left transition-all duration-200 ${
                  isActive
                    ? "border border-sky-200 bg-sky-50 text-sky-700"
                    : "border border-transparent text-slate-600 hover:bg-slate-50 hover:text-slate-950"
                }`}
              >
                <span
                  className="material-symbols-outlined text-xl"
                  style={isActive ? { fontVariationSettings: "'FILL' 1" } : {}}
                >
                  {item.icon}
                </span>
                <span
                  className={`text-xs uppercase tracking-wider ${isActive ? "font-bold" : "font-medium"}`}
                >
                  {item.label}
                </span>
              </button>
            );
          })}
        </nav>

        {/* Secondary Navigation */}
        <div className="space-y-1 border-t border-sky-100 px-3 pb-6 pt-4">
          {secondaryNav.map((item) => (
            <button
              key={item.href}
              type="button"
              onClick={() => void navigateWithClose(item.href)}
              className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-left text-slate-600 transition-colors duration-200 hover:bg-slate-50 hover:text-slate-950"
            >
              <span className="material-symbols-outlined text-xl">
                {item.icon}
              </span>
              <span className="text-xs font-medium uppercase tracking-wider">
                {item.label}
              </span>
            </button>
          ))}
          <button
            type="button"
            onClick={handleLogout}
            className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-left text-slate-600 transition-colors duration-200 hover:bg-red-50 hover:text-red-600"
          >
            <span className="material-symbols-outlined text-xl">logout</span>
            <span className="text-xs font-medium uppercase tracking-wider">
              Logout
            </span>
          </button>
        </div>
      </aside>
    </>
  );
}
