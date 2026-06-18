import { FieldValue } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { collections } from "../constants/collections";
import { RefundType } from "../models/domain";
import { db } from "./firebase";
import { WalletService } from "./walletService";

export class RefundService {
  constructor(private readonly wallets = new WalletService()) {}

  calculateRefundAmount(params: {
    paidAmount: number;
    requestedAmount?: number;
    type: RefundType;
    cancellationCharge?: number;
  }): number {
    const paid = Math.max(0, Number(params.paidAmount) || 0);
    const cancellationCharge = Math.max(0, Number(params.cancellationCharge) || 0);
    if (params.type === "FULL" || params.type === "PAYMENT_FAILURE") return paid;
    if (params.type === "CANCELLATION") return Math.max(0, paid - cancellationCharge);
    return Math.min(paid, Math.max(0, Number(params.requestedAmount) || 0));
  }

  async requestRefund(params: {
    orderId: string;
    requestedBy: string;
    type: RefundType;
    reason: string;
    requestedAmount?: number;
  }): Promise<{ refundId: string; amount: number; status: string }> {
    const orderSnap = await db.collection(collections.orders).doc(params.orderId).get();
    if (!orderSnap.exists) throw new HttpsError("not-found", "Order not found.");
    const order = orderSnap.data()!;
    if (order.customerId !== params.requestedBy) {
      throw new HttpsError("permission-denied", "Only the customer can request this refund.");
    }

    const paidAmount = Number(order.amount ?? order.totalAmount ?? 0);
    const amount = this.calculateRefundAmount({
      paidAmount,
      requestedAmount: params.requestedAmount,
      type: params.type,
      cancellationCharge: Number(order.cancellationCharge ?? 0),
    });
    if (amount <= 0) throw new HttpsError("failed-precondition", "Refund amount is zero.");

    const refundRef = db.collection(collections.refunds).doc();
    await refundRef.set({
      id: refundRef.id,
      orderId: params.orderId,
      customerId: params.requestedBy,
      amount,
      type: params.type,
      status: "REQUESTED",
      reason: params.reason,
      requestedBy: params.requestedBy,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      processedAt: null,
    });

    return { refundId: refundRef.id, amount, status: "REQUESTED" };
  }

  async approveRefund(params: {
    refundId: string;
    adminId: string;
    razorpayRefundId?: string;
  }): Promise<void> {
    const refundRef = db.collection(collections.refunds).doc(params.refundId);
    const snapshot = await refundRef.get();
    if (!snapshot.exists) throw new HttpsError("not-found", "Refund not found.");
    const refund = snapshot.data()!;
    if (refund.status === "PROCESSED") return;

    await refundRef.set(
      {
        status: "PROCESSED",
        approvedBy: params.adminId,
        razorpayRefundId: params.razorpayRefundId ?? null,
        updatedAt: FieldValue.serverTimestamp(),
        processedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await db.collection(collections.orders).doc(String(refund.orderId)).set(
      {
        paymentStatus: "REFUNDED",
        refundAmount: Number(refund.amount),
        refundId: params.refundId,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await this.wallets.record({
      userId: String(refund.customerId),
      role: "consumer",
      type: "REFUND",
      direction: "CREDIT",
      amount: Number(refund.amount),
      createdBy: params.adminId,
      orderId: String(refund.orderId),
      refundId: params.refundId,
    });
  }

  async rejectRefund(params: {
    refundId: string;
    adminId: string;
    reason: string;
  }): Promise<void> {
    await db.collection(collections.refunds).doc(params.refundId).set(
      {
        status: "REJECTED",
        rejectedBy: params.adminId,
        rejectionReason: params.reason,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
}
