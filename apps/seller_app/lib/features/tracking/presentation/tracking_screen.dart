import 'package:flutter/material.dart';

import '../../../widgets/feature_placeholder.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Tracking',
      description: 'Seller location streaming controls and delivery tracking render here.',
    );
  }
}
