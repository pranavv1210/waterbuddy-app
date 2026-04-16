import { PropsWithChildren } from "react";
import { Sidebar } from "./Sidebar";
import { Header } from "./Header";

export function AppShell({ children }: PropsWithChildren) {
  return (
    <div className="min-h-full bg-cream">
      <Sidebar />
      <Header />
      <main className="ml-64 p-8 min-h-screen">{children}</main>
    </div>
  );
}
