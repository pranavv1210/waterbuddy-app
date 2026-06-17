import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'premium_ui.dart';

class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WbColors.surface,
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          const AbstractWaterBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassPanel(
                radius: 28,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: WbColors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: WbColors.blue,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: WbColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: WbColors.muted,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}
