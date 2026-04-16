import { PropsWithChildren } from "react";

interface PageSectionProps extends PropsWithChildren {
  title: string;
}

export function PageSection({ title, children }: PageSectionProps) {
  return (
    <section style={{ padding: "32px 24px", borderBottom: "1px solid #e5e7eb" }}>
      <h2>{title}</h2>
      {children}
    </section>
  );
}
