import {
  applicationDefault,
  cert,
  getApps,
  initializeApp,
  type App,
} from "firebase-admin/app";
import { getAuth, type Auth } from "firebase-admin/auth";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { getStorage, type Storage } from "firebase-admin/storage";

function credential() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  if (!raw) return applicationDefault();
  try {
    const value = JSON.parse(raw) as {
      project_id: string;
      client_email: string;
      private_key: string;
    };
    return cert({
      projectId: value.project_id,
      clientEmail: value.client_email,
      privateKey: value.private_key.replace(/\\n/g, "\n"),
    });
  } catch (error) {
    console.error(
      "[Task Admin Firebase] FIREBASE_SERVICE_ACCOUNT_JSON is invalid; falling back to application default credentials.",
      error instanceof Error ? error.message : error,
    );
    return applicationDefault();
  }
}

let cachedApp: App | undefined;

/**
 * Lazily creates (once, on first real use) and returns the Firebase Admin
 * app. This must NEVER run at module import time.
 *
 * Firebase Hosting's Next.js deploy pipeline imports this module into a local
 * Node sandbox purely to enumerate exported route handlers ("determine
 * backend specification"), before anything is actually deployed. That
 * sandbox has no GCP metadata server and no gcloud Application Default
 * Credentials configured, so an eager `applicationDefault()` credential
 * lookup at import time hangs until Firebase's own analysis timeout fires
 * ("User code failed to load. Cannot determine backend specification.
 * Timeout after 10000."). Deferring initialization to the first time a
 * request handler actually touches Firestore/Auth/Storage avoids that
 * entirely, while still supporting FIREBASE_SERVICE_ACCOUNT_JSON if it's
 * provided later - nothing about the credential logic itself changed.
 */
function getAdminApp(): App {
  if (!cachedApp) {
    cachedApp =
      getApps()[0] ??
      initializeApp({
        credential: credential(),
        projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
        storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
      });
  }
  return cachedApp;
}

/**
 * Wraps a factory in a Proxy so importers can keep using
 * `firebaseAdminDb.collection(...)` etc. exactly as before - no call site
 * elsewhere in the app needs to change - while the real SDK instance (and the
 * app/credential it depends on) is only constructed on first property access,
 * not at module load. Methods are explicitly `.bind()`ed to the REAL
 * instance (not the proxy) before being returned, so internal `this` usage
 * inside the Firebase Admin SDK (including any ES private class fields)
 * behaves exactly as if the caller held the real instance directly.
 */
function lazy<T extends object>(factory: () => T): T {
  let instance: T | undefined;
  const resolve = () => (instance ??= factory());
  return new Proxy({} as T, {
    get(_target, prop) {
      const real = resolve();
      const value = Reflect.get(real as object, prop, real as object);
      return typeof value === "function" ? value.bind(real) : value;
    },
    has(_target, prop) {
      return Reflect.has(resolve() as object, prop);
    },
  });
}

export const firebaseAdminAuth: Auth = lazy(() => getAuth(getAdminApp()));
export const firebaseAdminDb: Firestore = lazy(() => getFirestore(getAdminApp()));
export const firebaseAdminStorage: Storage = lazy(() => getStorage(getAdminApp()));
