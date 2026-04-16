import 'package:flutter/material.dart';

import '../../../widgets/feature_placeholder.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Orders',
      description: 'Assigned and active deliveries stream from Firestore here.',
    );
  }
}
