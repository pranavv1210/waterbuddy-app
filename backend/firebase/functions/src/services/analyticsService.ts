import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { collections } from "../constants/collections";
import { db } from "./firebase";

/**
 * Server-side analytics service.
 * Uses FieldValue.increment() — no read-before-write cost.
 */
export class AnalyticsService {
  private get todayId(): string {
    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, "0");
    const d = String(now.getDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  }

  private async increment(field: string, amount = 1): Promise<void> {
    try {
      await db
        .collection(collections.systemMetrics)
        .doc(this.todayId)
        .set(
          {
            [field]: FieldValue.increment(amount),
            date: this.todayId,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    } catch (e) {
      logger.warn(`Analytics: failed to increment ${field}`, { error: e });
    }
  }

  async incrementOrdersCreated(): Promise<void> {
    await this.increment("ordersCreated");
  }

  async incrementOrdersCompleted(): Promise<void> {
    await this.increment("ordersCompleted");
  }

  async incrementOrdersCancelled(): Promise<void> {
    await this.increment("ordersCancelled");
  }

  async incrementPaymentsSuccess(): Promise<void> {
    await this.increment("paymentsSuccess");
  }

  async incrementPaymentsFailed(): Promise<void> {
    await this.increment("paymentsFailed");
  }

  async incrementDispatchAttempts(): Promise<void> {
    await this.increment("dispatchAttempts");
  }

  /**
   * Records revenue (amount in paise, stored as paise).
   */
  async recordRevenue(amountPaise: number): Promise<void> {
    try {
      await db
        .collection(collections.systemMetrics)
        .doc(this.todayId)
        .set(
          {
            revenuePaise: FieldValue.increment(amountPaise),
            date: this.todayId,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    } catch (e) {
      logger.warn("Analytics: failed to record revenue", { error: e });
    }
  }

  /**
   * Records delivery time in minutes for average calculation.
   */
  async recordDeliveryTime(durationMinutes: number): Promise<void> {
    try {
      await db
        .collection(collections.systemMetrics)
        .doc(this.todayId)
        .set(
          {
            deliveryTimes: FieldValue.arrayUnion(durationMinutes),
            totalDeliveries: FieldValue.increment(1),
            date: this.todayId,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    } catch (e) {
      logger.warn("Analytics: failed to record delivery time", { error: e });
    }
  }

  /**
   * Records time from order creation to seller acceptance (in seconds).
   */
  async recordAcceptanceTime(durationSeconds: number): Promise<void> {
    try {
      await db
        .collection(collections.systemMetrics)
        .doc(this.todayId)
        .set(
          {
            acceptanceTimes: FieldValue.arrayUnion(durationSeconds),
            date: this.todayId,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    } catch (e) {
      logger.warn("Analytics: failed to record acceptance time", { error: e });
    }
  }
}
