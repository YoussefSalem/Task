"use client";
import { createContext, useContext, useEffect, useMemo, useRef, useState } from "react";
import { doc, onSnapshot, updateDoc } from "firebase/firestore";
import { useAuth } from "@/components/auth-provider";
import { getFirebaseClient } from "@/lib/firebase/client";

export type ThemeMode = "dark" | "light" | "system";
export type Locale = "en" | "ar";

const ar: Record<string, string> = {
  Overview: "نظرة عامة",
  "Live operations": "مركز العمليات",
  Jobs: "إدارة الطلبات",
  Providers: "مقدمو الخدمات",
  Customers: "العملاء",
  "Trust & safety": "الثقة والأمان",
  Payments: "المدفوعات والمحفظة",
  "Services & pricing": "الخدمات والتسعير",
  Promotions: "العروض والتسويق",
  Analytics: "التحليلات",
  "Admin & roles": "المشرفون والصلاحيات",
  Account: "الحساب",
  Settings: "الإعدادات",
  "Settings Center": "مركز الإعدادات",
  "Profile, authentication, sessions, and connected devices.": "الملف الشخصي والمصادقة والجلسات والأجهزة المتصلة.",
  "Company, branding, appearance, notifications, security, and integrations.": "الشركة والهوية والمظهر والإشعارات والأمان والتكاملات.",
  "Operations overview": "نظرة عامة على العمليات",
  "Here’s how Task is moving across Cairo today.":
    "إليك حركة منصة تاسك في القاهرة اليوم.",
  "Live Operations Center": "مركز العمليات المباشرة",
  "Real-time dispatch, alerts, and provider coverage.":
    "الإسناد والتنبيهات وتغطية مقدمي الخدمة لحظة بلحظة.",
  "Jobs Management": "إدارة الطلبات",
  "Track every booking from request to completion.":
    "تابع كل حجز من الطلب حتى الإتمام.",
  "Provider Management": "إدارة مقدمي الخدمات",
  "Performance, verification, and marketplace quality.":
    "الأداء والتحقق وجودة السوق.",
  "Customer Management": "إدارة العملاء",
  "Profiles, history, refunds, and account health.":
    "الملفات والسجل والمبالغ المستردة وحالة الحساب.",
  "Trust & Safety Center": "مركز الثقة والأمان",
  "Resolve incidents with speed, context, and care.":
    "حل البلاغات بسرعة ودقة وعناية.",
  "Payments & Wallet": "المدفوعات والمحفظة",
  "Transactions, settlements, and cash reconciliation.":
    "المعاملات والتسويات ومطابقة النقدية.",
  "Services & Pricing": "الخدمات والتسعير",
  "Control availability, fees, and marketplace economics.":
    "تحكم في الإتاحة والرسوم واقتصاديات المنصة.",
  "Promotions & Marketing": "العروض والتسويق",
  "Campaigns, promo codes, and customer engagement.":
    "الحملات وأكواد الخصم وتفاعل العملاء.",
  "Admin Users & Roles": "المشرفون والصلاحيات",
  "People, permissions, and the audit trail.":
    "المستخدمون والصلاحيات وسجل التدقيق.",
  "Search jobs, providers, customers...": "ابحث عن طلب أو مقدم خدمة أو عميل...",
  "All systems operational": "جميع الأنظمة تعمل",
  Today: "اليوم",
  "Live Firestore": "فايرستور مباشر",
  Export: "تصدير",
  "Active jobs": "الطلبات النشطة",
  Delayed: "متأخر",
  Unassigned: "غير مسند",
  "Providers online": "مقدمو الخدمة المتصلون",
  Emergency: "طوارئ",
  "Dispatch queue": "قائمة الإسناد",
  "Operational command center": "مركز التحكم التشغيلي",
  Area: "المنطقة",
  Service: "الخدمة",
  Status: "الحالة",
  Provider: "مقدم الخدمة",
  Priority: "الأولوية",
  All: "الكل",
  "Assign provider": "إسناد مقدم خدمة",
  "Add note": "إضافة ملاحظة",
  Escalate: "تصعيد",
  "View details": "عرض التفاصيل",
  Available: "متاح",
  Busy: "مشغول",
  Offline: "غير متصل",
  Save: "حفظ",
  Cancel: "إلغاء",
  Create: "إنشاء",
  Edit: "تعديل",
  Delete: "حذف",
  Approve: "موافقة",
  Reject: "رفض",
  Suspend: "إيقاف",
  Ban: "حظر",
  Refund: "استرداد",
  Search: "بحث",
  "No results": "لا توجد نتائج",
  English: "الإنجليزية",
  Arabic: "العربية",
  Theme: "المظهر",
  Language: "اللغة",
  Dark: "داكن",
  Light: "فاتح",
  System: "النظام",
  "is required": "مطلوب",
  "Enter a valid email": "أدخل بريداً إلكترونياً صحيحاً",
  "Select…": "اختر…",
  "Save changes": "حفظ التغييرات",
  "Create job": "إنشاء طلب",
  "Create customer": "إنشاء عميل",
  "Create provider": "إنشاء مقدم خدمة",
  "Send invitation": "إرسال الدعوة",
  "Full name": "الاسم الكامل",
  "Work email": "البريد الإلكتروني للعمل",
  Phone: "الهاتف",
  Role: "الدور",
  Name: "الاسم",
  Email: "البريد الإلكتروني",
  Active: "نشط",
  Suspended: "موقوف",
  Pending: "قيد الانتظار",
  Completed: "مكتمل",
  Cancelled: "ملغي",
  Refunded: "مسترد",
  Assigned: "مسند",
  "In progress": "قيد التنفيذ",
  "En route": "في الطريق",
};

interface PreferencesValue {
  theme: ThemeMode;
  setTheme: (mode: ThemeMode) => void;
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (text: string) => string;
}
const PreferencesContext = createContext<PreferencesValue | null>(null);

export function AppPreferencesProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const [theme, setThemeState] = useState<ThemeMode>("dark");
  const [locale, setLocaleState] = useState<Locale>("en");
  const{user}=useAuth();
  const themeReady = useRef(false); const localeReady = useRef(false);
  useEffect(()=>{if(!user)return;return onSnapshot(doc(getFirebaseClient().db,"admins",user.id),(snapshot)=>{const data=snapshot.data();if(data?.theme)setThemeState(data.theme as ThemeMode);if(data?.locale)setLocaleState(data.locale as Locale);themeReady.current=true;localeReady.current=true})},[user]);
  useEffect(() => {
    if (!themeReady.current) { themeReady.current = true; return; }
    const root = document.documentElement;
    const dark =
      theme === "dark" ||
      (theme === "system" &&
        matchMedia("(prefers-color-scheme: dark)").matches);
    root.classList.toggle("dark", dark);
    root.classList.toggle("light", !dark);
    root.style.colorScheme = dark ? "dark" : "light";
  }, [theme]);
  useEffect(() => {
    if (!localeReady.current) { localeReady.current = true; return; }
    const root = document.documentElement;
    root.lang = locale;
    root.dir = locale === "ar" ? "rtl" : "ltr";
  }, [locale]);
  const value = useMemo<PreferencesValue>(
    () => ({
      theme,
      setTheme: (v) => {setThemeState(v);if(user)updateDoc(doc(getFirebaseClient().db,"admins",user.id),{theme:v})},
      locale,
      setLocale: (v) => {setLocaleState(v);if(user)updateDoc(doc(getFirebaseClient().db,"admins",user.id),{locale:v})},
      t: (text) => (locale === "ar" ? (ar[text] ?? text) : text),
    }),
    [theme, locale, user],
  );
  return (
    <PreferencesContext.Provider value={value}>
      {children}
    </PreferencesContext.Provider>
  );
}
export function usePreferences() {
  const value = useContext(PreferencesContext);
  if (!value) throw new Error("usePreferences requires AppPreferencesProvider");
  return value;
}
