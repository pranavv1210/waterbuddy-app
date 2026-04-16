class PaymentCheckout {
  const PaymentCheckout({
    required this.title,
    required this.userAvatarUrl,
    required this.summary,
    required this.methods,
    required this.securityLabel,
    required this.totalLabel,
    required this.payButtonLabel,
  });

  final String title;
  final String userAvatarUrl;
  final PaymentSummary summary;
  final List<PaymentMethodOption> methods;
  final String securityLabel;
  final String totalLabel;
  final String payButtonLabel;
}

class PaymentSummary {
  const PaymentSummary({
    required this.productTitle,
    required this.deliveryLabel,
    required this.statusLabel,
    required this.lineItems,
    required this.totalAmount,
  });

  final String productTitle;
  final String deliveryLabel;
  final String statusLabel;
  final List<PaymentLineItem> lineItems;
  final String totalAmount;
}

class PaymentLineItem {
  const PaymentLineItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;
}

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconKey,
  });

  final String id;
  final String title;
  final String subtitle;
  final String iconKey;
}
