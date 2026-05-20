import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/route_names.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  int get _currentIndex {
    if (location.startsWith(RouteNames.orders)) return 1;
    if (location.startsWith(RouteNames.profile)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RouteNames.home);
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: _WaterBuddyNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
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
          },
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
    const primary = Color(0xFF0F2B5B);
    const unselected = Color(0xFF94A3B8);
    const bg = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
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
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
