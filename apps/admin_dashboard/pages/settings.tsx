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
      <div className="space-y-10">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <nav className="mb-2 flex gap-2 text-[10px] font-bold uppercase tracking-[0.2em] text-[#14B8A6]">
              <span>System</span>
              <span className="text-white/20">/</span>
              <span className="text-white/60">Configuration</span>
            </nav>
            <h1 className="text-4xl font-extrabold tracking-tight text-white">Settings</h1>
            <p className="mt-1 text-white/40 font-medium">Control your profile, preferences, and security sessions.</p>
          </div>

          <button
            type="button"
            onClick={handleSignOut}
            className="flex items-center gap-2 rounded-xl bg-red-500 px-6 py-2.5 text-xs font-black text-white shadow-[0_0_20px_rgba(239,68,68,0.2)] transition-all hover:scale-[1.02] active:scale-[0.98] uppercase tracking-widest"
          >
            <span className="material-symbols-outlined text-[20px]">logout</span>
            Terminate Session
          </button>
        </div>

        {statusMessage ? (
          <div className="rounded-2xl border border-[#14B8A6]/20 bg-[#14B8A6]/5 px-6 py-4 text-sm font-bold text-[#14B8A6] animate-in fade-in slide-in-from-top-4">
             <div className="flex items-center gap-3">
                <span className="material-symbols-outlined">check_circle</span>
                {statusMessage}
             </div>
          </div>
        ) : null}

        <div className="grid grid-cols-1 gap-8 xl:grid-cols-[1.15fr_0.85fr]">
          <section className="rounded-[32px] border border-white/5 bg-[#0D1117]/60 p-8 shadow-xl backdrop-blur-xl">
            <div className="mb-10 flex items-center justify-between gap-4">
              <div>
                <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#14B8A6]">Personalization</p>
                <h2 className="mt-2 text-2xl font-black text-white tracking-tight">Identity & Profile</h2>
              </div>
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-white/5 text-[#14B8A6] border border-white/5">
                <span className="material-symbols-outlined text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>person</span>
              </div>
            </div>

            <form className="space-y-8" onSubmit={handleProfileSubmit}>
              <div className="space-y-3">
                <label className="text-[10px] font-black uppercase tracking-[0.2em] text-white/20">Display Name</label>
                <input
                  value={displayName}
                  onChange={(event) => setDisplayName(event.target.value)}
                  className="w-full rounded-2xl border border-white/5 bg-white/5 px-6 py-4 text-sm font-bold text-white outline-none transition-all focus:border-[#14B8A6]/50 focus:ring-4 focus:ring-[#14B8A6]/10 placeholder:text-white/10"
                  placeholder="WaterBuddy Admin"
                />
              </div>

              <div className="space-y-3">
                <label className="text-[10px] font-black uppercase tracking-[0.2em] text-white/20">Authenticated Email</label>
                <div className="relative">
                  <input
                    value={currentUser?.email ?? ""}
                    disabled
                    className="w-full cursor-not-allowed rounded-2xl border border-white/5 bg-white/[0.02] px-6 py-4 text-sm font-bold text-white/20 outline-none"
                  />
                  <span className="absolute right-4 top-1/2 -translate-y-1/2 material-symbols-outlined text-white/10">lock</span>
                </div>
              </div>

              <div className="pt-4">
                <button
                  type="submit"
                  disabled={saving}
                  className="flex items-center gap-3 rounded-2xl bg-[#14B8A6] px-8 py-4 text-xs font-black text-white shadow-[0_0_30px_rgba(20,184,166,0.3)] transition-all hover:scale-[1.02] active:scale-[0.98] uppercase tracking-widest disabled:opacity-50"
                >
                  <span className="material-symbols-outlined text-[20px]">save</span>
                  {saving ? "Processing..." : "Commit Changes"}
                </button>
              </div>
            </form>
          </section>

          <section className="space-y-8">
            <div className="rounded-[32px] border border-white/5 bg-[#0D1117]/60 p-8 shadow-xl backdrop-blur-xl">
              <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#14B8A6]">Global Behavior</p>
              <h2 className="mt-2 text-2xl font-black text-white tracking-tight">Preferences</h2>

              <div className="mt-10 space-y-4">
                <div className="space-y-3 mb-8">
                  <label className="text-[10px] font-black uppercase tracking-[0.2em] text-white/20">Default Entry Point</label>
                  <select
                    value={settings.defaultLanding}
                    onChange={(event) => persistSettings({ ...settings, defaultLanding: event.target.value })}
                    className="w-full rounded-2xl border border-white/5 bg-white/5 px-6 py-4 text-sm font-bold text-white outline-none transition-all focus:border-[#14B8A6]/50 appearance-none cursor-pointer"
                  >
                    <option value="/" className="bg-[#0D1117]">Overview Dashboard</option>
                    <option value="/orders" className="bg-[#0D1117]">Orders Tracking</option>
                    <option value="/sellers" className="bg-[#0D1117]">Seller Network</option>
                    <option value="/payments" className="bg-[#0D1117]">Treasury</option>
                  </select>
                </div>

                {[
                  {
                    label: "Interface Compact Mode",
                    key: "compactSidebar",
                    description: "Reduce shell density for high-resolution displays.",
                  },
                  {
                    label: "Network Notifications",
                    key: "emailAlerts",
                    description: "Enable real-time push alerts for critical events.",
                  },
                  {
                    label: "Automated Daily Digest",
                    key: "dailyDigest",
                    description: "Generate summary reports for the morning briefing.",
                  },
                ].map((setting) => (
                  <label
                    key={setting.key}
                    className="flex items-center justify-between gap-6 rounded-2xl bg-white/[0.03] border border-white/5 px-6 py-5 cursor-pointer transition-all hover:bg-white/5"
                  >
                    <span className="flex-1">
                      <span className="block text-xs font-black text-white uppercase tracking-wider">{setting.label}</span>
                      <span className="mt-1 block text-[10px] text-white/30 font-medium">{setting.description}</span>
                    </span>
                    <div className="relative">
                       <input
                        type="checkbox"
                        checked={settings[setting.key as keyof AdminSettings] as boolean}
                        onChange={(event) =>
                          persistSettings({
                            ...settings,
                            [setting.key]: event.target.checked,
                          })
                        }
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-white/10 rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white/40 after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#14B8A6] peer-checked:after:bg-white"></div>
                    </div>
                  </label>
                ))}
              </div>
            </div>

            <div className="relative overflow-hidden rounded-[32px] bg-[#14B8A6] p-8 text-white shadow-[0_0_40px_rgba(20,184,166,0.3)] group">
              <div className="absolute -right-20 -top-20 h-64 w-64 rounded-full bg-white/5 blur-3xl group-hover:bg-white/10 transition-all duration-1000"></div>
              <p className="text-[10px] font-black uppercase tracking-[0.3em] text-white/60">Active Authority</p>
              <h2 className="mt-3 text-2xl font-black tracking-tight">{currentUser?.displayName ?? "Primary Admin"}</h2>
              <p className="mt-2 text-xs font-medium text-white/80 leading-relaxed max-w-[200px]">
                Authorized session for real-time network monitoring.
              </p>

              <div className="mt-8 flex flex-col gap-3">
                <button
                  type="button"
                  onClick={() => void router.push("/")}
                  className="flex items-center justify-center gap-2 rounded-2xl bg-white py-4 text-[10px] font-black uppercase tracking-widest text-[#14B8A6] shadow-xl transition-all hover:scale-[1.02] active:scale-[0.98]"
                >
                  <span className="material-symbols-outlined text-lg">dashboard</span>
                  Return to Hub
                </button>
              </div>
            </div>
          </section>
        </div>
      </div>
    </AppShell>
  );
}