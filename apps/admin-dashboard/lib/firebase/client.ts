import { getApp, getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { getAuth, type Auth } from "firebase/auth";
import { getFirestore, type Firestore } from "firebase/firestore";
import { getStorage, type FirebaseStorage } from "firebase/storage";
import {
  firebaseConfigMissingKeys,
  resolveFirebaseClientConfig,
} from "@/lib/firebase/config";

export function firebaseConfigStatus(){const missing=firebaseConfigMissingKeys();return{configured:missing.length===0,missing}}
let services:{app:FirebaseApp;auth:Auth;db:Firestore;storage:FirebaseStorage}|null=null;
export function getFirebaseClient(){if(services)return services;const status=firebaseConfigStatus();if(!status.configured)throw new Error(`Firebase configuration is missing: ${status.missing.join(", ")}`);const app=getApps().length?getApp():initializeApp(resolveFirebaseClientConfig());services={app,auth:getAuth(app),db:getFirestore(app),storage:getStorage(app)};return services}
