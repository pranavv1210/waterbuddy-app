import { AppShell } from "../../components/layout/AppShell";
import { ModuleCard } from "../../components/ui/ModuleCard";

interface ModuleScreenProps {
  title: string;
  description: string;
}

export function ModuleScreen({ title, description }: ModuleScreenProps) {
  return (
    <AppShell>
      <ModuleCard title={title} description={description} />
    </AppShell>
  );
}
