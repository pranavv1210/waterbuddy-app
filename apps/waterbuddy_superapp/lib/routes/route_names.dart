class RouteNames {
  static const splash = '/';
  static const roleSelection = '/role-selection';

  static const authConsumer = '/auth/consumer';
  static const authConsumerLogin = '/auth/consumer/login';
  static const authConsumerSignup = '/auth/consumer/signup';
  static const authConsumerOtp = '/auth/consumer/otp';

  static const authSeller = '/auth/seller';
  static const authSellerLogin = '/auth/seller/login';
  static const authSellerSignup = '/auth/seller/signup';

  static const authDriver = '/auth/driver';
  static const authDriverLogin = '/auth/driver/login';
  static const authDriverSignup = '/auth/driver/signup';
  static const authDriverOtp = '/auth/driver/otp';

  static const authAdmin = '/auth/admin';
  
  static const auth = authConsumer;
  static const otp = authConsumerOtp;

  static const consumerHome = '/consumer/home';
  static const consumerOrders = '/consumer/orders';
  static const consumerProfile = '/consumer/profile';
  static const home = consumerHome;
  static const orders = consumerOrders;
  static const profile = consumerProfile;

  static const searching = '/consumer/searching';
  static const tracking = '/consumer/tracking';
  static const orderComplete = '/consumer/order-complete';
  static const orderDetails = '/consumer/order-details';
  static const payments = '/consumer/payments';
  static const locationSelection = '/consumer/location-selection';

  static const sellerDashboard = '/seller/dashboard';
  static const sellerWaiting = '/seller/waiting';
  static const sellerBlocked = '/seller/blocked';
  static const driverDashboard = '/driver/dashboard';
  static const adminDashboard = '/admin/dashboard';
  static const unauthorized = '/unauthorized';
}
