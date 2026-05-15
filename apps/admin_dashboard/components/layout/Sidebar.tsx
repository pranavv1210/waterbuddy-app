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
        className={`fixed inset-0 z-40 bg-black/60 backdrop-blur-sm transition-opacity lg:hidden ${
          isOpen ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
        }`}
      />

      <aside
        className={`fixed left-0 top-0 z-50 flex h-full w-64 flex-col bg-[#0D1117]/80 backdrop-blur-2xl border-r border-white/5 text-white transition-transform duration-300 lg:translate-x-0 ${
          isOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        {/* Branding */}
        <div className="px-6 py-8 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#0F766E]/20 text-[#14B8A6] border border-[#14B8A6]/20">
            <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>water_drop</span>
          </div>
          <div>
            <div className="text-xl font-bold tracking-tight text-white">WaterBuddy</div>
            <div className="text-[10px] font-medium uppercase tracking-wider text-[#14B8A6]">Admin Console</div>
          </div>
        </div>

        {/* New Dispatch Button */}
        <div className="mb-6 px-4">
          <button
            type="button"
            onClick={() => void navigateWithClose("/orders")}
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-[#0F766E] py-3 font-bold text-white shadow-[0_0_15px_rgba(15,118,110,0.4)] transition-all hover:bg-[#14B8A6] hover:shadow-[0_0_25px_rgba(20,184,166,0.5)]"
          >
            <span className="material-symbols-outlined text-lg">add_circle</span>
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
                    ? "bg-[#14B8A6]/10 text-[#14B8A6] border border-[#14B8A6]/20 shadow-[0_0_10px_rgba(20,184,166,0.1)]"
                    : "text-white/60 hover:bg-white/5 hover:text-white border border-transparent"
                }`}
              >
                <span className="material-symbols-outlined text-xl" style={isActive ? { fontVariationSettings: "'FILL' 1" } : {}}>{item.icon}</span>
                <span className={`text-xs uppercase tracking-wider ${isActive ? 'font-bold' : 'font-medium'}`}>{item.label}</span>
              </button>
            );
          })}
        </nav>

        {/* Secondary Navigation */}
        <div className="border-t border-white/5 px-3 pb-6 pt-4 space-y-1">
          {secondaryNav.map((item) => (
            <button
              key={item.href}
              type="button"
              onClick={() => void navigateWithClose(item.href)}
              className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-left text-white/60 transition-colors duration-200 hover:bg-white/5 hover:text-white"
            >
              <span className="material-symbols-outlined text-xl">{item.icon}</span>
              <span className="text-xs font-medium uppercase tracking-wider">{item.label}</span>
            </button>
          ))}
          <button
            type="button"
            onClick={handleLogout}
            className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-left text-white/60 transition-colors duration-200 hover:bg-red-500/10 hover:text-red-400"
          >
            <span className="material-symbols-outlined text-xl">logout</span>
            <span className="text-xs font-medium uppercase tracking-wider">Logout</span>
          </button>
        </div>
      </aside>
    </>
  );
}
