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
  ConsumerState<WaterBuddyAuthLayout> createState() => _WaterBuddyAuthLayoutState();
}

class _WaterBuddyAuthLayoutState extends ConsumerState<WaterBuddyAuthLayout> with SingleTickerProviderStateMixin {
  late final AnimationController _toastController;
  late final Animation<Offset> _toastOffset;
  String _toastMessage = '';
  bool _showToast = false;

  @override
  void initState() {
    super.initState();
    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _toastOffset = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _toastController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _toastController.dispose();
    super.dispose();
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

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.go(route);
      }
    });
  }

  List<Color> _getRoleColors(AppRole role) {
    switch (role) {
      case AppRole.consumer:
        return [const Color(0xFF38BDF8), const Color(0xFF0284C7), const Color(0xFF0369A1)];
      case AppRole.seller:
        return [const Color(0xFF34D399), const Color(0xFF059669), const Color(0xFF047857)];
      case AppRole.driver:
        return [const Color(0xFFFBBF24), const Color(0xFFD97706), const Color(0xFFB45309)];
      case AppRole.admin:
        return [const Color(0xFFC084FC), const Color(0xFF9333EA), const Color(0xFF7E22CE)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final switchOptions = AppRole.values.where((r) => r != widget.activeRole).toList();
    final gradientColors = _getRoleColors(widget.activeRole);
    final baseColor = gradientColors.last;

    return Scaffold(
      backgroundColor: baseColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            right: -50,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: switchOptions.map((role) {
                              String label = '';
                              switch (role) {
                                case AppRole.consumer: label = 'Consumer'; break;
                                case AppRole.seller: label = 'Tanker Owner'; break;
                                case AppRole.driver: label = 'Driver'; break;
                                case AppRole.admin: label = 'Admin'; break;
                              }

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: OutlinedButton(
                                    onPressed: () => _switchRole(role),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.water_drop_rounded, color: Colors.white, size: 45),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'WATERBUDDY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          widget.title,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.subtitle,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 28),
                        widget.child,
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
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
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(_toastMessage, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
