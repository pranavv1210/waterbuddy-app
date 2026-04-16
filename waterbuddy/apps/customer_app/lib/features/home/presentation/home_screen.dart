import 'package:flutter/material.dart';

import '../../../widgets/feature_placeholder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Home',
      description: 'Customer dashboard widgets will bind to live Firestore state here.',
    );
  }
}
