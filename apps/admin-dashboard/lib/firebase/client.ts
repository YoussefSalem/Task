import { getApp, getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { connectAuthEmulator, getAuth, type Auth } from "firebase/auth";
import { connectFirestoreEmulator, getFirestore, type Firestore } from "firebase/firestore";
import { connectStorageEmulator, getStorage, type FirebaseStorage } from "firebase/storage";

const config={apiKey:process.env.NEXT_PUBLIC_FIREBASE_API_KEY,authDomain:process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,projectId:process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,storageBucket:process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,messagingSenderId:process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,appId:process.env.NEXT_PUBLIC_FIREBASE_APP_ID};
export function firebaseConfigStatus(){const missing=Object.entries(config).filter(([,value])=>!value).map(([key])=>key);return{configured:missing.length===0,missing}}
let services:{app:FirebaseApp;auth:Auth;db:Firestore;storage:FirebaseStorage}|null=null;
// Opt-in only (unset in the real .env.local): lets an isolated E2E smoke-test
// run point this exact client code at the local Firebase emulator suite
// instead of the real project, so login/dashboard/complaint flows can be
// exercised end-to-end without ever touching production auth or data.
// Production behavior is completely unaffected when this is unset.
const useEmulators = process.env.NEXT_PUBLIC_USE_FIREBASE_EMULATORS === "true";
export function getFirebaseClient(){if(services)return services;const status=firebaseConfigStatus();if(!status.configured)throw new Error(`Firebase configuration is missing: ${status.missing.join(", ")}`);const app=getApps().length?getApp():initializeApp(config);const auth=getAuth(app);const db=getFirestore(app);const storage=getStorage(app);if(useEmulators){connectAuthEmulator(auth,"http://127.0.0.1:9099",{disableWarnings:true});connectFirestoreEmulator(db,"127.0.0.1",8080);connectStorageEmulator(storage,"127.0.0.1",9199);}services={app,auth,db,storage};return services}
