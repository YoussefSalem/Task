"use client";

import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import {
  EmailAuthProvider,
  browserLocalPersistence,
  type User,
  onAuthStateChanged,
  reauthenticateWithCredential,
  signInWithEmailAndPassword,
  signOut,
  setPersistence,
  updatePassword,
} from "firebase/auth";
import { useRouter } from "next/navigation";
import {
  collection,
  doc,
  getDocs,
  setDoc,
  updateDoc,
  writeBatch,
} from "firebase/firestore";
import { getFirebaseClient } from "@/lib/firebase/client";
import type { AdminUser } from "@/lib/types";

interface AuthContextValue {
  user: AdminUser | null;
  loading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  changePassword: (current: string, next: string) => Promise<boolean>;
  getIdToken: () => Promise<string>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function authLog(message: string, meta?: Record<string, unknown>) {
  console.info(`[Task Admin Auth] ${message}`, meta ?? {});
}

function clearStorage(storage: Storage | undefined, all = false) {
  if (!storage) return;
  for (const key of Object.keys(storage)) {
    const normalized = key.toLowerCase();
    if (
      all ||
      normalized.includes("firebase:authuser") ||
      normalized.includes("firebase:redirectuser") ||
      normalized.startsWith("task-admin-auth")
    ) {
      storage.removeItem(key);
    }
  }
}

function clearDashboardCookies() {
  if (typeof document === "undefined") return;
  for (const cookie of document.cookie.split(";")) {
    const name = cookie.split("=")[0]?.trim();
    if (!name) continue;
    document.cookie = `${name}=; Max-Age=0; path=/; SameSite=Lax`;
    document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/`;
  }
}

async function deleteIndexedDb(name: string) {
  if (typeof indexedDB === "undefined") return;
  await new Promise<void>((resolve) => {
    const request = indexedDB.deleteDatabase(name);
    request.onsuccess = () => resolve();
    request.onerror = () => resolve();
    request.onblocked = () => resolve();
  });
}

async function clearBrowserAuthCaches(all = false) {
  if (typeof window === "undefined") return;
  clearStorage(window.localStorage, all);
  clearStorage(window.sessionStorage, all);
  if (all) clearDashboardCookies();
  if (all) await deleteIndexedDb("firebaseLocalStorageDb");
  authLog("storage/cookies cleared", { all });
}

function firebaseLoginError(error: unknown) {
  const code = (error as { code?: string }).code;
  if (code === "auth/invalid-credential" || code === "auth/wrong-password")
    return "Invalid email or password.";
  if (code === "auth/user-disabled")
    return "This administrator account is disabled.";
  if (error instanceof Error && error.message.includes("demo account has expired"))
    return "This demo account has expired. Please contact Task to continue.";
  if (code === "auth/user-not-found")
    return "No Firebase user exists for this email address.";
  if (code === "auth/too-many-requests")
    return "Too many failed attempts. Try again later or reset the password.";
  return error instanceof Error ? error.message : "Authentication failed.";
}

async function withTimeout<T>(work: Promise<T>, message: string, timeoutMs = 15000) {
  let timeoutId: number | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timeoutId = window.setTimeout(() => reject(new Error(message)), timeoutMs);
  });
  try {
    return await Promise.race([work, timeout]);
  } finally {
    if (timeoutId) window.clearTimeout(timeoutId);
  }
}

async function syncAdminSession(firebaseUser: User, token?: string) {
  const idToken = token ?? (await firebaseUser.getIdToken());
  const inviteToken =
    typeof window !== "undefined"
      ? new URLSearchParams(window.location.search).get("invite") ||
        window.localStorage.getItem("task-admin-invite-token") ||
        ""
      : "";
  if (inviteToken && typeof window !== "undefined")
    window.localStorage.setItem("task-admin-invite-token", inviteToken);
  if (!token) authLog("token received", { uid: firebaseUser.uid });
  const response = await withTimeout(
    fetch("/api/firebase/auth/session", {
      method: "POST",
      headers: {
        authorization: `Bearer ${idToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({ inviteToken }),
    }),
    "Admin profile sync timed out. Please try again.",
  );
  const data = (await response.json().catch(() => ({}))) as {
    admin?: AdminUser;
    error?: string;
  };
  if (!response.ok || !data.admin)
    throw new Error(data.error ?? "This Firebase user is not authorized for the dashboard.");
  authLog("admin profile loaded/synced", {
    uid: firebaseUser.uid,
    email: data.admin.email,
    status: data.admin.status,
  });
  if (inviteToken && data.admin.status === "Active" && typeof window !== "undefined")
    window.localStorage.removeItem("task-admin-invite-token");
  return data.admin;
}

async function createDashboardSession(firebaseUser: User) {
  try {
    const { db } = getFirebaseClient();
    const now = new Date().toISOString();
    await updateDoc(doc(db, "admins", firebaseUser.uid), { lastSeen: now });
    const sessionId =
      `${firebaseUser.uid}-${firebaseUser.metadata.lastSignInTime ?? Date.now()}`
        .replace(/[^a-zA-Z0-9_-]/g, "-");
    await setDoc(
      doc(db, "admins", firebaseUser.uid, "sessions", sessionId),
      {
        id: sessionId,
        device: navigator.platform,
        browser: navigator.userAgent,
        location: "Browser session",
        ip: "Firebase Auth",
        lastActive: now,
        current: true,
        active: true,
      },
      { merge: true },
    );
    authLog("session created", { uid: firebaseUser.uid, sessionId });
  } catch (reason) {
    console.warn(
      "[Task Admin Auth] Session telemetry could not be written; login remains valid",
      reason,
    );
    authLog("session telemetry skipped", { uid: firebaseUser.uid });
  }
}

async function clearCurrentSessionDocument(uid: string) {
  const { db } = getFirebaseClient();
  const sessions = await getDocs(collection(db, "admins", uid, "sessions"));
  const batch = writeBatch(db);
  sessions.docs.forEach((session) =>
    batch.update(session.ref, {
      active: false,
      current: false,
      lastActive: new Date().toISOString(),
    }),
  );
  await batch.commit();
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [user, setUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const signingOut = useRef(false);

  useEffect(() => {
    let unsubscribe = () => {};
    try {
      const { auth } = getFirebaseClient();
      void setPersistence(auth, browserLocalPersistence).catch((reason) => {
        console.error("[Task Admin Auth] Failed to set Firebase persistence", reason);
      });
      unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
        try {
          if (signingOut.current) {
            authLog("auth state ignored during sign out");
            setUser(null);
            return;
          }
          if (!firebaseUser) {
            authLog("auth state signed out");
            setUser(null);
            return;
          }
          authLog("auth state user detected", { uid: firebaseUser.uid });
          const admin = await syncAdminSession(firebaseUser);
          if (String(admin.status ?? "").toLowerCase() !== "active")
            throw new Error("This administrator account is disabled.");
          void createDashboardSession(firebaseUser);
          setError(null);
          setUser(admin);
        } catch (reason) {
          console.error("[Task Admin Auth] Admin authorization failed", reason);
          signingOut.current = true;
          await signOut(auth).catch(() => undefined);
          await clearBrowserAuthCaches(true).catch(() => undefined);
          setUser(null);
          setError(firebaseLoginError(reason));
          signingOut.current = false;
        } finally {
          if (!signingOut.current) setLoading(false);
        }
      });
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Firebase is not configured");
      setLoading(false);
    }
    return unsubscribe;
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      loading,
      error,
      async login(email, password) {
        const { auth } = getFirebaseClient();
        const normalizedEmail = email.trim().toLowerCase();
        setError(null);
        authLog("login started", { email: normalizedEmail });
        try {
          await clearBrowserAuthCaches();
          await setPersistence(auth, browserLocalPersistence);
          const credential = await withTimeout(
            signInWithEmailAndPassword(auth, normalizedEmail, password),
            "Firebase sign in timed out. Please try again.",
          );
          authLog("Firebase signIn success", {
            uid: credential.user.uid,
            email: credential.user.email,
          });
          const token = await withTimeout(
            credential.user.getIdToken(),
            "Firebase token retrieval timed out. Please try again.",
          );
          authLog("token received", { uid: credential.user.uid });
          const admin = await syncAdminSession(credential.user, token);
          if (String(admin.status ?? "").toLowerCase() !== "active")
            throw new Error("This administrator account is disabled.");
          void createDashboardSession(credential.user);
          setUser(admin);
          setError(null);
          authLog("login flow completed", { uid: credential.user.uid });
        } catch (reason) {
          console.error("[Task Admin Auth] Login failed", reason);
          signingOut.current = true;
          await signOut(auth).catch(() => undefined);
          await clearBrowserAuthCaches(true).catch(() => undefined);
          setUser(null);
          const message = firebaseLoginError(reason);
          setError(message);
          throw new Error(message);
        } finally {
          signingOut.current = false;
          setLoading(false);
        }
      },
      async logout() {
        const { auth } = getFirebaseClient();
        const uid = auth.currentUser?.uid;
        signingOut.current = true;
        setUser(null);
        setError(null);
        setLoading(true);
        authLog("sign out started", { uid });
        if (uid) {
          await clearCurrentSessionDocument(uid).catch((reason) => {
            console.error("[Task Admin Auth] Failed to clear session document", reason);
          });
        }
        await signOut(auth).catch((reason) => {
          console.error("[Task Admin Auth] Firebase signOut failed", reason);
        });
        authLog("Firebase signOut done", { uid });
        await clearBrowserAuthCaches(true).catch((reason) => {
          console.error("[Task Admin Auth] Failed to clear browser auth cache", reason);
        });
        setUser(null);
        setLoading(false);
        signingOut.current = false;
        authLog("sign out completed; redirecting to login", { target: "/login" });
        if (typeof window !== "undefined") window.location.replace("/login");
        else router.replace("/login");
      },
      async changePassword(current, next) {
        try {
          const { auth } = getFirebaseClient();
          if (!auth.currentUser?.email) return false;
          await reauthenticateWithCredential(
            auth.currentUser,
            EmailAuthProvider.credential(auth.currentUser.email, current),
          );
          await updatePassword(auth.currentUser, next);
          return true;
        } catch {
          return false;
        }
      },
      async getIdToken() {
        const firebaseUser = getFirebaseClient().auth.currentUser;
        if (!firebaseUser) throw new Error("Sign in required");
        return firebaseUser.getIdToken();
      },
    }),
    [error, loading, router, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) throw new Error("useAuth must be used inside AuthProvider");
  return value;
}
