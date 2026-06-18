import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { collections } from "../constants/collections";
import { db } from "./firebase";
import { WalletService } from "./walletService";

interface CommissionSettings {
  platformCommission: number;
  driverCommission: number;
  sellerCommission: number;
  taxRate: number;
}

interface SettlementBreakdown {
  grossAmount: number;
  platformFee: number;
  driverCommission: number;
  sellerCommission: number;
  tax: number;
  sellerNetAmount: number;
}

const defaults: CommissionSettings = {
  platformCommission: 0.1,
  driverCommission: 0.2,
  sellerCommission: 0.7,
  taxRate: 0.18,
};

function normalizeRate(value: unknown, fallback: number): number {
  const numeric = Number(value);
  if (!Number.isFinite(numeric) || numeric < 0) return fallback;
  return numeric > 1 ? numeric / 100 : numeric;
}

export class CommissionService {
  constructor(private readonly wallets = new WalletService()) {}

  async getSettings(): Promise<CommissionSettings> {
    const snapshot = await db.collection(collections.systemSettings).doc("app").get();
    const data = snapshot.data() ?? {};
    return {
      platformCommission: normalizeRate(data.platformCommission, defaults.platformCommission),
      driverCommission: normalizeRate(data.driverCommission, defaults.driverCommission),
      sellerCommission: normalizeRate(data.sellerCommission, defaults.sellerCommission),
      taxRate: normalizeRate(data.taxRate, defaults.taxRate),
    };
  }

  calculate(grossAmount: number, settings: CommissionSettings): SettlementBreakdown {
    if (!Number.isFinite(grossAmount) || grossAmount <= 0) {
      throw new Error("Order amount must be positive for commission settlement.");
    }

    const platformFee = roundMoney(grossAmount * settings.platformCommission);
    const driverCommission = roundMoney(grossAmount * settings.driverCommission);
    const sellerGross = roundMoney(grossAmount * settings.sellerCommission);
    const tax = roundMoney(platformFee * settings.taxRate);
    const sellerNetAmount = roundMoney(Math.max(0, sellerGross - tax));

    return {
      grossAmount,
      platformFee,
      driverCommission,
      sellerCommission: sellerGross,
      tax,
      sellerNetAmount,
    };
  }

  async settleDeliveredOrder(orderId: string): Promise<void> {
    const orderRef = db.collection(collections.orders).doc(orderId);
    const settlementRef = db.collection("order_settlements").doc(orderId);
    const existing = await settlementRef.get();
    if (existing.exists) {
      logger.info("Settlement already exists, skipping", { orderId });
      return;
    }

    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) return;
    const order = orderSnap.data()!;
    if (!["DELIVERED", "COMPLETED"].includes(String(order.status))) return;

    const amount = Number(order.amount ?? order.totalAmount ?? 0);
    const sellerId = String(order.sellerId ?? "");
    const driverId = String(order.driverId ?? "");
    if (!sellerId || !driverId || amount <= 0) return;

    const settings = await this.getSettings();
    const breakdown = this.calculate(amount, settings);
    const sellerPayoutRef = db.collection(collections.sellerPayouts).doc();
    const driverPayoutRef = db.collection(collections.driverPayouts).doc();

    await db.runTransaction(async (tx) => {
      const freshSettlement = await tx.get(settlementRef);
      if (freshSettlement.exists) return;

      tx.set(settlementRef, {
        orderId,
        sellerId,
        driverId,
        ...breakdown,
        settings,
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.set(sellerPayoutRef, {
        id: sellerPayoutRef.id,
        sellerId,
        orderId,
        commission: breakdown.sellerCommission,
        platformFee: breakdown.platformFee,
        tax: breakdown.tax,
        netAmount: breakdown.sellerNetAmount,
        status: "PENDING",
        method: "BANK_TRANSFER",
        createdAt: FieldValue.serverTimestamp(),
        paidAt: null,
      });

      tx.set(driverPayoutRef, {
        id: driverPayoutRef.id,
        driverId,
        orderId,
        amount: breakdown.driverCommission,
        status: "PENDING",
        method: "BANK_TRANSFER",
        createdAt: FieldValue.serverTimestamp(),
        paidAt: null,
      });
    });

    await this.wallets.record({
      userId: sellerId,
      role: "seller",
      type: "ORDER_PAYMENT",
      direction: "LOCK_CREDIT",
      amount: breakdown.sellerNetAmount,
      createdBy: "commission_settlement",
      orderId,
      payoutId: sellerPayoutRef.id,
      metadata: { ...breakdown },
    });

    await this.wallets.record({
      userId: driverId,
      role: "driver",
      type: "ORDER_PAYMENT",
      direction: "LOCK_CREDIT",
      amount: breakdown.driverCommission,
      createdBy: "commission_settlement",
      orderId,
      payoutId: driverPayoutRef.id,
      metadata: { ...breakdown },
    });

    await this.wallets.record({
      userId: "platform",
      role: "admin",
      type: "ORDER_PAYMENT",
      direction: "CREDIT",
      amount: breakdown.platformFee,
      createdBy: "commission_settlement",
      orderId,
      metadata: { ...breakdown },
    });

    logger.info("Order settled", { orderId, sellerId, driverId, breakdown });
  }
}

function roundMoney(value: number): number {
  return Math.round(value * 100) / 100;
}
