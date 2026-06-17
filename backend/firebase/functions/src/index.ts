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
} from "./modules/cleanup/scheduledCleanup";

// ── Ratings ───────────────────────────────────────────────────────────────────
export { submitRatingFn as submitRating } from "./modules/ratings/submitRating";
export { onRatingCreated } from "./modules/ratings/onRatingCreated";
