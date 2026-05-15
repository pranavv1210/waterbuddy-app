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
    <main className="min-h-screen bg-[#0D1117] text-white overflow-hidden relative">
      {/* Background Orbs */}
      <div className="absolute top-[-100px] left-[-100px] h-[400px] w-[400px] rounded-full bg-[#0F766E] opacity-30 blur-[100px]"></div>
      <div className="absolute bottom-[-100px] right-[-100px] h-[300px] w-[300px] rounded-full bg-[#14B8A6] opacity-20 blur-[100px]"></div>

      <div className="grid min-h-screen lg:grid-cols-[1.2fr_1fr] relative z-10">
        
        {/* Left Side: Branding & Info */}
        <section className="flex flex-col justify-center px-8 py-12 lg:px-16 space-y-12 backdrop-blur-sm">
          <div className="flex items-center gap-4">
            <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#0F766E]/20 text-[#14B8A6] border border-[#14B8A6]/20 shadow-[0_0_20px_rgba(20,184,166,0.2)]">
              <span className="material-symbols-outlined text-4xl" style={{ fontVariationSettings: "'FILL' 1" }}>
                water_drop
              </span>
            </div>
            <div>
              <h1 className="text-4xl font-black tracking-tight text-white">WaterBuddy</h1>
              <p className="text-sm font-semibold uppercase tracking-[0.35em] text-[#14B8A6]">Admin Console</p>
            </div>
          </div>

          <div className="space-y-6">
            <h2 className="max-w-lg text-5xl font-black leading-tight tracking-tight text-white drop-shadow-lg">
              The command center for your entire operation.
            </h2>
            <p className="max-w-xl text-lg text-white/60 font-light">
              Manage dispatch, sellers, customers, and payouts securely. Experience full control with real-time sync across the platform.
            </p>
          </div>

          <div className="grid grid-cols-1 gap-6 sm:grid-cols-3 mt-12">
            <div className="rounded-2xl bg-white/[0.03] border border-white/[0.05] p-6 backdrop-blur-md transition hover:bg-white/[0.06]">
              <span className="material-symbols-outlined text-3xl text-[#14B8A6] mb-4 block">speed</span>
              <p className="text-xs font-bold uppercase tracking-[0.2em] text-white/40">Live Data</p>
              <p className="mt-2 text-2xl font-bold text-white">Realtime</p>
            </div>
            <div className="rounded-2xl bg-white/[0.03] border border-white/[0.05] p-6 backdrop-blur-md transition hover:bg-white/[0.06]">
              <span className="material-symbols-outlined text-3xl text-[#14B8A6] mb-4 block">security</span>
              <p className="text-xs font-bold uppercase tracking-[0.2em] text-white/40">Security</p>
              <p className="mt-2 text-2xl font-bold text-white">Firebase Auth</p>
            </div>
            <div className="rounded-2xl bg-white/[0.03] border border-white/[0.05] p-6 backdrop-blur-md transition hover:bg-white/[0.06]">
              <span className="material-symbols-outlined text-3xl text-[#14B8A6] mb-4 block">tune</span>
              <p className="text-xs font-bold uppercase tracking-[0.2em] text-white/40">Control</p>
              <p className="mt-2 text-2xl font-bold text-white">Full Access</p>
            </div>
          </div>
        </section>

        {/* Right Side: Login Form */}
        <section className="flex items-center justify-center px-6 py-10 lg:px-12 backdrop-blur-md bg-black/20">
          <div className="w-full max-w-md rounded-[32px] border border-white/10 bg-white/5 p-8 shadow-[0_30px_60px_rgba(0,0,0,0.4)] backdrop-blur-2xl">
            <div className="mb-10 space-y-3 text-center">
              <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-[#14B8A6]/10 mb-4">
                <span className="material-symbols-outlined text-3xl text-[#14B8A6]">admin_panel_settings</span>
              </div>
              <h2 className="text-3xl font-black tracking-tight text-white">Welcome back</h2>
              <p className="text-sm text-white/50">
                Authenticate to access the secure admin portal.
              </p>
            </div>

            <form className="space-y-6" onSubmit={handleSubmit}>
              <div className="space-y-4">
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <span className="material-symbols-outlined text-white/30 text-xl">mail</span>
                  </div>
                  <input
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                    type="email"
                    required
                    autoComplete="email"
                    className="w-full rounded-2xl border border-white/10 bg-white/5 pl-12 pr-4 py-4 text-sm text-white placeholder-white/30 outline-none transition focus:border-[#14B8A6] focus:bg-white/10 focus:ring-1 focus:ring-[#14B8A6]"
                    placeholder={ADMIN_LOGIN_EMAIL}
                  />
                </div>

                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <span className="material-symbols-outlined text-white/30 text-xl">lock</span>
                  </div>
                  <input
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                    type="password"
                    required
                    autoComplete="current-password"
                    className="w-full rounded-2xl border border-white/10 bg-white/5 pl-12 pr-4 py-4 text-sm text-white placeholder-white/30 outline-none transition focus:border-[#14B8A6] focus:bg-white/10 focus:ring-1 focus:ring-[#14B8A6]"
                    placeholder="Enter password"
                  />
                </div>
              </div>

              {errorMessage ? (
                <div className="rounded-2xl border border-red-500/20 bg-red-500/10 px-4 py-3 text-sm text-red-400 text-center">
                  {errorMessage}
                </div>
              ) : null}

              <button
                type="submit"
                disabled={submitting}
                className="flex w-full items-center justify-center gap-2 rounded-2xl bg-[#0F766E] px-4 py-4 text-sm font-bold text-white shadow-[0_0_20px_rgba(15,118,110,0.4)] transition hover:bg-[#14B8A6] hover:shadow-[0_0_25px_rgba(20,184,166,0.6)] hover:-translate-y-0.5 disabled:cursor-not-allowed disabled:opacity-50 disabled:transform-none"
              >
                {submitting ? (
                  <div className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                ) : (
                  <>
                    <span className="material-symbols-outlined text-[20px]">login</span>
                    Access Dashboard
                  </>
                )}
              </button>
            </form>

            <div className="mt-8 rounded-2xl bg-white/5 border border-white/10 p-4 text-center">
              <p className="text-xs leading-relaxed text-white/40">
                This is a restricted portal. Unauthorized access attempts are logged and monitored.
              </p>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}