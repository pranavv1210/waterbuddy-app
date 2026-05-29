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
  | "FAILED";

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
