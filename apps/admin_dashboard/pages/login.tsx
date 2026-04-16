import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/router";

import { useAdminAuth } from "../components/auth/AdminAuthProvider";
import { ADMIN_LOGIN_EMAIL, ADMIN_LOGIN_PASSWORD } from "../services/adminCredentials";

export default function LoginPage() {
  const router = useRouter();
  const { currentUser, loading, signIn } = useAdminAuth();
  const [email, setEmail] = useState(ADMIN_LOGIN_EMAIL);
  const [password, setPassword] = useState(ADMIN_LOGIN_PASSWORD);
  const [submitting, setSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (currentUser && !loading) {
      void router.replace("/");
    }
  }, [currentUser, loading, router]);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setErrorMessage(null);
    setSubmitting(true);

    try {
      await signIn(email, password);
      await router.replace("/");
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Unable to sign in.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="min-h-screen bg-surface-container-low text-on-surface">
      <div className="grid min-h-screen lg:grid-cols-[1.15fr_0.85fr]">
        <section className="relative flex flex-col justify-between overflow-hidden bg-primary-container px-8 py-10 text-white lg:px-12">
          <div className="absolute inset-0 opacity-25">
            <div className="absolute -left-16 top-16 h-48 w-48 rounded-full bg-secondary-container blur-3xl"></div>
            <div className="absolute bottom-16 right-6 h-44 w-44 rounded-full bg-white/20 blur-3xl"></div>
          </div>

          <div className="relative z-10 max-w-xl space-y-8">
            <div className="flex items-center gap-4">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-secondary-container text-primary-container shadow-lg shadow-black/10">
                <span className="material-symbols-outlined text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>
                  water_drop
                </span>
              </div>
              <div>
                <h1 className="text-4xl font-black tracking-tight">WaterBuddy</h1>
                <p className="text-sm font-semibold uppercase tracking-[0.35em] text-secondary-container/90">Admin Console</p>
              </div>
            </div>

            <div className="space-y-4">
              <h2 className="max-w-lg text-5xl font-black leading-tight tracking-tight">
                Secure access for dispatch, sellers, customers, and payouts.
              </h2>
              <p className="max-w-2xl text-base text-white/75">
                Sign in once and manage the full WaterBuddy operation from one place. First-time logins can create the admin account automatically.
              </p>
            </div>
          </div>

          <div className="relative z-10 grid grid-cols-1 gap-4 sm:grid-cols-3">
            <div className="rounded-2xl bg-white/10 p-4 backdrop-blur-sm">
              <p className="text-xs font-bold uppercase tracking-[0.3em] text-secondary-container">Live Orders</p>
              <p className="mt-2 text-3xl font-black">Realtime</p>
            </div>
            <div className="rounded-2xl bg-white/10 p-4 backdrop-blur-sm">
              <p className="text-xs font-bold uppercase tracking-[0.3em] text-secondary-container">Security</p>
              <p className="mt-2 text-3xl font-black">Firebase Auth</p>
            </div>
            <div className="rounded-2xl bg-white/10 p-4 backdrop-blur-sm">
              <p className="text-xs font-bold uppercase tracking-[0.3em] text-secondary-container">Control</p>
              <p className="mt-2 text-3xl font-black">Settings</p>
            </div>
          </div>
        </section>

        <section className="flex items-center justify-center px-6 py-10 sm:px-10">
          <div className="w-full max-w-md rounded-[28px] border border-outline-variant/40 bg-surface-container-lowest p-8 shadow-[0_24px_80px_rgba(0,35,111,0.12)]">
            <div className="mb-8 space-y-2">
              <p className="text-xs font-bold uppercase tracking-[0.35em] text-primary">Sign in</p>
              <h2 className="text-3xl font-black tracking-tight text-on-surface">Welcome back</h2>
              <p className="text-sm text-on-surface-variant">
                Enter the fixed WaterBuddy admin credentials to access the dashboard.
              </p>
            </div>

            <form className="space-y-5" onSubmit={handleSubmit}>
              <label className="block space-y-2">
                <span className="text-xs font-bold uppercase tracking-[0.3em] text-on-surface-variant">Email</span>
                <input
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  type="email"
                  required
                  autoComplete="email"
                  className="w-full rounded-2xl border border-outline-variant/60 bg-surface-container-low px-4 py-3 text-sm text-on-surface outline-none transition focus:border-secondary focus:ring-2 focus:ring-secondary/15"
                  placeholder={ADMIN_LOGIN_EMAIL}
                />
              </label>

              <label className="block space-y-2">
                <span className="text-xs font-bold uppercase tracking-[0.3em] text-on-surface-variant">Password</span>
                <input
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  type="password"
                  required
                  autoComplete="current-password"
                  className="w-full rounded-2xl border border-outline-variant/60 bg-surface-container-low px-4 py-3 text-sm text-on-surface outline-none transition focus:border-secondary focus:ring-2 focus:ring-secondary/15"
                  placeholder="Configured password"
                />
              </label>

              {errorMessage ? (
                <div className="rounded-2xl border border-error/20 bg-error-container px-4 py-3 text-sm text-on-error-container">
                  {errorMessage}
                </div>
              ) : null}

              <button
                type="submit"
                disabled={submitting}
                className="flex w-full items-center justify-center gap-2 rounded-2xl bg-primary px-4 py-3 text-sm font-bold text-on-primary shadow-lg shadow-primary/20 transition hover:bg-primary-container disabled:cursor-not-allowed disabled:opacity-70"
              >
                <span className="material-symbols-outlined text-[20px]">login</span>
                {submitting ? "Signing in..." : "Enter dashboard"}
              </button>
            </form>

            <div className="mt-6 rounded-2xl bg-surface-container-low px-4 py-4 text-xs leading-6 text-on-surface-variant">
              Only one admin login is enabled for this dashboard. Keep these credentials private.
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}