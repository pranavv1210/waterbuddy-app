import { collection, doc, onSnapshot, orderBy, query, updateDoc } from "firebase/firestore";

import { db, firebaseInitErrorMessage, isFirebaseReady } from "./firebase";
import { SellerRecord } from "./types";

function valueOrDash(value: unknown): string {
  return typeof value === "string" && value.trim().length > 0 ? value : "-";
}

export function subscribeSellers(
  callback: (sellers: SellerRecord[]) => void,
  onError: (error: Error) => void,
): () => void {
  if (!isFirebaseReady || !db) {
    onError(new Error(firebaseInitErrorMessage ?? "Firebase is not configured."));
    return () => {};
  }

  const sellersQuery = query(collection(db, "sellers"), orderBy("createdAt", "desc"));

  return onSnapshot(
    sellersQuery,
    (snapshot: any) => {
      const sellers = snapshot.docs.map((docSnap: any) => {
        const data = docSnap.data();
        return {
          id: docSnap.id,
          name: valueOrDash(data.name),
          phone: valueOrDash(data.phone),
          location: valueOrDash(data.location),
          kycStatus: valueOrDash(data.kycStatus),
          onlineStatus: Boolean(data.onlineStatus),
          enabled: data.enabled !== false,
          rating: typeof data.rating === "number" ? data.rating : undefined,
        } satisfies SellerRecord;
      });
      callback(sellers);
    },
    (error: any) => onError(error),
  );
}

export async function setSellerEnabled(sellerId: string, enabled: boolean): Promise<void> {
  if (!isFirebaseReady || !db) {
    throw new Error(firebaseInitErrorMessage ?? "Firebase is not configured.");
  }
  await updateDoc(doc(db, "sellers", sellerId), { enabled });
}

export async function setSellerKycStatus(sellerId: string, kycStatus: string): Promise<void> {
  if (!isFirebaseReady || !db) {
    throw new Error(firebaseInitErrorMessage ?? "Firebase is not configured.");
  }
  await updateDoc(doc(db, "sellers", sellerId), { kycStatus });
}
