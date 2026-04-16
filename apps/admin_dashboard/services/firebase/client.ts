import { initializeApp, getApps } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { firebaseConfig } from "../firebaseConfig";

let firebaseInitErrorMessage: string | null = null;

let app = getApps().length ? getApps()[0] : null;

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

export const auth = app ? getAuth(app) : null;
export const firestore = app ? getFirestore(app) : null;
