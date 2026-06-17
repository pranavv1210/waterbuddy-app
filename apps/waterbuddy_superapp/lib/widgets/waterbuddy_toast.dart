import 'dart:ui';
import 'package:flutter/material.dart';

import 'premium_ui.dart';

enum WaterBuddyToastType { success, error, info, warning }

class WaterBuddyToastService {
  static void success(BuildContext context, String message) {
    WaterBuddyToast.show(context, message, type: WaterBuddyToastType.success);
  }

  static void error(BuildContext context, String message) {
    WaterBuddyToast.show(context, message, type: WaterBuddyToastType.error);
  }

  static void info(BuildContext context, String message) {
    WaterBuddyToast.show(context, message, type: WaterBuddyToastType.info);
  }

  static void warning(BuildContext context, String message) {
    WaterBuddyToast.show(context, message, type: WaterBuddyToastType.warning);
  }
}

class WaterBuddyToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    WaterBuddyToastType? type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type ??
            (isError ? WaterBuddyToastType.error : WaterBuddyToastType.success),
        onDismiss: () {
          try {
            overlayEntry.remove();
          } catch (_) {}
        },
        duration: duration,
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  final String message;
  final WaterBuddyToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 350), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;
    final screenWidth = MediaQuery.of(context).size.width;
    final colors = _ToastVisuals.forType(widget.type);

    return Positioned(
      top: safeArea.top + 16,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 500 ? 460 : screenWidth - 32,
          ),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.color.withValues(alpha: 0.24),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              colors.icon,
                              color: colors.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                color: WbColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _controller
                                  .reverse()
                                  .then((_) => widget.onDismiss());
                            },
                            child: Icon(
                              Icons.close_rounded,
                              color: WbColors.muted.withValues(alpha: 0.7),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastVisuals {
  const _ToastVisuals({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  static _ToastVisuals forType(WaterBuddyToastType type) {
    switch (type) {
      case WaterBuddyToastType.success:
        return const _ToastVisuals(
          color: WbColors.green,
          icon: Icons.check_circle_rounded,
        );
      case WaterBuddyToastType.error:
        return const _ToastVisuals(
          color: WbColors.red,
          icon: Icons.error_rounded,
        );
      case WaterBuddyToastType.info:
        return const _ToastVisuals(
          color: WbColors.blue,
          icon: Icons.info_rounded,
        );
      case WaterBuddyToastType.warning:
        return const _ToastVisuals(
          color: WbColors.amber,
          icon: Icons.warning_rounded,
        );
    }
  }
}
