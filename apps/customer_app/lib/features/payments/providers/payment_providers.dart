import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_payment_repository.dart';
import '../models/payment_checkout.dart';

final paymentRepositoryProvider = Provider<MockPaymentRepository>(
  (ref) => MockPaymentRepository(),
);

final paymentCheckoutProvider = FutureProvider<PaymentCheckout>(
  (ref) => ref.watch(paymentRepositoryProvider).getCheckout(),
);

final selectedPaymentMethodProvider = StateProvider<String?>((ref) => 'upi');
