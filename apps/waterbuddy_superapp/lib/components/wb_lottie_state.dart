import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../animations/lottie_assets.dart';
import '../widgets/premium_ui.dart';

enum WbLottieStateType {
  searching,
  success,
  paymentSuccess,
  delivered,
  empty,
  noInternet,
  locationDenied,
  noOrders,
}

class WbLottieState extends StatelessWidget {
  const WbLottieState({
    super.key,
    required this.type,
    this.size = 132,
    this.repeat = true,
  });

  final WbLottieStateType type;
  final double size;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      _assetFor(type),
      width: size,
      height: size,
      repeat: repeat,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return AnimatedPulse(
          animation: const AlwaysStoppedAnimation(0.4),
          color: _colorFor(type),
          icon: _iconFor(type),
          size: size,
        );
      },
    );
  }

  static String _assetFor(WbLottieStateType type) {
    return switch (type) {
      WbLottieStateType.searching => WbLottieAssets.searching,
      WbLottieStateType.success => WbLottieAssets.success,
      WbLottieStateType.paymentSuccess => WbLottieAssets.paymentSuccess,
      WbLottieStateType.delivered => WbLottieAssets.delivered,
      WbLottieStateType.empty => WbLottieAssets.empty,
      WbLottieStateType.noInternet => WbLottieAssets.noInternet,
      WbLottieStateType.locationDenied => WbLottieAssets.locationDenied,
      WbLottieStateType.noOrders => WbLottieAssets.noOrders,
    };
  }

  static Color _colorFor(WbLottieStateType type) {
    return switch (type) {
      WbLottieStateType.success ||
      WbLottieStateType.paymentSuccess ||
      WbLottieStateType.delivered =>
        WbColors.green,
      WbLottieStateType.noInternet ||
      WbLottieStateType.locationDenied =>
        WbColors.red,
      _ => WbColors.blue,
    };
  }

  static IconData _iconFor(WbLottieStateType type) {
    return switch (type) {
      WbLottieStateType.searching => Icons.radar_rounded,
      WbLottieStateType.success => Icons.check_rounded,
      WbLottieStateType.paymentSuccess => Icons.payments_rounded,
      WbLottieStateType.delivered => Icons.local_shipping_rounded,
      WbLottieStateType.noInternet => Icons.wifi_off_rounded,
      WbLottieStateType.locationDenied => Icons.location_off_rounded,
      WbLottieStateType.noOrders => Icons.receipt_long_rounded,
      WbLottieStateType.empty => Icons.inbox_rounded,
    };
  }
}
