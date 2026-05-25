import { PropsWithChildren, useEffect, useState } from "react";
import { Sidebar } from "./Sidebar";
import { Header } from "./Header";

export function AppShell({ children }: PropsWithChildren) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  useEffect(() => {
    const onResize = () => {
      if (window.innerWidth >= 1024) {
        setIsSidebarOpen(false);
      }
    };

    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  return (
    <div className="admin-shell min-h-full overflow-x-hidden bg-sky-50 text-slate-950">
      <div className="flex min-h-screen">
        <Sidebar
          isOpen={isSidebarOpen}
          onClose={() => setIsSidebarOpen(false)}
        />
        <div className="flex min-w-0 flex-1 flex-col lg:pl-64">
          <Header onToggleSidebar={() => setIsSidebarOpen((prev) => !prev)} />
          <main className="min-w-0 flex-1 px-4 py-4 sm:px-5 sm:py-5 lg:p-6">
            {children}
          </main>
        </div>
      </div>
    </div>
  );
}
