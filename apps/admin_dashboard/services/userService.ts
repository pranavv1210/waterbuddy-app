import { collection, doc, onSnapshot, orderBy, query, updateDoc } from "firebase/firestore";

import { db, firebaseInitErrorMessage, isFirebaseReady } from "./firebase";
import { UserRecord } from "./types";

function valueOrDash(value: unknown): string {
  return typeof value === "string" && value.trim().length > 0 ? value : "-";
}

export function subscribeUsers(
  callback: (users: UserRecord[]) => void,
  onError: (error: Error) => void,
): () => void {
  if (!isFirebaseReady || !db) {
    onError(new Error(firebaseInitErrorMessage ?? "Firebase is not configured."));
    return () => {};
  }

  const usersQuery = query(collection(db, "users"), orderBy("createdAt", "desc"));

  return onSnapshot(
    usersQuery,
    (snapshot: any) => {
      const users = snapshot.docs.map((docSnap: any) => {
        const data = docSnap.data();
        return {
          id: docSnap.id,
          name: valueOrDash(data.name),
          phone: valueOrDash(data.phone),
          role: valueOrDash(data.role),
          email: valueOrDash(data.email),
          totalOrders: typeof data.totalOrders === "number" ? data.totalOrders : 0,
          joinDate: data.createdAt?.toMillis ? data.createdAt.toMillis() : data.createdAt,
          blocked: Boolean(data.blocked),
          lifetimeValue: typeof data.lifetimeValue === "number" ? data.lifetimeValue : undefined,
        } satisfies UserRecord;
      });
      callback(users);
    },
    (error: any) => onError(error),
  );
}

export async function setUserBlocked(userId: string, blocked: boolean): Promise<void> {
  if (!isFirebaseReady || !db) {
    throw new Error(firebaseInitErrorMessage ?? "Firebase is not configured.");
  }
  await updateDoc(doc(db, "users", userId), { blocked });
}
