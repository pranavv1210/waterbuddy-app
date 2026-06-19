import 'package:flutter/material.dart';

class WbTokens {
  const WbTokens._();

  static const blue50 = Color(0xFFF0F9FF);
  static const blue100 = Color(0xFFE0F2FE);
  static const blue500 = Color(0xFF0EA5E9);
  static const blue600 = Color(0xFF0284C7);
  static const blue700 = Color(0xFF0369A1);

  static const white = Colors.white;
  static const surface = Color(0xFFF8FAFC);
  static const surfaceSoft = Color(0xFFF1F5F9);
  static const ink = Color(0xFF08111F);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;

  static const radius12 = 12.0;
  static const radius16 = 16.0;
  static const radius20 = 20.0;
  static const radius24 = 24.0;
  static const radius32 = 32.0;
  static const radiusPill = 999.0;

  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);

  static const ease = Curves.easeOutCubic;
  static const spring = Curves.easeOutBack;

  static List<BoxShadow> elevation1([Color color = ink]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> elevation2([Color color = ink]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ];

  static List<BoxShadow> elevationMapSheet([Color color = ink]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.16),
          blurRadius: 34,
          offset: const Offset(0, -14),
        ),
      ];
}
