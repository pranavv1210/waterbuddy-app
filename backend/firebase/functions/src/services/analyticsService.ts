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

  private async updateRollingAverage(
    totalField: string,
    countField: string,
    averageField: string,
    value: number
  ): Promise<void> {
    try {
      const ref = db.collection(collections.systemMetrics).doc(this.todayId);
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const data = snap.data() ?? {};
        const nextTotal = Number(data[totalField] ?? 0) + value;
        const nextCount = Number(data[countField] ?? 0) + 1;
        tx.set(
          ref,
          {
            [totalField]: nextTotal,
            [countField]: nextCount,
            [averageField]: nextTotal / nextCount,
            date: this.todayId,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      });
    } catch (e) {
      logger.warn(`Analytics: failed to update ${averageField}`, { error: e });
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
            dailyRevenue: FieldValue.increment(amountPaise / 100),
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
    await this.updateRollingAverage(
      "totalDeliveryMinutes",
      "deliverySamples",
      "averageDeliveryTime",
      durationMinutes
    );
  }

  /**
   * Records time from order creation to seller acceptance (in seconds).
   */
  async recordAcceptanceTime(durationSeconds: number): Promise<void> {
    await this.updateRollingAverage(
      "totalAcceptanceSeconds",
      "acceptanceSamples",
      "averageAcceptanceTime",
      durationSeconds
    );
  }

  async incrementActiveDrivers(delta: number): Promise<void> {
    await this.increment("activeDrivers", delta);
  }

  async incrementActiveSellers(delta: number): Promise<void> {
    await this.increment("activeSellers", delta);
  }
}
