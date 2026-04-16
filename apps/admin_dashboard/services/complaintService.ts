import { collection, doc, onSnapshot, orderBy, query, updateDoc } from "firebase/firestore";

import { db, firebaseInitErrorMessage, isFirebaseReady } from "./firebase";
import { ComplaintRecord } from "./types";

function valueOrDash(value: unknown): string {
  return typeof value === "string" && value.trim().length > 0 ? value : "-";
}

function normalizeStatus(rawStatus: unknown): string {
  const status = valueOrDash(rawStatus).toLowerCase();
  if (status === "open" || status === "pending") {
    return "Open";
  }
  if (status === "in_progress" || status === "in progress") {
    return "In Progress";
  }
  if (status === "resolved" || status === "closed") {
    return "Resolved";
  }
  return status === "-" ? "Open" : status;
}

function inferIssueType(data: Record<string, unknown>): string {
  const explicitIssueType = valueOrDash(data.issueType);
  if (explicitIssueType !== "-") {
    return explicitIssueType;
  }

  const reason = valueOrDash(data.reason).toLowerCase();
  if (reason.includes("late")) return "Late Delivery";
  if (reason.includes("damage")) return "Damaged Seal";
  if (reason.includes("payment")) return "Payment Error";
  if (reason.includes("wrong")) return "Wrong Item";
  return reason === "-" ? "General Issue" : valueOrDash(data.reason);
}

function inferPriority(data: Record<string, unknown>): string {
  const explicitPriority = valueOrDash(data.priority);
  if (explicitPriority !== "-") {
    return explicitPriority;
  }
  const normalizedStatus = normalizeStatus(data.status).toLowerCase();
  if (normalizedStatus === "open") {
    return "critical";
  }
  if (normalizedStatus === "in progress") {
    return "medium";
  }
  return "low";
}

export function subscribeComplaints(
  callback: (complaints: ComplaintRecord[]) => void,
  onError: (error: Error) => void,
): () => void {
  if (!isFirebaseReady || !db) {
    onError(new Error(firebaseInitErrorMessage ?? "Firebase is not configured."));
    return () => {};
  }

  const complaintsQuery = query(collection(db, "complaints"), orderBy("createdAt", "desc"));

  return onSnapshot(
    complaintsQuery,
    (snapshot: any) => {
      const complaints = snapshot.docs.map((docSnap: any) => {
        const data = docSnap.data();
        return {
          id: docSnap.id,
          customer: valueOrDash(data.customerName ?? data.customerId),
          seller: valueOrDash(data.sellerName ?? data.sellerId),
          orderId: valueOrDash(data.orderId),
          issueType: inferIssueType(data),
          status: normalizeStatus(data.status),
          reason: valueOrDash(data.reason),
          priority: inferPriority(data),
          createdAt: data.createdAt?.toMillis ? data.createdAt.toMillis() : data.createdAt,
        } satisfies ComplaintRecord;
      });
      callback(complaints);
    },
    (error: any) => onError(error),
  );
}

export async function setComplaintStatus(complaintId: string, status: string): Promise<void> {
  if (!isFirebaseReady || !db) {
    throw new Error(firebaseInitErrorMessage ?? "Firebase is not configured.");
  }
  await updateDoc(doc(db, "complaints", complaintId), { status });
}
