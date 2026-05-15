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
    <div className="min-h-full bg-[#050608] text-white relative overflow-x-hidden">
      {/* Background Orbs */}
      <div className="fixed top-[-100px] left-[-100px] h-[400px] w-[400px] rounded-full bg-[#0F766E] opacity-20 blur-[100px] pointer-events-none z-0"></div>
      <div className="fixed bottom-[-100px] right-[-100px] h-[300px] w-[300px] rounded-full bg-[#14B8A6] opacity-10 blur-[100px] pointer-events-none z-0"></div>

      <div className="relative z-10 flex min-h-screen">
        <Sidebar isOpen={isSidebarOpen} onClose={() => setIsSidebarOpen(false)} />
        <div className="flex-1 flex flex-col w-full min-w-0">
          <Header onToggleSidebar={() => setIsSidebarOpen((prev) => !prev)} />
          <main className="flex-1 px-4 py-6 sm:px-6 sm:py-8 lg:ml-64 lg:p-8 w-full max-w-full overflow-x-hidden">
            {children}
          </main>
        </div>
      </div>
    </div>
  );
}
