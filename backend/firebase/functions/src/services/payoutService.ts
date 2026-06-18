import { FieldValue } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { collections } from "../constants/collections";
import { db } from "./firebase";
import { WalletService } from "./walletService";

export class PayoutService {
  constructor(private readonly wallets = new WalletService()) {}

  async approveDriverPayout(params: {
    payoutId: string;
    adminId: string;
    method?: string;
  }): Promise<void> {
    const ref = db.collection(collections.driverPayouts).doc(params.payoutId);
    const snapshot = await ref.get();
    if (!snapshot.exists) throw new HttpsError("not-found", "Driver payout not found.");
    const payout = snapshot.data()!;
    if (payout.status === "PAID") return;
    if (!["PENDING", "FAILED"].includes(String(payout.status))) {
      throw new HttpsError("failed-precondition", "Payout cannot be approved from current status.");
    }

    await ref.set(
      {
        status: "PAID",
        method: params.method ?? payout.method ?? "BANK_TRANSFER",
        approvedBy: params.adminId,
        paidAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await this.wallets.record({
      userId: String(payout.driverId),
      role: "driver",
      type: "PAYOUT",
      direction: "UNLOCK_DEBIT",
      amount: Number(payout.amount ?? 0),
      createdBy: params.adminId,
      payoutId: params.payoutId,
      orderId: payout.orderId,
    });
  }

  async approveSellerPayout(params: {
    payoutId: string;
    adminId: string;
    method?: string;
  }): Promise<void> {
    const ref = db.collection(collections.sellerPayouts).doc(params.payoutId);
    const snapshot = await ref.get();
    if (!snapshot.exists) throw new HttpsError("not-found", "Seller payout not found.");
    const payout = snapshot.data()!;
    if (payout.status === "PAID") return;
    if (!["PENDING", "FAILED"].includes(String(payout.status))) {
      throw new HttpsError("failed-precondition", "Payout cannot be approved from current status.");
    }

    await ref.set(
      {
        status: "PAID",
        method: params.method ?? payout.method ?? "BANK_TRANSFER",
        approvedBy: params.adminId,
        paidAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await this.wallets.record({
      userId: String(payout.sellerId),
      role: "seller",
      type: "PAYOUT",
      direction: "UNLOCK_DEBIT",
      amount: Number(payout.netAmount ?? 0),
      createdBy: params.adminId,
      payoutId: params.payoutId,
      orderId: payout.orderId,
    });
  }
}
