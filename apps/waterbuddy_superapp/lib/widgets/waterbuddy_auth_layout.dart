import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/app_role.dart';
import '../providers/app_providers.dart';
import '../routes/route_names.dart';

class WaterBuddyAuthLayout extends ConsumerStatefulWidget {
  final AppRole activeRole;
  final String title;
  final String subtitle;
  final Widget child;

  const WaterBuddyAuthLayout({
    super.key,
    required this.activeRole,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  ConsumerState<WaterBuddyAuthLayout> createState() =>
      _WaterBuddyAuthLayoutState();
}

class _WaterBuddyAuthLayoutState extends ConsumerState<WaterBuddyAuthLayout>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _toastController;
  late final Animation<Offset> _toastOffset;
  final ScrollController _scrollController = ScrollController();
  String _toastMessage = '';
  bool _showToast = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_handleFocusChange);
    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _toastOffset = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _toastController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleFocusChange);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _toastController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _ensureFocusedFieldVisible(const Duration(milliseconds: 280));
  }

  void _handleFocusChange() {
    _ensureFocusedFieldVisible(const Duration(milliseconds: 90));
  }

  void _ensureFocusedFieldVisible(Duration delay) {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) return;

    Future.delayed(delay, () {
      if (!focusedContext.mounted) return;
      Scrollable.ensureVisible(
        focusedContext,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _triggerToast(String message) {
    if (!mounted) return;
    setState(() {
      _toastMessage = message;
      _showToast = true;
    });
    _toastController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _toastController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showToast = false;
            });
          }
        });
      }
    });
  }

  void _switchRole(AppRole role) {
    String roleLabel = '';
    String route = '';

    switch (role) {
      case AppRole.consumer:
        roleLabel = 'Consumer';
        route = RouteNames.authConsumer;
        break;
      case AppRole.seller:
        roleLabel = 'Tanker Owner';
        route = RouteNames.authSeller;
        break;
      case AppRole.driver:
        roleLabel = 'Driver';
        route = RouteNames.authDriver;
        break;
      case AppRole.admin:
        roleLabel = 'Admin User';
        route = RouteNames.authAdmin;
        break;
    }

    _triggerToast('Switched to $roleLabel');
    ref.read(selectedRoleProvider.notifier).set(role);
    context.go(route);
  }

  List<Color> _getRoleColors(AppRole role) {
    switch (role) {
      case AppRole.consumer:
        return [
          const Color(0xFF0EA5E9), // Radiant Sky Blue
          const Color(0xFF0F766E), // Muted Teal
        ];
      case AppRole.seller:
        return [
          const Color(0xFF14B8A6), // Teal Glow
          const Color(0xFF0891B2), // Rich Cyan
        ];
      case AppRole.driver:
        return [
          const Color(0xFF6366F1), // Violet
          const Color(0xFF3B82F6), // Blue
        ];
      case AppRole.admin:
        return [
          const Color(0xFFEC4899), // Pink
          const Color(0xFF4F46E5), // Royal Indigo
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final switchOptions =
        AppRole.values.where((r) => r != widget.activeRole).toList();
    final gradientColors = _getRoleColors(widget.activeRole);
    final darkBg = const Color(0xFF090D16); // Obsidian deep dark background
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: darkBg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            // Ambient glowing background orbs
            Positioned(
              top: -120,
              left: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradientColors[0].withOpacity(0.28),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradientColors[1].withOpacity(0.25),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
                child: Container(color: Colors.transparent),
              ),
            ),
            SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Column(
                              children: [
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  child: keyboardOpen
                                      ? const SizedBox.shrink()
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.04),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.white.withOpacity(0.08)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: switchOptions.map((role) {
                                              String label = '';
                                              switch (role) {
                                                case AppRole.consumer:
                                                  label = 'Consumer';
                                                  break;
                                                case AppRole.seller:
                                                  label = 'Owner';
                                                  break;
                                                case AppRole.driver:
                                                  label = 'Driver';
                                                  break;
                                                case AppRole.admin:
                                                  label = 'Admin';
                                                  break;
                                              }

                                              return Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 4),
                                                  child: OutlinedButton(
                                                    onPressed: () =>
                                                        _switchRole(role),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      foregroundColor:
                                                          Colors.white.withOpacity(0.8),
                                                      side: BorderSide(
                                                          color: Colors.white.withOpacity(0.12),
                                                          width: 1),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 10),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      label,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                ),
                                SizedBox(height: keyboardOpen ? 12 : 40),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  width: keyboardOpen ? 48 : 88,
                                  height: keyboardOpen ? 48 : 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.04),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.12),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gradientColors[0].withOpacity(0.15),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(Icons.water_drop_rounded,
                                        color: gradientColors[0],
                                        size: keyboardOpen ? 24 : 44),
                                  ),
                                ),
                                SizedBox(height: keyboardOpen ? 8 : 16),
                                Text(
                                  'WATERBUDDY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: keyboardOpen ? 18 : 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: keyboardOpen ? 16 : 40),
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: keyboardOpen ? 18 : 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5),
                                  textAlign: TextAlign.center,
                                ),
                                if (widget.subtitle.isNotEmpty &&
                                    !keyboardOpen) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.subtitle,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                SizedBox(height: keyboardOpen ? 14 : 28),
                                widget.child,
                                SizedBox(height: keyboardOpen ? 16 : 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showToast)
              Positioned(
                top: 50,
                left: 24,
                right: 24,
                child: SlideTransition(
                  position: _toastOffset,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(_toastMessage,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
