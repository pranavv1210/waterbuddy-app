import 'package:flutter/material.dart';

import '../../../widgets/feature_placeholder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Home',
      description: 'Seller dashboard state such as availability and pending requests loads here.',
    );
  }
}
