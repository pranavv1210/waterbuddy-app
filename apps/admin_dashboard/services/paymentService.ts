import { collection, onSnapshot, query, where } from "firebase/firestore";

import { db, firebaseInitErrorMessage, isFirebaseReady } from "./firebase";
import { PaymentDashboardData, PaymentPayoutRecord, PaymentSummary, WeeklyRevenueItem } from "./types";

function toNumber(value: unknown): number {
  return typeof value === "number" ? value : 0;
}

function valueOrDash(value: unknown): string {
  return typeof value === "string" && value.trim().length > 0 ? value : "-";
}

function toMillis(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (value instanceof Date) {
    return value.getTime();
  }

  const maybeTimestamp = value as { toMillis?: () => number };
  if (maybeTimestamp && typeof maybeTimestamp.toMillis === "function") {
    return maybeTimestamp.toMillis();
  }

  return undefined;
}

function getWeekBucketIndex(millis: number): number {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const offsetDays = Math.floor((millis - startOfMonth.getTime()) / (1000 * 60 * 60 * 24));
  return Math.max(0, Math.min(3, Math.floor(offsetDays / 7)));
}

function createInitialWeeklyRevenue(): WeeklyRevenueItem[] {
  return [
    { label: "WK 1", gross: 0, net: 0 },
    { label: "WK 2", gross: 0, net: 0 },
    { label: "WK 3", gross: 0, net: 0 },
    { label: "WK 4", gross: 0, net: 0 },
  ];
}

function normalizePayoutStatus(value: unknown): string {
  const normalized = valueOrDash(value).toLowerCase();
  if (normalized === "paid" || normalized === "completed") {
    return "Completed";
  }
  if (normalized === "pending") {
    return "Pending";
  }
  return "Pending";
}

function makeSellerCode(source: string): string {
  const cleaned = source.replace(/[^A-Za-z0-9]/g, "").toUpperCase();
  if (cleaned.length >= 4) {
    return `WB-${cleaned.slice(0, 4)}`;
  }
  if (cleaned.length > 0) {
    return `WB-${cleaned.padEnd(4, "0")}`;
  }
  return "WB-0000";
}

function buildDashboardData(snapshot: any): PaymentDashboardData {
  let totalRevenue = 0;
  let codRevenue = 0;
  let onlineRevenue = 0;
  let codCount = 0;
  let onlineCount = 0;

  const weeklyRevenue = createInitialWeeklyRevenue();
  const payouts: PaymentPayoutRecord[] = [];

  snapshot.forEach((docSnap: any) => {
    const data = docSnap.data();
    const amount = toNumber(data.amount);
    const paymentType = String(data.paymentType ?? "").toLowerCase();
    const createdAt = toMillis(data.createdAt);

    totalRevenue += amount;

    if (paymentType === "cod") {
      codRevenue += amount;
      codCount += 1;
    }

    if (paymentType === "online") {
      onlineRevenue += amount;
      onlineCount += 1;
    }

    if (typeof createdAt === "number") {
      const weekIndex = getWeekBucketIndex(createdAt);
      if (weekIndex >= 0 && weekIndex <= 3) {
        weeklyRevenue[weekIndex].gross += amount;
        weeklyRevenue[weekIndex].net += amount * 0.85;
      }
    }

    const sellerName = valueOrDash(data.sellerName ?? data.sellerId);
    const sellerCode = makeSellerCode(String(data.sellerId ?? data.sellerName ?? docSnap.id));

    payouts.push({
      id: docSnap.id,
      sellerName,
      sellerCode,
      transactionId: valueOrDash(data.transactionId ?? `TXN-${docSnap.id.slice(0, 8).toUpperCase()}`),
      date: createdAt,
      amount,
      status: normalizePayoutStatus(data.payoutStatus ?? data.paymentStatus),
    });
  });

  payouts.sort((a, b) => {
    const aMillis = typeof a.date === "number" ? a.date : 0;
    const bMillis = typeof b.date === "number" ? b.date : 0;
    return bMillis - aMillis;
  });

  const summary: PaymentSummary = {
    totalRevenue,
    codRevenue,
    onlineRevenue,
    codCount,
    onlineCount,
  };

  return {
    summary,
    weeklyRevenue,
    recentPayouts: payouts.slice(0, 5),
  };
}

export function subscribePaymentDashboard(
  callback: (dashboard: PaymentDashboardData) => void,
  onError: (error: Error) => void,
): () => void {
  if (!isFirebaseReady || !db) {
    onError(new Error(firebaseInitErrorMessage ?? "Firebase is not configured."));
    return () => {};
  }

  const paidOrdersQuery = query(collection(db, "orders"), where("paymentStatus", "==", "paid"));

  return onSnapshot(
    paidOrdersQuery,
    (snapshot: any) => {
      callback(buildDashboardData(snapshot));
    },
    (error: any) => onError(error),
  );
}
