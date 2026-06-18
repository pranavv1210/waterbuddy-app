import { FieldValue, Transaction } from "firebase-admin/firestore";
import { LoggerService } from "./loggerService";
import { collections } from "../constants/collections";
import {
  WalletRole,
  WalletTransactionDirection,
  WalletTransactionType,
} from "../models/domain";
import { db } from "./firebase";

export function walletId(role: WalletRole, userId: string): string {
  return `${role}_${userId}`;
}

export class WalletService {
  async record(params: {
    userId: string;
    role: WalletRole;
    type: WalletTransactionType;
    direction: WalletTransactionDirection;
    amount: number;
    createdBy: string;
    orderId?: string;
    payoutId?: string;
    refundId?: string;
    metadata?: Record<string, unknown>;
  }): Promise<void> {
    if (!Number.isFinite(params.amount) || params.amount < 0) {
      throw new Error("Wallet transaction amount must be non-negative.");
    }

    const id = walletId(params.role, params.userId);
    const walletRef = db.collection(collections.wallets).doc(id);
    const txRef = db.collection(collections.walletTransactions).doc();

    await db.runTransaction(async (tx) => {
      const snapshot = await tx.get(walletRef);
      const current = snapshot.data() ?? {};
      const balance = Number(current.balance ?? 0);
      const lockedBalance = Number(current.lockedBalance ?? 0);
      const totalEarned = Number(current.totalEarned ?? 0);
      const totalSpent = Number(current.totalSpent ?? 0);

      let nextBalance = balance;
      let nextLocked = lockedBalance;
      let nextEarned = totalEarned;
      let nextSpent = totalSpent;

      switch (params.direction) {
        case "CREDIT":
          nextBalance += params.amount;
          nextEarned += params.amount;
          break;
        case "DEBIT":
          if (balance < params.amount) throw new Error("Insufficient wallet balance.");
          nextBalance -= params.amount;
          nextSpent += params.amount;
          break;
        case "LOCK_CREDIT":
          nextLocked += params.amount;
          nextEarned += params.amount;
          break;
        case "UNLOCK_DEBIT":
          if (lockedBalance < params.amount) throw new Error("Insufficient locked balance.");
          nextLocked -= params.amount;
          nextSpent += params.amount;
          break;
        case "EXTERNAL_SPEND":
          nextSpent += params.amount;
          break;
      }

      tx.set(
        walletRef,
        {
          id,
          userId: params.userId,
          role: params.role,
          balance: nextBalance,
          lockedBalance: nextLocked,
          totalEarned: nextEarned,
          totalSpent: nextSpent,
          createdAt: snapshot.exists ? current.createdAt : FieldValue.serverTimestamp(),
          lastUpdated: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      tx.set(txRef, {
        id: txRef.id,
        walletId: id,
        userId: params.userId,
        role: params.role,
        type: params.type,
        direction: params.direction,
        amount: params.amount,
        balanceAfter: nextBalance,
        lockedBalanceAfter: nextLocked,
        orderId: params.orderId ?? null,
        payoutId: params.payoutId ?? null,
        refundId: params.refundId ?? null,
        createdBy: params.createdBy,
        metadata: params.metadata ?? {},
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    LoggerService.info("WALLET", "Wallet transaction recorded", { userId: params.userId }, {
      role: params.role,
      type: params.type,
      direction: params.direction,
      amount: params.amount,
    });
  }

  recordInTransaction(
    tx: Transaction,
    params: {
      userId: string;
      role: WalletRole;
      type: WalletTransactionType;
      direction: WalletTransactionDirection;
      amount: number;
      createdBy: string;
      balance: number;
      lockedBalance: number;
      totalEarned: number;
      totalSpent: number;
      orderId?: string;
      payoutId?: string;
      refundId?: string;
      metadata?: Record<string, unknown>;
    }
  ): {
    balance: number;
    lockedBalance: number;
    totalEarned: number;
    totalSpent: number;
  } {
    const id = walletId(params.role, params.userId);
    const walletRef = db.collection(collections.wallets).doc(id);
    const txRef = db.collection(collections.walletTransactions).doc();
    let balance = params.balance;
    let lockedBalance = params.lockedBalance;
    let totalEarned = params.totalEarned;
    let totalSpent = params.totalSpent;

    if (params.direction === "CREDIT") {
      balance += params.amount;
      totalEarned += params.amount;
    } else if (params.direction === "DEBIT") {
      if (balance < params.amount) throw new Error("Insufficient wallet balance.");
      balance -= params.amount;
      totalSpent += params.amount;
    } else if (params.direction === "LOCK_CREDIT") {
      lockedBalance += params.amount;
      totalEarned += params.amount;
    } else if (params.direction === "UNLOCK_DEBIT") {
      if (lockedBalance < params.amount) throw new Error("Insufficient locked balance.");
      lockedBalance -= params.amount;
      totalSpent += params.amount;
    } else {
      totalSpent += params.amount;
    }

    tx.set(
      walletRef,
      {
        id,
        userId: params.userId,
        role: params.role,
        balance,
        lockedBalance,
        totalEarned,
        totalSpent,
        lastUpdated: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    tx.set(txRef, {
      id: txRef.id,
      walletId: id,
      userId: params.userId,
      role: params.role,
      type: params.type,
      direction: params.direction,
      amount: params.amount,
      balanceAfter: balance,
      lockedBalanceAfter: lockedBalance,
      orderId: params.orderId ?? null,
      payoutId: params.payoutId ?? null,
      refundId: params.refundId ?? null,
      createdBy: params.createdBy,
      metadata: params.metadata ?? {},
      createdAt: FieldValue.serverTimestamp(),
    });

    return { balance, lockedBalance, totalEarned, totalSpent };
  }
}
