import 'package:flutter/material.dart';

import '../../../widgets/feature_placeholder.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Earnings',
      description: 'Daily payouts, trends, and settlement history render here.',
    );
  }
}
