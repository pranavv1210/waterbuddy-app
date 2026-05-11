import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/providers/home_providers.dart';
import '../../../routes/route_names.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(sellerAvailabilityProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 24, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 24,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOnline ? Icons.online_prediction : Icons.offline_bolt_outlined,
                    color: isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'You are Online' : 'You are Offline',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        isOnline
                            ? 'Visible to customers'
                            : 'Not receiving requests',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isOnline,
                  activeColor: const Color(0xFF10B981),
                  activeTrackColor: const Color(0xFF10B981).withOpacity(0.2),
                  onChanged: (value) {
                    ref.read(sellerAvailabilityProvider.notifier).setOnline(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          _ProfileMenuItem(
            icon: Icons.person_outline,
            label: 'Business Details',
            onTap: () {
              context.push(RouteNames.editProfile);
            },
          ),
          _ProfileMenuItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payout Settings',
            onTap: () {},
          ),
          _ProfileMenuItem(
            icon: Icons.history,
            label: 'Order History',
            onTap: () {},
          ),
          _ProfileMenuItem(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () {},
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFFEE2E2)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF1F2937),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD1D5DB)),
    );
  }
}
