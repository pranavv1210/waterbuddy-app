import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../orders/providers/order_providers.dart';
import '../../../core/services/auth/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Please log in.'));
            }

            final orderCount = ordersAsync.when(
              data: (orders) => orders.where((o) => o.status == 'DELIVERED').length,
              loading: () => 0,
              error: (_, __) => 0,
            );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF102A43),
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Color(0xFF486581)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Settings coming soon!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildProfileHeader(user, orderCount),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _buildActionCard(
                          context,
                          icon: Icons.history_rounded,
                          title: 'Order History',
                          subtitle: 'View your past and current deliveries',
                          onTap: () => context.go(RouteNames.orders),
                        ),
                        const SizedBox(height: 16),
                        _buildActionCard(
                          context,
                          icon: Icons.support_agent_rounded,
                          title: 'Help & Support',
                          subtitle: 'Get help with your orders',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Support section coming soon!')),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildActionCard(
                          context,
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          subtitle: 'Sign out of your account',
                          isDestructive: true,
                          onTap: () async {
                            final authService = ref.read(authServiceProvider);
                            await authService.signOut();
                            if (context.mounted) {
                              context.go(RouteNames.splash);
                            }
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user, int orderCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B5B), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
              image: user.photoURL != null
                  ? DecorationImage(
                      image: NetworkImage(user.photoURL!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.photoURL == null
                ? const Center(
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName ?? 'Customer',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email ?? user.phoneNumber ?? 'No Contact Info',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem(orderCount.toString(), 'Orders'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildStatItem('1', 'Locations'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFE53E3E) : const Color(0xFF102A43);
    final bgColor = isDestructive ? const Color(0xFFFFF5F5) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF829AB1),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFFBCCCDC).withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
