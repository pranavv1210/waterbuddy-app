import { PropsWithChildren, useEffect } from "react";
import { useRouter } from "next/router";

import { useAdminAuth } from "./AdminAuthProvider";

function FullScreenLoading() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-surface-container-low px-6 text-on-surface">
      <div className="flex items-center gap-3 rounded-full border border-outline-variant/40 bg-surface-container-lowest px-5 py-3 shadow-sm">
        <span className="material-symbols-outlined animate-pulse text-primary">water_drop</span>
        <span className="text-sm font-semibold tracking-wide text-on-surface-variant">Loading WaterBuddy Admin...</span>
      </div>
    </main>
  );
}

export function AuthGate({ children }: PropsWithChildren) {
  const router = useRouter();
  const { currentUser, loading } = useAdminAuth();
  const isLoginRoute = router.pathname === "/login";

  useEffect(() => {
    if (loading) {
      return;
    }

    if (!currentUser && !isLoginRoute) {
      void router.replace("/login");
      return;
    }

    if (currentUser && isLoginRoute) {
      void router.replace("/");
    }
  }, [currentUser, isLoginRoute, loading, router]);

  if (loading) {
    return <FullScreenLoading />;
  }

  if (!currentUser && !isLoginRoute) {
    return <FullScreenLoading />;
  }

  if (currentUser && isLoginRoute) {
    return <FullScreenLoading />;
  }

  return <>{children}</>;
}