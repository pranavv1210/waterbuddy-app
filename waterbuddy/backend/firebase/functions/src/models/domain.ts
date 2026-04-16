export type UserRole = "customer" | "seller" | "admin";
export type OrderStatus =
  | "SEARCHING"
  | "ASSIGNED"
  | "ON_THE_WAY"
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
  tankSize: number;
  status: OrderStatus;
  paymentType: PaymentType;
  paymentStatus: PaymentStatus;
  location: OrderLocation;
  candidateSellerIds: string[];
  rejectedSellerIds: string[];
  createdAt?: FirebaseFirestore.Timestamp;
  updatedAt?: FirebaseFirestore.Timestamp;
}
