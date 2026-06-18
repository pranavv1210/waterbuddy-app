import { FieldValue } from "firebase-admin/firestore";
import { collections } from "../constants/collections";
import { db } from "./firebase";

export class PerformanceMetricsService {
  async recordDelivery(params: {
    orderId: string;
    sellerId?: string | null;
    driverId?: string | null;
    amount: number;
    deliveryMinutes?: number;
  }): Promise<void> {
    const writes: Promise<unknown>[] = [];
    if (params.driverId) {
      writes.push(
        db.collection(collections.driverMetrics).doc(params.driverId).set(
          {
            driverId: params.driverId,
            deliveriesCompleted: FieldValue.increment(1),
            revenue: FieldValue.increment(params.amount),
            updatedAt: FieldValue.serverTimestamp(),
            ...(params.deliveryMinutes != null
              ? {
                  totalDeliveryMinutes: FieldValue.increment(params.deliveryMinutes),
                  deliverySamples: FieldValue.increment(1),
                }
              : {}),
          },
          { merge: true }
        )
      );
    }
    if (params.sellerId) {
      writes.push(
        db.collection(collections.sellerMetrics).doc(params.sellerId).set(
          {
            sellerId: params.sellerId,
            ordersAccepted: FieldValue.increment(1),
            revenue: FieldValue.increment(params.amount),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        )
      );
    }
    await Promise.all(writes);
    await this.recomputeAverages(params.driverId ?? undefined, params.sellerId ?? undefined);
  }

  async recordCancellation(params: {
    sellerId?: string | null;
    driverId?: string | null;
  }): Promise<void> {
    const writes: Promise<unknown>[] = [];
    if (params.driverId) {
      writes.push(
        db.collection(collections.driverMetrics).doc(params.driverId).set(
          {
            driverId: params.driverId,
            cancellations: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        )
      );
    }
    if (params.sellerId) {
      writes.push(
        db.collection(collections.sellerMetrics).doc(params.sellerId).set(
          {
            sellerId: params.sellerId,
            cancellations: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        )
      );
    }
    await Promise.all(writes);
  }

  async recordOfferRejected(sellerId: string): Promise<void> {
    await db.collection(collections.sellerMetrics).doc(sellerId).set(
      {
        sellerId,
        ordersRejected: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    await this.recomputeAverages(undefined, sellerId);
  }

  async recomputeAverages(driverId?: string, sellerId?: string): Promise<void> {
    const updates: Promise<unknown>[] = [];
    if (driverId) {
      updates.push(
        db.runTransaction(async (tx) => {
          const ref = db.collection(collections.driverMetrics).doc(driverId);
          const snap = await tx.get(ref);
          const data = snap.data() ?? {};
          const deliveries = Number(data.deliveriesCompleted ?? 0);
          const cancellations = Number(data.cancellations ?? 0);
          const samples = Number(data.deliverySamples ?? 0);
          const totalMinutes = Number(data.totalDeliveryMinutes ?? 0);
          tx.set(
            ref,
            {
              acceptanceRate:
                deliveries + cancellations === 0
                  ? 0
                  : deliveries / (deliveries + cancellations),
              averageDeliveryTime: samples === 0 ? 0 : totalMinutes / samples,
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        })
      );
    }
    if (sellerId) {
      updates.push(
        db.runTransaction(async (tx) => {
          const ref = db.collection(collections.sellerMetrics).doc(sellerId);
          const snap = await tx.get(ref);
          const data = snap.data() ?? {};
          const accepted = Number(data.ordersAccepted ?? 0);
          const rejected = Number(data.ordersRejected ?? 0);
          tx.set(
            ref,
            {
              acceptanceRate:
                accepted + rejected === 0 ? 0 : accepted / (accepted + rejected),
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        })
      );
    }
    await Promise.all(updates);
  }
}
