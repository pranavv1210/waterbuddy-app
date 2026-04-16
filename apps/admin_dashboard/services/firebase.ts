import { initializeApp, getApps } from "firebase/app";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

const requiredKeys = [
  "apiKey",
  "authDomain",
  "projectId",
  "storageBucket",
  "messagingSenderId",
  "appId",
] as const;

const missingKeys = requiredKeys.filter((key) => {
  const value = firebaseConfig[key];
  return typeof value !== "string" || value.trim().length === 0;
});

let firebaseInitErrorMessage: string | null =
  missingKeys.length > 0
    ? `Missing Firebase config: ${missingKeys.join(", ")}. Set NEXT_PUBLIC_FIREBASE_* env vars before deploy.`
    : null;

let app = getApps().length > 0 ? getApps()[0] : null;

if (!app && !firebaseInitErrorMessage) {
  try {
    app = initializeApp(firebaseConfig);
  } catch (error) {
    firebaseInitErrorMessage =
      error instanceof Error ? error.message : "Failed to initialize Firebase.";
  }
}

export { firebaseInitErrorMessage };
export const isFirebaseReady = app !== null && firebaseInitErrorMessage === null;

export const db = app ? getFirestore(app) : null;
