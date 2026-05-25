import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/router";

import { useAdminAuth } from "../components/auth/AdminAuthProvider";
import {
  ADMIN_LOGIN_EMAIL,
  ADMIN_LOGIN_PASSWORD,
} from "../services/adminCredentials";

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
      setErrorMessage(
        error instanceof Error ? error.message : "Unable to sign in.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="min-h-screen overflow-hidden bg-sky-50 text-slate-950">
      <div className="grid min-h-screen lg:grid-cols-[1.2fr_1fr]">
        {/* Left Side: Branding & Info */}
        <section className="flex flex-col justify-center space-y-12 px-8 py-12 lg:px-16">
          <div className="flex items-center gap-4">
            <div className="flex h-16 w-16 items-center justify-center rounded-2xl border border-sky-200 bg-white text-sky-600 shadow-sm">
              <span
                className="material-symbols-outlined text-4xl"
                style={{ fontVariationSettings: "'FILL' 1" }}
              >
                water_drop
              </span>
            </div>
            <div>
              <h1 className="text-4xl font-black tracking-tight text-slate-950">
                WaterBuddy
              </h1>
              <p className="text-sm font-semibold uppercase tracking-[0.35em] text-sky-600">
                Admin Console
              </p>
            </div>
          </div>

          <div className="space-y-6">
            <h2 className="max-w-lg text-5xl font-black leading-tight tracking-tight text-slate-950">
              The command center for your entire operation.
            </h2>
            <p className="max-w-xl text-lg font-medium text-slate-600">
              Manage dispatch, sellers, customers, and payouts securely.
              Experience full control with real-time sync across the platform.
            </p>
          </div>

          <div className="grid grid-cols-1 gap-6 sm:grid-cols-3 mt-12">
            <div className="rounded-2xl border border-sky-100 bg-white p-6 shadow-sm transition hover:border-sky-200">
              <span className="material-symbols-outlined mb-4 block text-3xl text-sky-600">
                speed
              </span>
              <p className="text-xs font-bold uppercase tracking-[0.2em] text-slate-500">
                Live Data
              </p>
              <p className="mt-2 text-2xl font-bold text-slate-950">Realtime</p>
            </div>
            <div className="rounded-2xl border border-sky-100 bg-white p-6 shadow-sm transition hover:border-sky-200">
              <span className="material-symbols-outlined mb-4 block text-3xl text-sky-600">
                security
              </span>
              <p className="text-xs font-bold uppercase tracking-[0.2em] text-slate-500">
                Security
              </p>
              <p className="mt-2 text-2xl font-bold text-slate-950">
                Firebase Auth
              </p>
            </div>
            <div className="rounded-2xl border border-sky-100 bg-white p-6 shadow-sm transition hover:border-sky-200">
              <span className="material-symbols-outlined mb-4 block text-3xl text-sky-600">
                tune
              </span>
              <p className="text-xs font-bold uppercase tracking-[0.2em] text-slate-500">
                Control
              </p>
              <p className="mt-2 text-2xl font-bold text-slate-950">
                Full Access
              </p>
            </div>
          </div>
        </section>

        {/* Right Side: Login Form */}
        <section className="flex items-center justify-center bg-white px-6 py-10 lg:px-12">
          <div className="w-full max-w-md rounded-[32px] border border-sky-100 bg-white p-8 shadow-2xl shadow-sky-900/10">
            <div className="mb-10 space-y-3 text-center">
              <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-sky-50">
                <span className="material-symbols-outlined text-3xl text-sky-600">
                  admin_panel_settings
                </span>
              </div>
              <h2 className="text-3xl font-black tracking-tight text-slate-950">
                Welcome back
              </h2>
              <p className="text-sm text-slate-500">
                Authenticate to access the secure admin portal.
              </p>
            </div>

            <form className="space-y-6" onSubmit={handleSubmit}>
              <div className="space-y-4">
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <span className="material-symbols-outlined text-slate-400 text-xl">
                      mail
                    </span>
                  </div>
                  <input
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                    type="email"
                    required
                    autoComplete="email"
                    className="w-full rounded-2xl border border-sky-100 bg-sky-50 py-4 pl-12 pr-4 text-sm text-slate-950 outline-none transition placeholder:text-slate-400 focus:border-sky-300 focus:bg-white focus:ring-2 focus:ring-sky-100"
                    placeholder={ADMIN_LOGIN_EMAIL}
                  />
                </div>

                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <span className="material-symbols-outlined text-slate-400 text-xl">
                      lock
                    </span>
                  </div>
                  <input
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                    type="password"
                    required
                    autoComplete="current-password"
                    className="w-full rounded-2xl border border-sky-100 bg-sky-50 py-4 pl-12 pr-4 text-sm text-slate-950 outline-none transition placeholder:text-slate-400 focus:border-sky-300 focus:bg-white focus:ring-2 focus:ring-sky-100"
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
                className="flex w-full items-center justify-center gap-2 rounded-2xl bg-sky-600 px-4 py-4 text-sm font-bold text-white shadow-lg shadow-sky-600/20 transition hover:-translate-y-0.5 hover:bg-sky-700 disabled:cursor-not-allowed disabled:translate-y-0 disabled:opacity-50"
              >
                {submitting ? (
                  <div className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                ) : (
                  <>
                    <span className="material-symbols-outlined text-[20px]">
                      login
                    </span>
                    Access Dashboard
                  </>
                )}
              </button>
            </form>

            <div className="mt-8 rounded-2xl border border-sky-100 bg-sky-50 p-4 text-center">
              <p className="text-xs leading-relaxed text-slate-500">
                This is a restricted portal. Unauthorized access attempts are
                logged and monitored.
              </p>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
