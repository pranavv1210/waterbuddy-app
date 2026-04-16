import '../models/payment_checkout.dart';

class MockPaymentRepository {
  Future<PaymentCheckout> getCheckout() async {
    return const PaymentCheckout(
      title: 'Payment',
      userAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDssUhzY_5Yzl3LNNxVw_wmsOOFp-knQvEiEs4DUoEsKV_Rzs0E4JGdKRjPGWNQh8B-sgfqCaEz4jREy1TvXz023w8sQZHpvRb4QeZ7S7IpTt4V1_swehmd-aNIpMzi_5TIDy3U2Kz4ys9eg8Sp1CA2jN7Ipi3_4GQgB3_NFPMFYhK5k4nTR7bMITIL9rwcTtnrosGoq5HWojeqWiIfwWtSOIGpxHKrcooqMjiQwPX9xqQu0fcjBJW5owegcV5CIl2_DWaCqH7BylA',
      summary: PaymentSummary(
        productTitle: 'Premium Hydration Pack',
        deliveryLabel: 'Standard Delivery (30-45 mins)',
        statusLabel: 'Active Order',
        lineItems: [
          PaymentLineItem(label: 'Base Price (20L x 5)', value: '\$45.00'),
          PaymentLineItem(label: 'Delivery Fee', value: 'FREE', highlight: true),
          PaymentLineItem(label: 'Platform Tax (18%)', value: '\$8.10'),
        ],
        totalAmount: '\$53.10',
      ),
      methods: [
        PaymentMethodOption(
          id: 'upi',
          title: 'UPI Transfer',
          subtitle: 'Pay via GPay, PhonePe, or BHIM',
          iconKey: 'wallet',
        ),
        PaymentMethodOption(
          id: 'card',
          title: 'Debit / Credit Cards',
          subtitle: 'Visa, Mastercard, RuPay, Amex',
          iconKey: 'card',
        ),
        PaymentMethodOption(
          id: 'cod',
          title: 'Cash on Delivery',
          subtitle: 'Pay when your water arrives',
          iconKey: 'cash',
        ),
      ],
      securityLabel: 'Secure 256-bit encrypted checkout',
      totalLabel: '\$53.10',
      payButtonLabel: 'Pay Now',
    );
  }
}
