import {
  applicationDefault,
  cert,
  getApps,
  initializeApp,
} from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { firebaseProjectId, firebaseStorageBucket } from "@/lib/firebase/config";

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

const app =
  getApps()[0] ??
  initializeApp({
    credential: credential(),
    projectId: firebaseProjectId(),
    storageBucket: firebaseStorageBucket(),
  });

export const firebaseAdminAuth = getAuth(app);
export const firebaseAdminDb = getFirestore(app);
export const firebaseAdminStorage = getStorage(app);
