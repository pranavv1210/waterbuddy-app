import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/operations_ui.dart';
import '../../orders/providers/order_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final orders = ref.watch(orderHistoryProvider);
    const appBg = Color(0xFFFFFBF3);

    if (user == null) {
      return const Scaffold(
        body: OpsEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Not signed in',
          message: 'Please sign in to view your WaterBuddy profile.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: appBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: OpsColors.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          OpsCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFE0F2FE),
                    backgroundImage: user.photoURL == null
                        ? null
                        : NetworkImage(user.photoURL!),
                    child: user.photoURL == null
                        ? const Icon(Icons.person_rounded,
                            size: 28, color: OpsColors.blue)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'WaterBuddy User',
                        style: const TextStyle(
                          color: OpsColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email ??
                            user.phoneNumber ??
                            'Contact not recorded',
                        style: TextStyle(
                          color: OpsColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          orders.when(
            data: (list) => OpsCard(
              child: _ProfileMetric(
                label: 'Orders placed',
                value: '${list.length}',
                icon: Icons.receipt_long_rounded,
              ),
            ),
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          _ProfileAction(
            icon: Icons.history_rounded,
            title: 'Order history',
            subtitle: 'View current and completed tanker bookings',
            onTap: () => context.go(RouteNames.orders),
          ),
          _ProfileAction(
            icon: Icons.payment_rounded,
            title: 'Payments',
            subtitle: 'Open payment records for your orders',
            onTap: () => context.go(RouteNames.payments),
          ),
          _ProfileAction(
            icon: Icons.support_agent_rounded,
            title: 'Support',
            subtitle: AppConstants.supportEmail,
            onTap: () {
              launchUrl(Uri(
                scheme: 'mailto',
                path: AppConstants.supportEmail,
                query: 'subject=WaterBuddy support',
              ));
            },
          ),
          _ProfileAction(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out of this device',
            destructive: true,
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              await ref.read(selectedRoleProvider.notifier).clear();
              if (context.mounted) context.go(RouteNames.roleSelection);
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: OpsColors.blue),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: OpsColors.ink,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: OpsColors.muted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? OpsColors.red : OpsColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OpsCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: destructive
                          ? color.withOpacity(0.72)
                          : OpsColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: OpsColors.muted),
          ],
        ),
      ),
    );
  }
}
