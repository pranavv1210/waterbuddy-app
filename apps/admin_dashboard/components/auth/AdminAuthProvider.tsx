import {
  createContext,
  PropsWithChildren,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  updateProfile,
} from "firebase/auth";

import { auth } from "../../services/firebase/client";
import { ADMIN_LOGIN_EMAIL, ADMIN_LOGIN_PASSWORD } from "../../services/adminCredentials";

interface AdminUserProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
}

interface FirebaseUserProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
}

interface AdminAuthContextValue {
  currentUser: AdminUserProfile | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  updateDisplayName: (displayName: string) => Promise<void>;
}

const AdminAuthContext = createContext<AdminAuthContextValue | null>(null);

function toAdminUserProfile(user: FirebaseUserProfile): AdminUserProfile {
  return {
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoURL: user.photoURL,
  };
}

function deriveDisplayName(email: string): string {
  const localPart = email.split("@")[0]?.trim();
  if (localPart) {
    return localPart
      .split(/[._-]+/)
      .filter(Boolean)
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
      .join(" ");
  }

  return "WaterBuddy Admin";
}

function normalizeAuthError(error: unknown): string {
  if (error && typeof error === "object" && "code" in error) {
    const code = String((error as { code?: unknown }).code);

    if (code === "auth/user-not-found") {
      return "No account exists for that email yet. Submit again to create the first admin account.";
    }

    if (code === "auth/wrong-password" || code === "auth/invalid-credential") {
      return "The email or password is incorrect.";
    }

    if (code === "auth/email-already-in-use") {
      return "That email is already registered. Please sign in with the existing password.";
    }

    if (code === "auth/operation-not-allowed") {
      return "Enable Email/Password sign-in in Firebase Authentication > Sign-in method.";
    }
  }

  return error instanceof Error ? error.message : "Unable to authenticate right now.";
}

function isAllowedAdminCredential(email: string, password: string): boolean {
  return email.trim().toLowerCase() === ADMIN_LOGIN_EMAIL.toLowerCase() && password === ADMIN_LOGIN_PASSWORD;
}

export function AdminAuthProvider({ children }: PropsWithChildren) {
  const [currentUser, setCurrentUser] = useState<AdminUserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!auth) {
      setLoading(false);
      return;
    }

    return onAuthStateChanged(auth, (user: FirebaseUserProfile | null) => {
      setCurrentUser(user ? toAdminUserProfile(user) : null);
      setLoading(false);
    });
  }, []);

  const value = useMemo<AdminAuthContextValue>(() => {
    const signIn = async (email: string, password: string) => {
      if (!auth) {
        throw new Error("Firebase Auth is not available.");
      }

      const normalizedEmail = email.trim();

      if (!isAllowedAdminCredential(normalizedEmail, password)) {
        throw new Error("Only the configured WaterBuddy admin credentials are allowed for this dashboard.");
      }

      try {
        await signInWithEmailAndPassword(auth, ADMIN_LOGIN_EMAIL, ADMIN_LOGIN_PASSWORD);
      } catch (error) {
        const code = error && typeof error === "object" && "code" in error ? String((error as { code?: unknown }).code) : "";

        if (
          code === "auth/user-not-found" ||
          code === "auth/invalid-credential" ||
          code === "auth/invalid-login-credentials"
        ) {
          try {
            const created = await createUserWithEmailAndPassword(auth, ADMIN_LOGIN_EMAIL, ADMIN_LOGIN_PASSWORD);
            const nextDisplayName = deriveDisplayName(ADMIN_LOGIN_EMAIL);
            await updateProfile(created.user, {
              displayName: nextDisplayName,
            });
            setCurrentUser({
              uid: created.user.uid,
              email: created.user.email,
              displayName: nextDisplayName,
              photoURL: created.user.photoURL,
            });
            return;
          } catch (createError) {
            const createCode =
              createError && typeof createError === "object" && "code" in createError
                ? String((createError as { code?: unknown }).code)
                : "";

            if (createCode === "auth/email-already-in-use") {
              throw new Error("The configured dashboard password does not match Firebase Auth. Reset this user password in Firebase to continue.");
            }

            throw new Error(normalizeAuthError(createError));
          }
        }

        if (code === "auth/wrong-password") {
          throw new Error("The configured dashboard password does not match Firebase Auth. Reset this user password in Firebase to continue.");
        }

        throw new Error(normalizeAuthError(error));
      }
    };

    const signOut = async () => {
      if (!auth) {
        return;
      }

      await firebaseSignOut(auth);
      setCurrentUser(null);
    };

    const updateDisplayName = async (displayName: string) => {
      if (!auth?.currentUser) {
        throw new Error("Please sign in again before updating profile details.");
      }

      const nextDisplayName = displayName.trim() || deriveDisplayName(auth.currentUser.email ?? "");
      await updateProfile(auth.currentUser, {
        displayName: nextDisplayName,
      });
      setCurrentUser({
        uid: auth.currentUser.uid,
        email: auth.currentUser.email,
        displayName: nextDisplayName,
        photoURL: auth.currentUser.photoURL,
      });
    };

    return {
      currentUser,
      loading,
      signIn,
      signOut,
      updateDisplayName,
    };
  }, [currentUser, loading]);

  return <AdminAuthContext.Provider value={value}>{children}</AdminAuthContext.Provider>;
}

export function useAdminAuth() {
  const context = useContext(AdminAuthContext);

  if (!context) {
    throw new Error("useAdminAuth must be used within AdminAuthProvider.");
  }

  return context;
}