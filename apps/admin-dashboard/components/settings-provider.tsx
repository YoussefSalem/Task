"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { collection, doc, onSnapshot, setDoc, updateDoc } from "firebase/firestore";
import { useAuth } from "@/components/auth-provider";
import { getFirebaseClient } from "@/lib/firebase/client";

export interface AccountProfile {
  avatar: string;
  fullName: string;
  email: string;
  phone: string;
  jobTitle: string;
  department: string;
  role: string;
  lastLogin: string;
  lastIp: string;
  twoFactorEnabled: boolean;
}
export interface SessionRecord {
  id: string;
  device: string;
  browser: string;
  location: string;
  ip: string;
  lastActive: string;
  current: boolean;
  active: boolean;
}
export interface DashboardSettings {
  general: {
    companyName: string;
    companyEmail: string;
    companyPhone: string;
    companyAddress: string;
    timezone: string;
    currency: string;
    language: string;
    dateFormat: string;
  };
  branding: {
    companyLogo: string;
    dashboardLogo: string;
    favicon: string;
    loginLogo: string;
    sidebarLogo: string;
  };
  appearance: { accentColor: string; sidebarCollapsed: boolean };
  notifications: Record<
    "email" | "push" | "jobs" | "complaints" | "finance" | "system",
    boolean
  >;
  integrations: Record<
    | "firebase"
    | "googleMaps"
    | "resend"
    | "gemini"
    | "twilio"
    | "stripe"
    | "instapay"
    | "supabase",
    { enabled: boolean; value: string; updatedAt?: string }
  >;
}

const logo = "/task-logo.svg";
const initialSettings: DashboardSettings = {
  general: {
    companyName: "Task",
    companyEmail: "operations@task.app",
    companyPhone: "+20 2 5555 0100",
    companyAddress: "Cairo, Egypt",
    timezone: "Africa/Cairo",
    currency: "EGP",
    language: "English",
    dateFormat: "DD/MM/YYYY",
  },
  branding: {
    companyLogo: logo,
    dashboardLogo: logo,
    favicon: logo,
    loginLogo: logo,
    sidebarLogo: logo,
  },
  appearance: { accentColor: "#6366f1", sidebarCollapsed: false },
  notifications: {
    email: true,
    push: true,
    jobs: true,
    complaints: true,
    finance: true,
    system: true,
  },
  integrations: {
    firebase: { enabled: false, value: "" },
    googleMaps: { enabled: false, value: "" },
    resend: { enabled: false, value: "" },
    gemini: { enabled: false, value: "" },
    twilio: { enabled: false, value: "" },
    stripe: { enabled: false, value: "" },
    instapay: { enabled: false, value: "" },
    supabase: { enabled: false, value: "" },
  },
};
const initialProfile: AccountProfile = {
  avatar: "",
  fullName: "",
  email: "",
  phone: "",
  jobTitle: "",
  department: "",
  role: "",
  lastLogin: "Never",
  lastIp: "Unknown",
  twoFactorEnabled: false,
};
const initialSessions: SessionRecord[] = [];
const reportSettingsError=(error:unknown)=>window.dispatchEvent(new CustomEvent("task:operation-error",{detail:{message:error instanceof Error?error.message:"Settings could not be saved"}}));

interface SettingsContextValue {
  settings: DashboardSettings;
  profile: AccountProfile;
  sessions: SessionRecord[];
  updateSettings: (patch: Partial<DashboardSettings>) => void;
  updateProfile: (patch: Partial<AccountProfile>) => Promise<void>;
  setBrandAsset: (
    key: keyof DashboardSettings["branding"],
    value: string,
  ) => void;
  toggleNotification: (key: keyof DashboardSettings["notifications"]) => void;
  saveIntegration: (
    key: keyof DashboardSettings["integrations"],
    value: string,
    enabled: boolean,
  ) => void;
  revokeSession: (id: string) => Promise<void>;
  revokeOtherSessions: () => Promise<void>;
}
const SettingsContext = createContext<SettingsContextValue | null>(null);
export function SettingsProvider({ children }: { children: React.ReactNode }) {
  const { user, loading: authLoading, getIdToken } = useAuth();
  const [settings, setSettings] = useState(initialSettings);
  const [profile, setProfile] = useState(initialProfile);
  const [sessions, setSessions] = useState(initialSessions);
  useEffect(() => {
    if(authLoading||!user)return;const{db}=getFirebaseClient();const unsubSettings=onSnapshot(doc(db,"settings","dashboard"),(snapshot)=>{if(snapshot.exists())setSettings(snapshot.data() as DashboardSettings)});const unsubAdmin=onSnapshot(doc(db,"admins",user.id),(snapshot)=>{const data=snapshot.data()??{};setProfile({avatar:String(data.avatar??""),fullName:String(data.name??user.name),email:String(data.email??user.email),phone:String(data.phone??""),jobTitle:String(data.jobTitle??""),department:String(data.department??""),role:String(data.role??user.role),lastLogin:String(data.lastSeen??"Never"),lastIp:"Firebase Auth",twoFactorEnabled:Boolean(data.twoFactorEnabled)})});const unsubSessions=onSnapshot(collection(db,"admins",user.id,"sessions"),(snapshot)=>setSessions(snapshot.docs.map((item)=>item.data() as SessionRecord)));return()=>{unsubSettings();unsubAdmin();unsubSessions()}
  }, [authLoading,user]);
  useEffect(() => {
    document.documentElement.style.setProperty(
      "--brand-accent",
      settings.appearance.accentColor,
    );
    const favicon =
      document.querySelector<HTMLLinkElement>('link[rel="icon"]') ??
      document.head.appendChild(
        Object.assign(document.createElement("link"), { rel: "icon" }),
      );
    favicon.href = settings.branding.favicon || logo;
  }, [settings]);
  const value = useMemo<SettingsContextValue>(
    () => ({
      settings,
      profile,
      sessions,
      updateSettings(patch) {
        setSettings((current) => {const next={...current,...patch};void setDoc(doc(getFirebaseClient().db,"settings","dashboard"),next).catch((error)=>window.dispatchEvent(new CustomEvent("task:operation-error",{detail:{message:error instanceof Error?error.message:"Settings could not be saved"}})));return next});
      },
      async updateProfile(patch) {
        if(!user)throw new Error("Sign in required");const token=await getIdToken();const response=await fetch("/api/firebase/admin-users",{method:"POST",headers:{"content-type":"application/json",authorization:`Bearer ${token}`},body:JSON.stringify({action:"update-profile",id:user.id,patch:{name:patch.fullName??profile.fullName,email:patch.email??profile.email,phone:patch.phone??profile.phone,jobTitle:patch.jobTitle??profile.jobTitle,department:patch.department??profile.department,avatar:patch.avatar??profile.avatar,twoFactorEnabled:patch.twoFactorEnabled??profile.twoFactorEnabled}})});const data=await response.json().catch(()=>({}));if(!response.ok)throw new Error(typeof data.error==="string"?data.error:"Account update failed");setProfile((current) => ({ ...current, ...patch }));
      },
      setBrandAsset(key, asset) {
        setSettings((current) => {const next={...current,branding:{...current.branding,[key]:asset}};void setDoc(doc(getFirebaseClient().db,"settings","dashboard"),next).catch(reportSettingsError);return next});
      },
      toggleNotification(key) {
        setSettings((current) => {const next={...current,notifications:{...current.notifications,[key]:!current.notifications[key]}};void setDoc(doc(getFirebaseClient().db,"settings","dashboard"),next).catch(reportSettingsError);return next});
      },
      saveIntegration(key, integrationValue, enabled) {
        setSettings((current) => {const next={...current,integrations:{...current.integrations,[key]:{value:integrationValue,enabled,updatedAt:new Date().toISOString()}}};void setDoc(doc(getFirebaseClient().db,"settings","dashboard"),next).catch(reportSettingsError);return next});
      },
      async revokeSession(id) {
        if(!user)throw new Error("Sign in required");await updateDoc(doc(getFirebaseClient().db,"admins",user.id,"sessions",id),{active:false,current:false,lastActive:new Date().toISOString()});setSessions((current) =>
          current.map((item) =>
            item.id === id && !item.current ? { ...item, active: false } : item,
          ),
        );
      },
      async revokeOtherSessions() {
        if(!user)throw new Error("Sign in required");const batch=(await import("firebase/firestore")).writeBatch(getFirebaseClient().db);sessions.filter((item)=>!item.current&&item.active).forEach((item)=>batch.update(doc(getFirebaseClient().db,"admins",user.id,"sessions",item.id),{active:false,lastActive:new Date().toISOString()}));await batch.commit();setSessions((current) =>
          current.map((item) =>
            item.current ? item : { ...item, active: false },
          ),
        );
      },
    }),
    [getIdToken, profile, sessions, settings, user],
  );
  return (
    <SettingsContext.Provider value={value}>
      {children}
    </SettingsContext.Provider>
  );
}
export function useDashboardSettings() {
  const value = useContext(SettingsContext);
  if (!value) throw new Error("useDashboardSettings requires SettingsProvider");
  return value;
}
