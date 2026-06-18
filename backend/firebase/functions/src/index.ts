// ── Auth ─────────────────────────────────────────────────────────────────────
export { setRoleClaims } from "./modules/auth/setRoleClaims";

// ── Orders ───────────────────────────────────────────────────────────────────
export { placeOrder } from "./modules/orders/placeOrder";
export { onOrderCreated } from "./modules/orders/onOrderCreated";
export { onOfferUpdated } from "./modules/orders/onOfferUpdated";
export { acceptOrder } from "./modules/orders/acceptOrder";
export { rejectOffer } from "./modules/orders/rejectOffer";
export { expireOffers } from "./modules/orders/expireOffers";
export { onOrderStatusChanged } from "./modules/orders/onOrderStatusChanged";

// ── Tracking ─────────────────────────────────────────────────────────────────
export { updateTracking } from "./modules/tracking/updateTracking";

// ── Payments ─────────────────────────────────────────────────────────────────
export { paymentWebhook } from "./modules/payments/paymentWebhook";
export { createRazorpayOrder } from "./modules/payments/createRazorpayOrder";
export { verifyPayment } from "./modules/payments/verifyPayment";

// ── Cleanup (Scheduled) ───────────────────────────────────────────────────────
export {
  cleanupExpiredOffers,
  cleanupStaleOrders,
  cleanupOrphanNotifications,
  cleanupInactiveLocations,
  cleanupOldDispatchLogs,
  cleanupOldMetrics,
  cleanupOrphanSessions,
} from "./modules/cleanup/scheduledCleanup";

// ── Ratings ───────────────────────────────────────────────────────────────────
export { submitRatingFn as submitRating } from "./modules/ratings/submitRating";
export { onRatingCreated } from "./modules/ratings/onRatingCreated";

// Metrics
export {
  onSellerPresenceChanged,
  onDriverPresenceChanged,
} from "./modules/metrics/onPresenceChanged";

// Finance
export { requestRefund } from "./modules/finance/requestRefund";
export { approveRefund } from "./modules/finance/approveRefund";
export { rejectRefund } from "./modules/finance/rejectRefund";
export { approveDriverPayout } from "./modules/finance/approveDriverPayout";
export { approveSellerPayout } from "./modules/finance/approveSellerPayout";
