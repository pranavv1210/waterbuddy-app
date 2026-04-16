import 'package:flutter/material.dart';

import '../../../widgets/feature_placeholder.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Payments',
      description: 'Razorpay integration and payment state orchestration plug in here.',
    );
  }
}
