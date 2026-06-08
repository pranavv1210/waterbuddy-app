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

  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.consumer:
        return const Color(0xFF007AFF); // Sky/Water Blue
      case AppRole.seller:
        return const Color(0xFF0ea5e9); // Owner Cyan
      case AppRole.driver:
        return const Color(0xFF10b981); // Driver Green
      case AppRole.admin:
        return const Color(0xFF6366f1); // Indigo
    }
  }

  @override
  Widget build(BuildContext context) {
    final switchOptions =
        AppRole.values.where((r) => r != widget.activeRole).toList();
    final roleColor = _getRoleColor(widget.activeRole);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8FAFC), // Off-white clean background
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            // Soft Light Ambient Background Shapes
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: roleColor.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEEF7FF).withOpacity(0.7),
                ),
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
                                horizontal: 24, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Role Selector Tabs (Uber style, clean pill)
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  child: keyboardOpen
                                      ? const SizedBox.shrink()
                                      : Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9), // slate 100
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: const Color(0xFFE2E8F0)), // slate 200
                                          ),
                                          child: Row(
                                            children: [
                                              // Display active role first
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.05),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      widget.activeRole.name.toUpperCase(),
                                                      style: TextStyle(
                                                        color: roleColor,
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 11,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              ...switchOptions.map((role) {
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
                                                  child: GestureDetector(
                                                    onTap: () => _switchRole(role),
                                                    behavior: HitTestBehavior.opaque,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                      child: Center(
                                                        child: Text(
                                                          label,
                                                          style: const TextStyle(
                                                            color: Color(0xFF64748B), // Slate 500
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        ),
                                ),
                                SizedBox(height: keyboardOpen ? 12 : 36),
                                // App Branding / Logo
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF7FF),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFFDCEFFF),
                                            width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.water_drop_rounded,
                                        color: Color(0xFF007AFF),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'WaterBuddy',
                                      style: TextStyle(
                                        color: Color(0xFF0F172A), // Slate 900
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: keyboardOpen ? 16 : 32),
                                // Title and Subtitle
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                      color: const Color(0xFF0F172A), // Slate 900
                                      fontSize: keyboardOpen ? 18 : 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5),
                                  textAlign: TextAlign.center,
                                ),
                                if (widget.subtitle.isNotEmpty &&
                                    !keyboardOpen) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.subtitle,
                                    style: const TextStyle(
                                        color: Color(0xFF64748B), // Slate 500
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                SizedBox(height: keyboardOpen ? 16 : 28),
                                // Child screen contents
                                widget.child,
                                const SizedBox(height: 24),
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
            // Toast Notification Overlay
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
                        color: const Color(0xFF0F172A), // Slate 900
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF10B981), size: 20),
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
