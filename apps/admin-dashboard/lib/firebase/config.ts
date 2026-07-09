import type { FirebaseOptions } from "firebase/app";

type FirebaseDefaults = {
  config?: Partial<FirebaseOptions> & {
    projectId?: string;
    storageBucket?: string;
  };
};

const envConfig = (): FirebaseOptions => ({
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
});

function readDefaultsFromEnvironment(): FirebaseDefaults | null {
  const raw = process.env.__FIREBASE_DEFAULTS__?.trim();
  if (!raw) return null;
  try {
    return JSON.parse(raw) as FirebaseDefaults;
  } catch {
    return null;
  }
}

function readDefaultsFromGlobal(): FirebaseDefaults | null {
  const maybeGlobal = globalThis as typeof globalThis & {
    __FIREBASE_DEFAULTS__?: FirebaseDefaults;
  };
  return maybeGlobal.__FIREBASE_DEFAULTS__ ?? null;
}

export function resolveFirebaseClientConfig(): FirebaseOptions {
  const fromEnv = envConfig();
  const defaults = readDefaultsFromEnvironment() ?? readDefaultsFromGlobal();
  return {
    ...defaults?.config,
    ...Object.fromEntries(
      Object.entries(fromEnv).filter(([, value]) => Boolean(value)),
    ),
  };
}

export function firebaseConfigMissingKeys() {
  const config = resolveFirebaseClientConfig();
  return [
    "apiKey",
    "authDomain",
    "projectId",
    "storageBucket",
    "messagingSenderId",
    "appId",
  ].filter((key) => !config[key as keyof FirebaseOptions]);
}

export function firebaseProjectId() {
  return (
    resolveFirebaseClientConfig().projectId ??
    process.env.GCLOUD_PROJECT ??
    process.env.GOOGLE_CLOUD_PROJECT
  );
}

export function firebaseStorageBucket() {
  return resolveFirebaseClientConfig().storageBucket;
}
