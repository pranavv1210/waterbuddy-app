export type OrderStatus = "pending" | "accepted" | "in_progress" | "delivered" | "cancelled" | "assigned" | string;

export interface OrderRecord {
  id: string;
  customer: string;
  seller: string;
  status: OrderStatus;
  paymentType: string;
  tankSize: string;
  createdAt?: number | string;
  items?: string;
  quantity?: number;
}

export interface SellerRecord {
  id: string;
  name: string;
  phone: string;
  location: string;
  kycStatus: string;
  onlineStatus: boolean;
  enabled: boolean;
  rating?: number;
}

export interface UserRecord {
  id: string;
  name: string;
  phone: string;
  role: string;
  email: string;
  totalOrders: number;
  joinDate?: number | string;
  blocked: boolean;
  lifetimeValue?: number;
}

export interface ComplaintRecord {
  id: string;
  customer: string;
  seller: string;
  orderId: string;
  issueType: string;
  status: string;
  reason: string;
  priority: string;
  createdAt?: number | string;
}

export interface PaymentSummary {
  totalRevenue: number;
  codRevenue: number;
  onlineRevenue: number;
  codCount: number;
  onlineCount: number;
}

export interface WeeklyRevenueItem {
  label: string;
  gross: number;
  net: number;
}

export interface PaymentPayoutRecord {
  id: string;
  sellerName: string;
  sellerCode: string;
  transactionId: string;
  date?: number | string;
  amount: number;
  status: string;
}

export interface PaymentDashboardData {
  summary: PaymentSummary;
  weeklyRevenue: WeeklyRevenueItem[];
  recentPayouts: PaymentPayoutRecord[];
}
