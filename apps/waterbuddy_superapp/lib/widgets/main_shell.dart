import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routes/route_names.dart';
import '../providers/app_providers.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  int get _currentIndex {
    if (location.startsWith(RouteNames.orders)) return 1;
    if (location.startsWith(RouteNames.profile)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 800;
    const appBg = Color(0xFFFFFBF3);

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RouteNames.home);
      },
      child: isDesktop
          ? Scaffold(
              backgroundColor: appBg,
              body: Row(
                children: [
                  _DesktopSidebar(
                    currentIndex: _currentIndex,
                    onTap: (index) => _navigate(context, index),
                    onSignOut: () => _handleSignOut(context, ref),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: child,
                  ),
                ],
              ),
            )
          : Scaffold(
              backgroundColor: appBg,
              body: child,
              bottomNavigationBar: _WaterBuddyNavBar(
                currentIndex: _currentIndex,
                onTap: (index) => _navigate(context, index),
              ),
            ),
    );
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.home);
        break;
      case 1:
        context.go(RouteNames.orders);
        break;
      case 2:
        context.go(RouteNames.profile);
        break;
    }
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authServiceProvider);
    final roleNotifier = ref.read(selectedRoleProvider.notifier);
    await auth.signOut();
    await roleNotifier.clear();
    if (context.mounted) {
      context.go(RouteNames.roleSelection);
    }
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.currentIndex,
    required this.onTap,
    required this.onSignOut,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.water_drop_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WaterBuddy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Superapp Platform',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Menu navigation options
          _SidebarItem(
            icon: Icons.home_rounded,
            label: 'Order Booking',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          const SizedBox(height: 10),
          _SidebarItem(
            icon: Icons.receipt_long_rounded,
            label: 'Order History',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(height: 10),
          _SidebarItem(
            icon: Icons.person_rounded,
            label: 'Profile Settings',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),

          const Spacer(),

          // Logout Action at bottom
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.logout_rounded,
                color: Colors.redAccent, size: 22),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0EA5E9);
    const unselectedColor = Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: activeColor.withOpacity(0.2))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? activeColor : unselectedColor, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterBuddyNavBar extends StatelessWidget {
  const _WaterBuddyNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0EA5E9);
    const unselected = Color(0xFF94A3B8);
    const bg = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: bg,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      primaryColor: primary,
                      unselectedColor: unselected,
                      onTap: () => onTap(0),
                    ),
                    _NavItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'History',
                      isSelected: currentIndex == 1,
                      primaryColor: primary,
                      unselectedColor: unselected,
                      onTap: () => onTap(1),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isSelected: currentIndex == 2,
                      primaryColor: primary,
                      unselectedColor: unselected,
                      onTap: () => onTap(2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color primaryColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? primaryColor : unselectedColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
