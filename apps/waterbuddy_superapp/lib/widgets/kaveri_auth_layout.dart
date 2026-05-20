import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/app_role.dart';
import '../providers/app_providers.dart';
import '../routes/route_names.dart';

class KaveriAuthLayout extends ConsumerStatefulWidget {
  final AppRole activeRole;
  final String title;
  final String subtitle;
  final Widget child;

  const KaveriAuthLayout({
    super.key,
    required this.activeRole,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  ConsumerState<KaveriAuthLayout> createState() => _KaveriAuthLayoutState();
}

class _KaveriAuthLayoutState extends ConsumerState<KaveriAuthLayout> with SingleTickerProviderStateMixin {
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
        roleLabel = 'Subdivision User';
        route = RouteNames.authAdmin;
        break;
    }

    _triggerToast('Switched to $roleLabel');
    ref.read(selectedRoleProvider.notifier).set(role);

    // Wait a brief moment for toast animation initiation, then navigate
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.go(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get all roles except the currently active one
    final switchOptions = AppRole.values.where((r) => r != widget.activeRole).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0369A1), // Sky Blue/Teal base
      body: Stack(
        children: [
          // Elegant Sky Blue to Cyan gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Bottom background curves / waves visual representation
          Positioned(
            bottom: -50,
            left: -50,
            right: -50,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Main Form Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        // Top Switcher Row
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
                                case AppRole.consumer:
                                  label = 'Consumer';
                                  break;
                                case AppRole.seller:
                                  label = 'Tanker Owner';
                                  break;
                                case AppRole.driver:
                                  label = 'Driver';
                                  break;
                                case AppRole.admin:
                                  label = 'Subdivision';
                                  break;
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

                        const SizedBox(height: 32),

                        // Emblem
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0369A1),
                            border: Border.all(color: const Color(0xFFFBBF24), width: 4), // Gold rim
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Droplet background detail
                              Icon(
                                Icons.water_drop,
                                color: Colors.white.withOpacity(0.1),
                                size: 85,
                              ),
                              // Crest content
                              const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.water_drop_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'ಕಾವೇರಿ',
                                    style: TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'WATERBUDDY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Board Text
                        const Text(
                          'Bangalore Water Supply and\nSewerage Board',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Role Header
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Inserted children forms
                        widget.child,

                        const SizedBox(height: 40),

                        // Footer / Copyright Sanchari Kaveri Style
                        Text(
                          'Version 1.0.34',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© 2026, All Rights Reserved by BWSSB, Bangalore',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Animated Top Banner Switch Toast
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
                      color: const Color(0xFF10B981), // Emerald banner
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _toastMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
