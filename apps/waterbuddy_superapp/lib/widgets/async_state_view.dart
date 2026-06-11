import 'package:flutter/material.dart';

import 'premium_ui.dart';

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.child,
  });

  final bool isLoading;
  final bool hasError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const WaterBuddyLoader(
        message: 'Loading latest WaterBuddy data',
        compact: true,
      );
    }

    if (hasError) {
      return const Center(
        child: GlassPanel(
          padding: EdgeInsets.all(18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_rounded, color: WbColors.red),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Unable to load state.',
                  style: TextStyle(
                    color: WbColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}
