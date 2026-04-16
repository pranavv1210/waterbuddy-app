import Link from "next/link";
import { PropsWithChildren } from "react";

const navigation = [
  { href: "/orders", label: "Orders" },
  { href: "/sellers", label: "Sellers" },
  { href: "/customers", label: "Customers" },
  { href: "/payments", label: "Payments" },
  { href: "/complaints", label: "Complaints" },
];

export function AppShell({ children }: PropsWithChildren) {
  return (
    <div style={{ fontFamily: "sans-serif", padding: 24 }}>
      <header style={{ marginBottom: 24 }}>
        <h1>WaterBuddy Admin</h1>
        <nav style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
          {navigation.map((item) => (
            <Link key={item.href} href={item.href}>
              {item.label}
            </Link>
          ))}
        </nav>
      </header>
      <main>{children}</main>
    </div>
  );
}
