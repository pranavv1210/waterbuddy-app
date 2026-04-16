interface ModuleCardProps {
  title: string;
  description: string;
}

export function ModuleCard({ title, description }: ModuleCardProps) {
  return (
    <section className="mb-4 rounded-2xl border border-lilac/50 bg-white p-5 shadow-sm">
      <h2 className="text-lg font-semibold text-brand-600">{title}</h2>
      <p className="mt-2 text-sm text-slate-600">{description}</p>
    </section>
  );
}
