"use client";
/* eslint-disable @next/next/no-img-element */

import { useCallback, useEffect, useState } from "react";
import {
  Bell,
  Building2,
  KeyRound,
  Laptop,
  Link2,
  LogOut,
  Monitor,
  Palette,
  Save,
  ShieldCheck,
  Smartphone,
  Upload,
  Trash2,
} from "lucide-react";
import { useAuth } from "@/components/auth-provider";
import { BrandLogo } from "@/components/brand-logo";
import { usePreferences } from "@/components/app-preferences-provider";
import {
  useDashboardSettings,
  type DashboardSettings,
} from "@/components/settings-provider";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SearchableSelect } from "@/components/searchable-select";
import { cn } from "@/lib/utils";
import { uploadFirebaseFile } from "@/lib/firebase/storage";
import { usePermissions } from "@/components/use-permissions";

type Notify = (message: string) => void;
async function uploadImage(file:File,purpose:"avatar"|"branding"){
  if(!file.type.startsWith("image/"))throw new Error("Choose a PNG, JPEG, or WebP image.");
  return (await uploadFirebaseFile(file,purpose)).url;
}

export function AccountPage({ notify }: { notify: Notify }) {
  const {
    profile,
    sessions,
    updateProfile,
    revokeSession,
    revokeOtherSessions,
  } = useDashboardSettings();
  const { logout, changePassword: updatePassword } = useAuth();
  const [draft, setDraft] = useState(profile);
  const [editing, setEditing] = useState(false);
  const [passwords, setPasswords] = useState({
    current: "",
    next: "",
    confirm: "",
  });
  const [passwordError, setPasswordError] = useState("");
  useEffect(() => setDraft(profile), [profile]);
  const saveProfile = async () => {
    if (
      !draft.fullName.trim() ||
      !/^\S+@\S+\.\S+$/.test(draft.email) ||
      !draft.phone.trim()
    )
      return notify("Name, valid email, and phone are required");
    await updateProfile(draft);
    setEditing(false);
    notify("Account profile saved");
  };
  const changePassword = async () => {
    setPasswordError("");
    if (passwords.next.length < 10)
      return setPasswordError(
        "New password must contain at least 10 characters.",
      );
    if (passwords.next !== passwords.confirm)
      return setPasswordError("New passwords do not match.");
    if (!(await updatePassword(passwords.current, passwords.next)))
      return setPasswordError("Current password is incorrect.");
    setPasswords({ current: "", next: "", confirm: "" });
    notify("Password changed securely");
  };
  return (
    <div className="space-y-5">
      <Panel
        title="Account profile"
        subtitle="Identity used across audit logs and administrative workflows"
        action={
          <Button
            variant="secondary"
            onClick={() => (editing ? setDraft(profile) : setEditing(true))}
          >
            {editing ? "Reset" : "Edit profile"}
          </Button>
        }
      >
        <div className="grid gap-6 p-5 lg:grid-cols-[220px_1fr]">
          <div className="flex flex-col items-center rounded-2xl border border-white/[.07] bg-white/[.02] p-5 text-center">
            <div className="relative grid h-24 w-24 place-items-center overflow-hidden rounded-3xl bg-indigo-500/10 text-2xl font-semibold text-indigo-400">
              {profile.avatar ? (
                <img
                  src={profile.avatar}
                  alt="Profile"
                  className="h-full w-full object-cover"
                />
              ) : (
                profile.fullName
                  .split(" ")
                  .map((x) => x[0])
                  .join("")
              )}
            </div>
            <label className="btn-secondary mt-4 cursor-pointer">
              <Upload className="h-3.5 w-3.5" />
              Upload avatar
              <input
                hidden
                type="file"
                accept="image/*"
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if(file)uploadImage(file,"avatar").then((value)=>updateProfile({avatar:value})).then(()=>notify("Profile photo updated")).catch((error)=>notify(error instanceof Error?error.message:"Upload failed"));
                }}
              />
            </label>
            <p className="mt-3 text-[10px] text-zinc-600">
              PNG, JPEG, WebP or SVG · max 500 KB
            </p>
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            {(
              [
                ["fullName", "Full name"],
                ["email", "Email"],
                ["phone", "Phone"],
                ["jobTitle", "Job title"],
                ["department", "Department"],
                ["role", "Role"],
              ] as const
            ).map(([key, label]) => (
              <Field key={key} label={label}>
                <Input
                  disabled={!editing || key === "role"}
                  value={draft[key]}
                  onChange={(e) =>
                    setDraft({ ...draft, [key]: e.target.value })
                  }
                />
              </Field>
            ))}
            <Info label="Last login" value={profile.lastLogin} />
            <Info label="Last IP" value={profile.lastIp} />
            {editing && (
              <div className="flex justify-end gap-2 sm:col-span-2">
                <Button
                  variant="secondary"
                  onClick={() => {
                    setDraft(profile);
                    setEditing(false);
                  }}
                >
                  Cancel
                </Button>
                <Button onClick={saveProfile}>
                  <Save />
                  Save changes
                </Button>
              </div>
            )}
          </div>
        </div>
      </Panel>
      <div className="grid gap-5 xl:grid-cols-2">
        <Panel
          title="Password & two-factor authentication"
          subtitle="Database-backed password and two-factor controls"
        >
          <div className="space-y-3 p-5">
            <Input
              type="password"
              placeholder="Current password"
              value={passwords.current}
              onChange={(e) =>
                setPasswords({ ...passwords, current: e.target.value })
              }
            />
            <Input
              type="password"
              placeholder="New password"
              value={passwords.next}
              onChange={(e) =>
                setPasswords({ ...passwords, next: e.target.value })
              }
            />
            <Input
              type="password"
              placeholder="Confirm new password"
              value={passwords.confirm}
              onChange={(e) =>
                setPasswords({ ...passwords, confirm: e.target.value })
              }
            />
            {passwordError && (
              <p className="text-xs text-red-400">{passwordError}</p>
            )}
            <Button onClick={changePassword}>
              <KeyRound />
              Change password
            </Button>
            <div className="mt-4 flex items-center justify-between rounded-xl border border-white/[.07] p-3">
              <div>
                <b className="text-xs">Two-factor authentication</b>
                <p className="text-[10px] text-zinc-600">
                  Authenticator-app challenge simulation
                </p>
              </div>
              <Switch
                checked={profile.twoFactorEnabled}
                onClick={() => {
                  updateProfile({
                    twoFactorEnabled: !profile.twoFactorEnabled,
                  });
                  notify(
                    `Two-factor authentication ${profile.twoFactorEnabled ? "disabled" : "enabled"}`,
                  );
                }}
              />
            </div>
          </div>
        </Panel>
        <Panel
          title="Account actions"
          subtitle="Session and authentication controls"
        >
          <div className="space-y-3 p-5">
            <div className="flex items-center justify-between rounded-xl border border-white/[.07] p-3">
              <span>
                <b className="text-xs">Active sessions</b>
                <p className="text-[10px] text-zinc-600">
                  {sessions.filter((x) => x.active).length} devices currently
                  authorized
                </p>
              </span>
              <Button
                variant="secondary"
                size="sm"
                onClick={() => {
                  revokeOtherSessions();
                  notify("Other devices signed out");
                }}
              >
                Force logout others
              </Button>
            </div>
            <Button
              variant="destructive"
              className="w-full"
              onClick={() => {
                void logout();
              }}
            >
              <LogOut />
              Sign out of this device
            </Button>
          </div>
        </Panel>
      </div>
      <SessionTable
        sessions={sessions}
        revoke={revokeSession}
        notify={notify}
      />
    </div>
  );
}

export function SettingsPage({ notify }: { notify: Notify }) {
  const {
    settings,
    updateSettings,
    setBrandAsset,
    toggleNotification,
  } = useDashboardSettings();
  const { theme, setTheme, setLocale } = usePreferences();
  const [tab, setTab] = useState<
    | "general"
    | "branding"
    | "appearance"
    | "notifications"
    | "security"
    | "integrations"
  >("general");
  const [general, setGeneral] = useState(settings.general);
  useEffect(() => setGeneral(settings.general), [settings.general]);
  useEffect(
    () => setLocale(settings.general.language === "Arabic" ? "ar" : "en"),
    [setLocale, settings.general.language],
  );
  const tabs = [
    ["general", "General", Building2],
    ["branding", "Branding", Upload],
    ["appearance", "Appearance", Palette],
    ["notifications", "Notifications", Bell],
    ["security", "Security", ShieldCheck],
    ["integrations", "API Center", Link2],
  ] as const;
  const upload = (key: keyof DashboardSettings["branding"], file?: File) => {
    if(file)uploadImage(file,"branding").then((value)=>{setBrandAsset(key,value);notify(`${assetNames[key]} updated across the dashboard`)}).catch((error)=>notify(error instanceof Error?error.message:"Upload failed"));
  };
  return (
    <div className="grid gap-5 xl:grid-cols-[220px_1fr]">
      <div className="panel h-fit p-2">
        {tabs.map(([key, label, Icon]) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={cn(
              "flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs",
              tab === key
                ? "bg-white/[.08] text-white"
                : "text-zinc-500 hover:bg-white/[.04]",
            )}
          >
            <Icon className="h-4 w-4" />
            {label}
          </button>
        ))}
      </div>
      <div>
        {tab === "general" && (
          <Panel
            title="General settings"
            subtitle="Company defaults used throughout the control center"
          >
            <div className="grid gap-4 p-5 sm:grid-cols-2">
              {(
                [
                  ["companyName", "Company name"],
                  ["companyEmail", "Company email"],
                  ["companyPhone", "Company phone"],
                  ["companyAddress", "Company address"],
                ] as const
              ).map(([key, label]) => (
                <Field key={key} label={label}>
                  <Input
                    value={general[key]}
                    onChange={(e) =>
                      setGeneral({ ...general, [key]: e.target.value })
                    }
                  />
                </Field>
              ))}
              <Select
                label="Timezone"
                value={general.timezone}
                values={["Africa/Cairo", "UTC", "Asia/Riyadh", "Europe/London"]}
                set={(value) => setGeneral({ ...general, timezone: value })}
              />
              <Select
                label="Currency"
                value={general.currency}
                values={["EGP", "USD", "SAR", "AED"]}
                set={(value) => setGeneral({ ...general, currency: value })}
              />
              <Select
                label="Language"
                value={general.language}
                values={["English", "Arabic"]}
                set={(value) => setGeneral({ ...general, language: value })}
              />
              <Select
                label="Date format"
                value={general.dateFormat}
                values={["DD/MM/YYYY", "MM/DD/YYYY", "YYYY-MM-DD"]}
                set={(value) => setGeneral({ ...general, dateFormat: value })}
              />
              <div className="flex justify-end gap-2 sm:col-span-2">
                <Button
                  variant="secondary"
                  onClick={() => setGeneral(settings.general)}
                >
                  Cancel
                </Button>
                <Button
                  onClick={() => {
                    if (
                      !general.companyName ||
                      !/^\S+@\S+\.\S+$/.test(general.companyEmail)
                    )
                      return notify(
                        "Company name and valid email are required",
                      );
                    updateSettings({ general });
                    notify("General settings saved");
                  }}
                >
                  <Save />
                  Save changes
                </Button>
              </div>
            </div>
          </Panel>
        )}
        {tab === "branding" && (
          <Panel
            title="Branding assets"
            subtitle="Uploads update the running dashboard immediately"
          >
            <div className="grid gap-4 p-5 md:grid-cols-2">
              {(
                Object.keys(assetNames) as Array<
                  keyof DashboardSettings["branding"]
                >
              ).map((key) => (
                <div
                  key={key}
                  className="flex items-center gap-4 rounded-2xl border border-white/[.07] bg-white/[.02] p-4"
                >
                  <BrandLogo
                    location={
                      key === "sidebarLogo"
                        ? "sidebar"
                        : key === "loginLogo"
                          ? "login"
                          : key === "companyLogo"
                            ? "company"
                            : "dashboard"
                    }
                    className="h-16 w-16 bg-white/[.04]"
                  />
                  <div className="flex-1">
                    <b className="text-xs">{assetNames[key]}</b>
                    <p className="mt-1 text-[10px] text-zinc-600">
                      Maintains aspect ratio automatically
                    </p>
                    <label className="btn-secondary mt-3 cursor-pointer">
                      <Upload className="h-3.5 w-3.5" />
                      Replace
                      <input
                        hidden
                        type="file"
                        accept="image/*"
                        onChange={(e) => upload(key, e.target.files?.[0])}
                      />
                    </label>
                  </div>
                </div>
              ))}
            </div>
          </Panel>
        )}
        {tab === "appearance" && (
          <Panel
            title="Appearance"
            subtitle="Persisted for this administrator and browser"
          >
            <div className="space-y-5 p-5">
              <div>
                <b className="text-xs">Theme</b>
                <div className="mt-2 flex gap-2">
                  {(["dark", "light", "system"] as const).map((mode) => (
                    <Button
                      key={mode}
                      variant={theme === mode ? "default" : "secondary"}
                      onClick={() => {
                        setTheme(mode);
                        notify(`${mode} theme selected`);
                      }}
                      className="capitalize"
                    >
                      {mode === "system" ? <><Monitor />system</> : mode}
                    </Button>
                  ))}
                </div>
              </div>
              <Field label="Accent color">
                <div className="flex gap-3">
                  <input
                    aria-label="Accent color"
                    type="color"
                    value={settings.appearance.accentColor}
                    onChange={(e) =>
                      updateSettings({
                        appearance: {
                          ...settings.appearance,
                          accentColor: e.target.value,
                        },
                      })
                    }
                    className="h-10 w-14 rounded-lg border border-white/[.08] bg-transparent"
                  />
                  <Input
                    value={settings.appearance.accentColor}
                    onChange={(e) =>
                      updateSettings({
                        appearance: {
                          ...settings.appearance,
                          accentColor: e.target.value,
                        },
                      })
                    }
                  />
                </div>
              </Field>
              <div className="flex items-center justify-between rounded-xl border border-white/[.07] p-3">
                <span>
                  <b className="text-xs">Collapsed sidebar</b>
                  <p className="text-[10px] text-zinc-600">
                    Use a compact icon-only navigation rail
                  </p>
                </span>
                <Switch
                  checked={settings.appearance.sidebarCollapsed}
                  onClick={() => {
                    updateSettings({
                      appearance: {
                        ...settings.appearance,
                        sidebarCollapsed: !settings.appearance.sidebarCollapsed,
                      },
                    });
                    notify("Sidebar preference saved");
                  }}
                />
              </div>
            </div>
          </Panel>
        )}
        {tab === "notifications" && (
          <Panel
            title="Notification preferences"
            subtitle="Controls which operational events reach this administrator"
          >
            <div className="divide-y divide-white/[.06] p-5">
              {(
                [
                  ["email", "Email notifications"],
                  ["push", "Push notifications"],
                  ["jobs", "Job alerts"],
                  ["complaints", "Complaint alerts"],
                  ["finance", "Finance alerts"],
                  ["system", "System alerts"],
                ] as const
              ).map(([key, label]) => (
                <div
                  key={key}
                  className="flex items-center justify-between py-3"
                >
                  <span className="text-xs">{label}</span>
                  <Switch
                    checked={settings.notifications[key]}
                    onClick={() => {
                      toggleNotification(key);
                      notify(`${label} preference saved`);
                    }}
                  />
                </div>
              ))}
            </div>
          </Panel>
        )}
        {tab === "security" && <SecuritySettings notify={notify} />}
        {tab === "integrations" && (
          <Panel
            title="External Integrations / API Center"
            subtitle="Securely configure providers, credentials, tests, and activation without code changes"
          >
            <div className="p-5 pb-0"><IntegrationStatus/></div>
            <ApiCenter notify={notify} />
          </Panel>
        )}
      </div>
    </div>
  );
}

function IntegrationStatus(){
  const { getIdToken } = useAuth();
  const [checks,setChecks]=useState<Record<string,{configured:boolean;label:string;model?:string}>|null>(null);
  const [error,setError]=useState("");
  useEffect(()=>{let mounted=true;getIdToken().then((token)=>fetch("/api/firebase/integration-status",{headers:{authorization:`Bearer ${token}`}})).then(async(response)=>{const data=await response.json().catch(()=>({}));if(!response.ok)throw new Error(typeof data.error==="string"?data.error:"Integration status unavailable");if(mounted)setChecks(data as Record<string,{configured:boolean;label:string;model?:string}>)}).catch((reason)=>{if(mounted)setError(reason instanceof Error?reason.message:"Integration status unavailable")});return()=>{mounted=false}},[getIdToken]);
  if(error)return <div className="rounded-xl border border-amber-500/25 bg-amber-500/10 p-3 text-xs text-amber-200">{error}</div>;
  if(!checks)return <div className="rounded-xl border border-white/[.07] bg-white/[.02] p-3 text-xs text-zinc-500">Checking secure server integrations…</div>;
  return <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-6">{Object.entries(checks).map(([key,item])=><div key={key} className="rounded-xl border border-white/[.07] bg-white/[.02] p-3"><div className={cn("text-[10px] font-medium",item.configured?"text-emerald-400":"text-amber-400")}>● {item.configured?"Configured":"Missing"}</div><div className="mt-1 text-xs">{item.label}</div>{item.model&&<div className="mt-1 text-[10px] text-zinc-600">{item.model}</div>}</div>)}</div>;
}

type ApiIntegration = {
  id: string;
  category: string;
  provider: string;
  providerName: string;
  defaultModel?: string;
  baseUrl?: string;
  mode: "sandbox" | "live";
  enabled: boolean;
  status: "untested" | "success" | "failed" | "disabled";
  maskedCredentials: Record<string, string>;
  lastSuccessfulTest?: string;
  lastError?: string;
  updatedAt: string;
};

function ApiCenter({ notify }: { notify: Notify }) {
  const { getIdToken, user } = useAuth();
  const { can } = usePermissions();
  const [items, setItems] = useState<ApiIntegration[]>([]);
  const [category, setCategory] = useState("AI Providers");
  const [selected, setSelected] = useState<ApiIntegration | null>(null);
  const [draft, setDraft] = useState({
    apiKey: "",
    secretKey: "",
    webhookSecret: "",
    clientId: "",
    clientSecret: "",
    defaultModel: "",
    baseUrl: "",
    mode: "sandbox" as "sandbox" | "live",
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const token = await getIdToken();
      const response = await fetch("/api/firebase/integrations", {
        headers: { authorization: `Bearer ${token}` },
      });
      const data = (await response.json().catch(() => ({}))) as {
        integrations?: ApiIntegration[];
        error?: string;
      };
      if (!response.ok) throw new Error(data.error ?? "API Center unavailable");
      setItems(data.integrations ?? []);
      setSelected((current) => current ? (data.integrations ?? []).find((item) => item.provider === current.provider) ?? null : (data.integrations ?? [])[0] ?? null);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "API Center unavailable");
    } finally {
      setLoading(false);
    }
  }, [getIdToken]);
  useEffect(() => { void load(); }, [load]);
  useEffect(() => {
    if (!selected) return;
    setDraft({
      apiKey: "",
      secretKey: "",
      webhookSecret: "",
      clientId: "",
      clientSecret: "",
      defaultModel: selected.defaultModel ?? "",
      baseUrl: selected.baseUrl ?? "",
      mode: selected.mode ?? "sandbox",
    });
  }, [selected]);
  const categories = Array.from(new Set(items.map((item) => item.category)));
  const filtered = items.filter((item) => item.category === category);
  const request = async (action: "save" | "test" | "enable" | "disable" | "delete") => {
    if (!selected) return;
    setSaving(true);
    setError("");
    try {
      const token = await getIdToken();
      const response = await fetch("/api/firebase/integrations", {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
        body: JSON.stringify({
          action,
          provider: selected.provider,
          defaultModel: draft.defaultModel,
          baseUrl: draft.baseUrl,
          mode: draft.mode,
          credentials: {
            apiKey: draft.apiKey || undefined,
            secretKey: draft.secretKey || undefined,
            webhookSecret: draft.webhookSecret || undefined,
            clientId: draft.clientId || undefined,
            clientSecret: draft.clientSecret || undefined,
          },
        }),
      });
      const data = (await response.json().catch(() => ({}))) as { error?: string; message?: string };
      if (!response.ok) throw new Error(data.error ?? `${action} failed`);
      notify(data.message ?? `${selected.providerName} ${action} completed`);
      await load();
    } catch (reason) {
      const message = reason instanceof Error ? reason.message : `${action} failed`;
      setError(message);
      notify(message);
    } finally {
      setSaving(false);
    }
  };
  if (!can("settings.integrations.apiCenter.view"))
    return <div className="p-5 text-xs text-zinc-500">You do not have permission to view API Center.</div>;
  return (
    <div className="grid gap-5 p-5 xl:grid-cols-[280px_1fr]">
      <div className="space-y-3">
        <SearchableSelect value={category} onChange={setCategory} allowEmpty={false} options={categories.map((value)=>({label:value,value}))} className="w-full" />
        <div className="space-y-2">
          {loading && <div className="rounded-xl border border-white/[.07] p-3 text-xs text-zinc-500">Loading API providers…</div>}
          {filtered.map((item) => (
            <button key={item.provider} onClick={() => setSelected(item)} className={cn("w-full rounded-xl border p-3 text-left transition", selected?.provider===item.provider?"border-indigo-400/40 bg-indigo-500/10":"border-white/[.07] bg-white/[.02] hover:bg-white/[.04]")}>
              <div className="flex items-center justify-between gap-2">
                <span className="text-xs font-semibold">{item.providerName}</span>
                <span className={cn("rounded-full px-2 py-0.5 text-[9px]", item.enabled?"bg-emerald-500/10 text-emerald-400":"bg-zinc-500/10 text-zinc-500")}>{item.enabled?"Enabled":"Disabled"}</span>
              </div>
              <div className={cn("mt-2 text-[10px]", item.status==="success"?"text-emerald-400":item.status==="failed"?"text-red-400":"text-zinc-500")}>● {item.status}</div>
            </button>
          ))}
        </div>
      </div>
      <div className="rounded-2xl border border-white/[.07] bg-white/[.02] p-5">
        {!selected ? <div className="text-xs text-zinc-500">Choose an integration provider.</div> : (
          <div className="space-y-5">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h3 className="text-lg font-semibold">{selected.providerName}</h3>
                <p className="mt-1 text-xs text-zinc-500">{selected.category} · credentials encrypted server-side</p>
              </div>
              <div className="flex flex-wrap gap-2">
                {can("settings.integrations.apiCenter.test") && <Button variant="secondary" disabled={saving} onClick={()=>request("test")}>Test connection</Button>}
                {!selected.enabled && can("settings.integrations.apiCenter.enable") && <Button disabled={saving} onClick={()=>request("enable")}>Activate</Button>}
                {selected.enabled && can("settings.integrations.apiCenter.disable") && <Button variant="secondary" disabled={saving} onClick={()=>request("disable")}>Deactivate</Button>}
                {can("settings.integrations.apiCenter.delete") && <Button variant="destructive" disabled={saving} onClick={()=>request("delete")}><Trash2 className="h-3.5 w-3.5" />Delete</Button>}
              </div>
            </div>
            {user?.isDemoUser && <div className="rounded-xl border border-amber-400/20 bg-amber-400/10 p-3 text-xs text-amber-100">Demo mode uses simulated integrations and never stores real credentials.</div>}
            {error && <div className="rounded-xl border border-red-500/20 bg-red-500/10 p-3 text-xs text-red-200">{error}</div>}
            <div className="grid gap-4 md:grid-cols-2">
              <Field label="Default model"><Input value={draft.defaultModel} onChange={(e)=>setDraft({...draft,defaultModel:e.target.value})} placeholder="gpt-4.1-mini or gemini-3.5-flash" /></Field>
              <Select label="Mode" value={draft.mode} values={["sandbox","live"]} set={(value)=>setDraft({...draft,mode:value as "sandbox"|"live"})} />
              <Field label="Base URL"><Input value={draft.baseUrl} onChange={(e)=>setDraft({...draft,baseUrl:e.target.value})} placeholder="https://api.provider.com" /></Field>
              <Info label="Last successful test" value={selected.lastSuccessfulTest ? new Date(selected.lastSuccessfulTest).toLocaleString() : "Never"} />
              <Field label={`API key ${selected.maskedCredentials.apiKey ? `(${selected.maskedCredentials.apiKey})` : ""}`}><Input type="password" value={draft.apiKey} onChange={(e)=>setDraft({...draft,apiKey:e.target.value})} placeholder="Paste new API key to set or rotate" /></Field>
              <Field label={`Secret key ${selected.maskedCredentials.secretKey ? `(${selected.maskedCredentials.secretKey})` : ""}`}><Input type="password" value={draft.secretKey} onChange={(e)=>setDraft({...draft,secretKey:e.target.value})} placeholder="Optional secret key" /></Field>
              <Field label={`Webhook secret ${selected.maskedCredentials.webhookSecret ? `(${selected.maskedCredentials.webhookSecret})` : ""}`}><Input type="password" value={draft.webhookSecret} onChange={(e)=>setDraft({...draft,webhookSecret:e.target.value})} placeholder="Optional webhook secret" /></Field>
              <Field label={`Client ID ${selected.maskedCredentials.clientId ? `(${selected.maskedCredentials.clientId})` : ""}`}><Input value={draft.clientId} onChange={(e)=>setDraft({...draft,clientId:e.target.value})} placeholder="Optional client ID" /></Field>
              <Field label={`Client secret ${selected.maskedCredentials.clientSecret ? `(${selected.maskedCredentials.clientSecret})` : ""}`}><Input type="password" value={draft.clientSecret} onChange={(e)=>setDraft({...draft,clientSecret:e.target.value})} placeholder="Optional client secret" /></Field>
              <Info label="Last error" value={selected.lastError || "None"} />
            </div>
            <div className="flex justify-end gap-2">
              <Button variant="secondary" onClick={()=>setSelected({...selected})}>Cancel</Button>
              {(can("settings.integrations.apiCenter.edit") || can("settings.integrations.apiCenter.rotateKey")) && <Button disabled={saving} onClick={()=>request("save")}><Save className="h-3.5 w-3.5" />Save encrypted credentials</Button>}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

const assetNames: Record<keyof DashboardSettings["branding"], string> = {
  companyLogo: "Company logo",
  dashboardLogo: "Dashboard logo",
  favicon: "Browser favicon",
  loginLogo: "Login logo",
  sidebarLogo: "Sidebar logo",
};
function Panel({
  title,
  subtitle,
  action,
  children,
}: {
  title: string;
  subtitle: string;
  action?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <section className="panel overflow-hidden">
      <div className="flex items-center justify-between border-b border-white/[.06] p-4">
        <div>
          <h2 className="text-sm font-semibold">{title}</h2>
          <p className="mt-1 text-[10px] text-zinc-600">{subtitle}</p>
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}
function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <label>
      <span className="mb-2 block text-[11px] text-zinc-400">{label}</span>
      {children}
    </label>
  );
}
function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-white/[.07] bg-white/[.02] p-3">
      <div className="text-[10px] text-zinc-600">{label}</div>
      <div className="mt-1 text-xs">{value}</div>
    </div>
  );
}
function Select({
  label,
  value,
  values,
  set,
}: {
  label: string;
  value: string;
  values: string[];
  set: (value: string) => void;
}) {
  return (
    <Field label={label}>
      <SearchableSelect
        value={value}
        onChange={set}
        allowEmpty={false}
        className="w-full"
        options={values.map((item) => ({ label: item, value: item }))}
      />
    </Field>
  );
}
function Switch({
  checked,
  onClick,
}: {
  checked: boolean;
  onClick: () => void;
}) {
  return (
    <button
      role="switch"
      aria-checked={checked}
      onClick={onClick}
      className={cn(
        "relative h-6 w-11 rounded-full transition",
        checked ? "bg-indigo-500" : "bg-zinc-700",
      )}
    >
      <span
        className={cn(
          "absolute top-1 h-4 w-4 rounded-full bg-white transition",
          checked ? "left-6" : "left-1",
        )}
      />
    </button>
  );
}
function SessionTable({
  sessions,
  revoke,
  notify,
}: {
  sessions: ReturnType<typeof useDashboardSettings>["sessions"];
  revoke: (id: string) => void;
  notify: Notify;
}) {
  return (
    <Panel
      title="Session history"
      subtitle="Active sessions and previously connected devices"
    >
      <div className="divide-y divide-white/[.06]">
        {sessions.map((item) => (
          <div key={item.id} className="flex flex-wrap items-center gap-3 p-4">
            <span className="grid h-9 w-9 place-items-center rounded-xl bg-white/[.04]">
              {item.device.includes("iPhone") ? (
                <Smartphone className="h-4 w-4" />
              ) : (
                <Laptop className="h-4 w-4" />
              )}
            </span>
            <span className="min-w-[180px] flex-1">
              <b className="block text-xs">
                {item.device}
                {item.current && (
                  <span className="ml-2 text-[9px] text-emerald-400">
                    Current
                  </span>
                )}
              </b>
              <small className="text-[10px] text-zinc-600">
                {item.browser} · {item.location} · {item.ip}
              </small>
            </span>
            <span className="text-[10px] text-zinc-500">{item.lastActive}</span>
            <span
              className={cn(
                "rounded-full px-2 py-1 text-[9px]",
                item.active
                  ? "bg-emerald-500/10 text-emerald-400"
                  : "bg-white/[.04] text-zinc-600",
              )}
            >
              {item.active ? "Active" : "Signed out"}
            </span>
            {item.active && !item.current && (
              <Button
                size="sm"
                variant="secondary"
                onClick={() => {
                  revoke(item.id);
                  notify(`${item.device} signed out`);
                }}
              >
                Revoke
              </Button>
            )}
          </div>
        ))}
      </div>
    </Panel>
  );
}
function SecuritySettings({ notify }: { notify: Notify }) {
  const {
    profile,
    sessions,
    updateProfile,
    revokeSession,
    revokeOtherSessions,
  } = useDashboardSettings();
  const { changePassword } = useAuth();
  const [passwords, setPasswords] = useState({
    current: "",
    next: "",
    confirm: "",
  });
  const [error, setError] = useState("");
  const change = async () => {
    setError("");
    if (passwords.next.length < 10)
      return setError("New password must contain at least 10 characters.");
    if (passwords.next !== passwords.confirm)
      return setError("New passwords do not match.");
    if (!(await changePassword(passwords.current, passwords.next)))
      return setError("Current password is incorrect.");
    setPasswords({ current: "", next: "", confirm: "" });
    notify("Password changed securely");
  };
  return (
    <div className="space-y-5">
      <Panel
        title="Change password"
        subtitle="Validated server-side against your encrypted credential"
      >
        <div className="grid gap-3 p-5 sm:grid-cols-3">
          <Input
            type="password"
            placeholder="Current password"
            value={passwords.current}
            onChange={(e) =>
              setPasswords({ ...passwords, current: e.target.value })
            }
          />
          <Input
            type="password"
            placeholder="New password"
            value={passwords.next}
            onChange={(e) =>
              setPasswords({ ...passwords, next: e.target.value })
            }
          />
          <Input
            type="password"
            placeholder="Confirm password"
            value={passwords.confirm}
            onChange={(e) =>
              setPasswords({ ...passwords, confirm: e.target.value })
            }
          />
          {error && (
            <p className="text-xs text-red-400 sm:col-span-3">{error}</p>
          )}
          <div className="sm:col-span-3">
            <Button onClick={change}>
              <KeyRound />
              Change password
            </Button>
          </div>
        </div>
      </Panel>
      <Panel
        title="Security controls"
        subtitle="Authentication and device policy"
      >
        <div className="space-y-3 p-5">
          <div className="flex items-center justify-between rounded-xl border border-white/[.07] p-3">
            <span>
              <b className="text-xs">Two-factor authentication</b>
              <p className="text-[10px] text-zinc-600">
                Authenticator enrollment status
              </p>
            </span>
            <Switch
              checked={profile.twoFactorEnabled}
              onClick={() => {
                updateProfile({ twoFactorEnabled: !profile.twoFactorEnabled });
                notify("Two-factor setting saved");
              }}
            />
          </div>
          <Button
            variant="destructive"
            onClick={() => {
              revokeOtherSessions();
              notify("All other active sessions revoked");
            }}
          >
            Force logout other devices
          </Button>
        </div>
      </Panel>
      <SessionTable
        sessions={sessions}
        revoke={revokeSession}
        notify={notify}
      />
    </div>
  );
}
