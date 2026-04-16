import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/router";

import { AppShell } from "../components/layout/AppShell";
import { useAdminAuth } from "../components/auth/AdminAuthProvider";

const SETTINGS_STORAGE_KEY = "waterbuddy.admin.settings";

interface AdminSettings {
  defaultLanding: string;
  compactSidebar: boolean;
  emailAlerts: boolean;
  dailyDigest: boolean;
}

const defaultSettings: AdminSettings = {
  defaultLanding: "/",
  compactSidebar: false,
  emailAlerts: true,
  dailyDigest: false,
};

export default function SettingsPage() {
  const router = useRouter();
  const { currentUser, signOut, updateDisplayName } = useAdminAuth();
  const [displayName, setDisplayName] = useState("");
  const [settings, setSettings] = useState<AdminSettings>(defaultSettings);
  const [saving, setSaving] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  useEffect(() => {
    if (currentUser?.displayName) {
      setDisplayName(currentUser.displayName);
    }

    if (typeof window === "undefined") {
      return;
    }

    const stored = window.localStorage.getItem(SETTINGS_STORAGE_KEY);
    if (stored) {
      try {
        const parsed = JSON.parse(stored) as Partial<AdminSettings>;
        setSettings({
          defaultLanding: parsed.defaultLanding ?? defaultSettings.defaultLanding,
          compactSidebar: parsed.compactSidebar ?? defaultSettings.compactSidebar,
          emailAlerts: parsed.emailAlerts ?? defaultSettings.emailAlerts,
          dailyDigest: parsed.dailyDigest ?? defaultSettings.dailyDigest,
        });
      } catch {
        window.localStorage.removeItem(SETTINGS_STORAGE_KEY);
      }
    }
  }, [currentUser]);

  const persistSettings = (nextSettings: AdminSettings) => {
    setSettings(nextSettings);
    if (typeof window !== "undefined") {
      window.localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(nextSettings));
    }
  };

  const handleProfileSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSaving(true);
    setStatusMessage(null);

    try {
      await updateDisplayName(displayName);
      setStatusMessage("Profile updated successfully.");
    } catch (error) {
      setStatusMessage(error instanceof Error ? error.message : "Unable to update profile right now.");
    } finally {
      setSaving(false);
    }
  };

  const handleSignOut = async () => {
    await signOut();
    await router.replace("/login");
  };

  return (
    <AppShell>
      <div className="space-y-8">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.35em] text-secondary">Admin settings</p>
            <h1 className="mt-2 text-4xl font-black tracking-tight text-primary">Settings</h1>
            <p className="mt-2 max-w-2xl text-sm text-on-surface-variant">
              Control your WaterBuddy admin profile, preferences, and sign-out session from one screen.
            </p>
          </div>

          <button
            type="button"
            onClick={handleSignOut}
            className="inline-flex items-center gap-2 rounded-2xl bg-primary px-4 py-3 text-sm font-bold text-on-primary shadow-lg shadow-primary/15 transition hover:bg-primary-container"
          >
            <span className="material-symbols-outlined text-[20px]">logout</span>
            Sign out
          </button>
        </div>

        {statusMessage ? (
          <div className="rounded-2xl border border-outline-variant/40 bg-surface-container-lowest px-4 py-3 text-sm text-on-surface-variant shadow-sm">
            {statusMessage}
          </div>
        ) : null}

        <div className="grid grid-cols-1 gap-6 xl:grid-cols-[1.15fr_0.85fr]">
          <section className="rounded-[28px] border border-outline-variant/40 bg-surface-container-lowest p-6 shadow-sm">
            <div className="mb-6 flex items-center justify-between gap-4">
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.3em] text-on-surface-variant">Profile</p>
                <h2 className="mt-2 text-2xl font-black text-on-surface">Account details</h2>
              </div>
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-secondary-container text-primary-container">
                <span className="material-symbols-outlined">person</span>
              </div>
            </div>

            <form className="space-y-5" onSubmit={handleProfileSubmit}>
              <label className="block space-y-2">
                <span className="text-xs font-bold uppercase tracking-[0.3em] text-on-surface-variant">Display name</span>
                <input
                  value={displayName}
                  onChange={(event) => setDisplayName(event.target.value)}
                  className="w-full rounded-2xl border border-outline-variant/60 bg-surface-container-low px-4 py-3 text-sm outline-none transition focus:border-secondary focus:ring-2 focus:ring-secondary/15"
                  placeholder="WaterBuddy Admin"
                />
              </label>

              <label className="block space-y-2">
                <span className="text-xs font-bold uppercase tracking-[0.3em] text-on-surface-variant">Email</span>
                <input
                  value={currentUser?.email ?? ""}
                  disabled
                  className="w-full cursor-not-allowed rounded-2xl border border-outline-variant/50 bg-surface-container-low px-4 py-3 text-sm text-on-surface-variant"
                />
              </label>

              <div className="flex flex-wrap items-center gap-3">
                <button
                  type="submit"
                  disabled={saving}
                  className="inline-flex items-center gap-2 rounded-2xl bg-primary px-4 py-3 text-sm font-bold text-on-primary shadow-lg shadow-primary/15 transition hover:bg-primary-container disabled:cursor-not-allowed disabled:opacity-70"
                >
                  <span className="material-symbols-outlined text-[20px]">save</span>
                  {saving ? "Saving..." : "Save profile"}
                </button>
              </div>
            </form>
          </section>

          <section className="space-y-6">
            <div className="rounded-[28px] border border-outline-variant/40 bg-surface-container-lowest p-6 shadow-sm">
              <p className="text-xs font-bold uppercase tracking-[0.3em] text-on-surface-variant">Preferences</p>
              <h2 className="mt-2 text-2xl font-black text-on-surface">Dashboard behavior</h2>

              <div className="mt-6 space-y-4">
                <label className="block space-y-2">
                  <span className="text-xs font-bold uppercase tracking-[0.3em] text-on-surface-variant">Default landing page</span>
                  <select
                    value={settings.defaultLanding}
                    onChange={(event) => persistSettings({ ...settings, defaultLanding: event.target.value })}
                    className="w-full rounded-2xl border border-outline-variant/60 bg-surface-container-low px-4 py-3 text-sm outline-none transition focus:border-secondary focus:ring-2 focus:ring-secondary/15"
                  >
                    <option value="/">Overview</option>
                    <option value="/orders">Orders</option>
                    <option value="/sellers">Sellers</option>
                    <option value="/payments">Payments</option>
                  </select>
                </label>

                {[
                  {
                    label: "Compact sidebar",
                    key: "compactSidebar",
                    description: "Reduce the shell spacing for denser layouts.",
                  },
                  {
                    label: "Email alerts",
                    key: "emailAlerts",
                    description: "Enable local dashboard notifications for key events.",
                  },
                  {
                    label: "Daily digest",
                    key: "dailyDigest",
                    description: "Receive a summary of orders, payouts, and complaints.",
                  },
                ].map((setting) => (
                  <label
                    key={setting.key}
                    className="flex items-start justify-between gap-4 rounded-2xl bg-surface-container-low px-4 py-4"
                  >
                    <span>
                      <span className="block text-sm font-bold text-on-surface">{setting.label}</span>
                      <span className="mt-1 block text-xs text-on-surface-variant">{setting.description}</span>
                    </span>
                    <input
                      type="checkbox"
                      checked={settings[setting.key as keyof AdminSettings] as boolean}
                      onChange={(event) =>
                        persistSettings({
                          ...settings,
                          [setting.key]: event.target.checked,
                        })
                      }
                      className="mt-1 h-5 w-5 rounded border-outline-variant text-primary focus:ring-primary"
                    />
                  </label>
                ))}
              </div>
            </div>

            <div className="rounded-[28px] border border-outline-variant/40 bg-primary-container p-6 text-white shadow-sm">
              <p className="text-xs font-bold uppercase tracking-[0.3em] text-secondary-container">Session</p>
              <h2 className="mt-2 text-2xl font-black">Signed in as {currentUser?.displayName ?? "Admin"}</h2>
              <p className="mt-2 text-sm text-white/75">
                Keep this window open for live monitoring. Sign out when you are done to lock the dashboard.
              </p>

              <div className="mt-6 flex flex-wrap gap-3">
                <button
                  type="button"
                  onClick={() => void router.push("/")}
                  className="rounded-2xl bg-secondary-container px-4 py-3 text-sm font-bold text-primary-container transition hover:opacity-90"
                >
                  Back to overview
                </button>
                <button
                  type="button"
                  onClick={handleSignOut}
                  className="rounded-2xl border border-white/20 px-4 py-3 text-sm font-bold text-white transition hover:bg-white/10"
                >
                  Sign out now
                </button>
              </div>
            </div>
          </section>
        </div>
      </div>
    </AppShell>
  );
}