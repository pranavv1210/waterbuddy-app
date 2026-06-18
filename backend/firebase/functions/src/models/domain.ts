export type UserRole = "consumer" | "customer" | "seller" | "driver" | "admin";
export type OrderStatus =
  | "SEARCHING"
  | "OFFER_SENT"
  | "ACCEPTED"
  | "DRIVER_ASSIGNED"
  | "ON_THE_WAY"
  | "ARRIVED"
  | "DELIVERING"
  | "DELIVERED"
  | "CANCELLED"
  | "NO_PARTNER_FOUND"
  | "FAILED";
export type OfferStatus = "pending" | "accepted" | "rejected" | "expired";
export type PaymentType = "ONLINE" | "COD";
export type PaymentStatus =
  | "PENDING"
  | "PAID"
  | "COD_PENDING"
  | "COMPLETED"
  | "FAILED"
  | "REFUNDED";

export type NotificationType =
  | "ORDER_OFFER"
  | "ORDER_ACCEPTED"
  | "DRIVER_ASSIGNED"
  | "DRIVER_EN_ROUTE"
  | "DRIVER_ARRIVED"
  | "ORDER_DELIVERED"
  | "ORDER_CANCELLED"
  | "PAYMENT_SUCCESS"
  | "PAYMENT_FAILED"
  | "REFUND_INITIATED"
  | "SYSTEM_ALERT";

export interface WaterBuddyUser {
  id: string;
  name: string;
  phone: string;
  role: UserRole;
  createdAt?: FirebaseFirestore.Timestamp;
}

export interface SellerProfile {
  id: string;
  kycStatus: "pending" | "approved" | "rejected";
  isOnline: boolean;
  tankSizes: number[];
  pricing: Record<string, number>;
  serviceArea: {
    geohash: string;
    label: string;
    radiusKm: number;
  };
  averageRating?: number;
  ratingCount?: number;
}

export interface SystemSettings {
  bookingsEnabled: boolean;
  maintenanceMode: boolean;
  dispatchRadiusKm: number;
  offerTimeoutSeconds: number;
  maxDispatchAttempts: number;
}

export interface OrderLocation {
  address: string;
  lat: number;
  lng: number;
}

export interface OrderRecord {
  id: string;
  customerId: string;
  customerName?: string;
  customerPhone?: string;
  sellerId: string | null;
  driverId?: string | null;
  tankSize: number;
  tankLabel?: string;
  tankId?: string;
  amount?: number;
  pricingSnapshot?: Record<string, unknown>;
  status: OrderStatus;
  paymentType: PaymentType;
  paymentStatus: PaymentStatus;
  paymentId?: string | null;
  razorpayOrderId?: string | null;
  location: OrderLocation;
  candidateSellerIds: string[];
  rejectedSellerIds: string[];
  currentOfferId?: string | null;
  dispatchAttempt?: number;
  assignedAt?: FirebaseFirestore.Timestamp;
  startedAt?: FirebaseFirestore.Timestamp;
  deliveredAt?: FirebaseFirestore.Timestamp;
  createdAt?: FirebaseFirestore.Timestamp;
  updatedAt?: FirebaseFirestore.Timestamp;
}

export interface OrderOfferRecord {
  id: string;
  orderId: string;
  sellerId: string;
  driverId: string | null;
  status: OfferStatus;
  attemptNumber: number;
  distanceKm: number;
  expiresAt: FirebaseFirestore.Timestamp;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

// Phase 5 additions ───────────────────────────────────────────────────────────

export interface PaymentEvent {
  id: string;
  orderId: string;
  razorpayPaymentId?: string;
  razorpayOrderId?: string;
  razorpaySignature?: string;
  razorpayRefundId?: string;
  event: "payment_captured" | "payment_failed" | "refund_created" | "cod_confirmed";
  amount?: number;
  currency?: string;
  status: PaymentStatus;
  errorCode?: string;
  errorDescription?: string;
  processedAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
  createdAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
}

export interface RatingRecord {
  id: string;
  orderId: string;
  raterId: string;
  rateeId: string;
  rateeRole: "seller" | "driver" | "customer" | "service";
  stars: number; // 1-5
  comment?: string;
  createdAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
}

export type WalletRole = "consumer" | "seller" | "driver" | "admin";
export type WalletTransactionType =
  | "ORDER_PAYMENT"
  | "PAYOUT"
  | "REFUND"
  | "BONUS"
  | "PENALTY"
  | "ADJUSTMENT";
export type WalletTransactionDirection =
  | "CREDIT"
  | "DEBIT"
  | "LOCK_CREDIT"
  | "UNLOCK_DEBIT"
  | "EXTERNAL_SPEND";
export type PayoutStatus = "PENDING" | "PROCESSING" | "PAID" | "FAILED";
export type RefundStatus = "REQUESTED" | "APPROVED" | "REJECTED" | "PROCESSED";
export type RefundType =
  | "FULL"
  | "PARTIAL"
  | "CANCELLATION"
  | "PAYMENT_FAILURE";

export interface WalletRecord {
  id: string;
  userId: string;
  role: WalletRole;
  balance: number;
  lockedBalance: number;
  totalEarned: number;
  totalSpent: number;
  lastUpdated: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
  createdAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
}

export interface WalletTransactionRecord {
  id: string;
  walletId: string;
  userId: string;
  role: WalletRole;
  type: WalletTransactionType;
  direction: WalletTransactionDirection;
  amount: number;
  balanceAfter: number;
  lockedBalanceAfter: number;
  orderId?: string;
  payoutId?: string;
  refundId?: string;
  createdBy: string;
  metadata?: Record<string, unknown>;
  createdAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
}

export interface DriverPayoutRecord {
  id: string;
  driverId: string;
  amount: number;
  status: PayoutStatus;
  method: string;
  createdAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
  paidAt?: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue | null;
}

export interface SellerPayoutRecord {
  id: string;
  sellerId: string;
  orderId?: string;
  commission: number;
  platformFee: number;
  tax: number;
  netAmount: number;
  status: PayoutStatus;
  method: string;
  createdAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
  paidAt?: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue | null;
}

export interface RefundRecord {
  id: string;
  orderId: string;
  customerId: string;
  amount: number;
  type: RefundType;
  status: RefundStatus;
  reason: string;
  requestedBy: string;
  approvedBy?: string;
  razorpayRefundId?: string;
  createdAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
  updatedAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
  processedAt?: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue | null;
}

export interface RatingAggregate {
  userId: string;
  role: "seller" | "driver";
  averageRating: number;
  ratingCount: number;
  updatedAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
}

export interface AnalyticsCounter {
  date: string; // YYYY-MM-DD
  ordersCreated?: number;
  ordersCompleted?: number;
  ordersCancelled?: number;
  paymentsSuccess?: number;
  paymentsFailed?: number;
  revenue?: number;
  deliveryTimes?: number[];
  totalDeliveries?: number;
  dispatchAttempts?: number;
  averageAcceptanceSeconds?: number;
  updatedAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
}
