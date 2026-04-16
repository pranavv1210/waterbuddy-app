interface ModuleCardProps {
  title: string;
  description: string;
}

export function ModuleCard({ title, description }: ModuleCardProps) {
  return (
    <section
      style={{
        border: "1px solid #d1d5db",
        borderRadius: 12,
        padding: 16,
        marginBottom: 16,
      }}
    >
      <h2>{title}</h2>
      <p>{description}</p>
    </section>
  );
}
