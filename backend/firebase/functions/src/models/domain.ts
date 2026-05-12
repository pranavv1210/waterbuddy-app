export type UserRole = "consumer" | "customer" | "seller" | "driver" | "admin";
export type OrderStatus =
  | "SEARCHING"
  | "ASSIGNED"
  | "DRIVER_ASSIGNED"
  | "ON_THE_WAY"
  | "ARRIVED"
  | "DELIVERED"
  | "CANCELLED";
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

export interface OrderLocation {
  address: string;
  lat: number;
  lng: number;
}

export interface OrderRecord {
  id: string;
  customerId: string;
  sellerId: string | null;
  driverId?: string | null;
  tankSize: number;
  status: OrderStatus;
  paymentType: PaymentType;
  paymentStatus: PaymentStatus;
  location: OrderLocation;
  candidateSellerIds: string[];
  rejectedSellerIds: string[];
  assignedAt?: FirebaseFirestore.Timestamp;
  startedAt?: FirebaseFirestore.Timestamp;
  deliveredAt?: FirebaseFirestore.Timestamp;
  createdAt?: FirebaseFirestore.Timestamp;
  updatedAt?: FirebaseFirestore.Timestamp;
}
