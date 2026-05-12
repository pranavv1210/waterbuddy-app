import 'package:flutter/material.dart';

class SellerWaitingScreen extends StatelessWidget {
  const SellerWaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Your seller account is under review. Access will be enabled after approval.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
