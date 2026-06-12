import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/session_actions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/operations_ui.dart';
import '../../../widgets/premium_ui.dart';
import '../../orders/providers/order_providers.dart';
import '../../../widgets/waterbuddy_toast.dart';
import '../../../widgets/waterbuddy_bottom_sheet.dart';
import '../../../widgets/loading_feedback_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final ordersAsync = ref.watch(orderHistoryProvider);
    final settings = ref.watch(systemSettingsProvider).valueOrNull;
    final supportEmail = settings?.supportEmail.isNotEmpty == true
        ? settings!.supportEmail
        : AppConstants.supportEmail;
    final supportSubtitle = settings?.supportNumber.isNotEmpty == true
        ? '${settings!.supportNumber} • $supportEmail'
        : supportEmail;
    const appBg = Color(0xFFF8FAFC); // Off-White instead of soft beige

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: OpsColors.ink),
          onPressed: () => context.go(RouteNames.home),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: OpsColors.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // 1. TOP PROFILE CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0095F6),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFE0F2FE),
                    backgroundImage: user.photoURL == null
                        ? null
                        : NetworkImage(user.photoURL!),
                    child: user.photoURL == null
                        ? const Icon(Icons.person_rounded,
                            size: 36, color: Color(0xFF0095F6))
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName ?? 'WaterBuddy User',
                              style: const TextStyle(
                                color: OpsColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              color: Colors.green, size: 18),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email ?? user.phoneNumber ?? 'No contact info',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0095F6).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Consumer Account',
                          style: TextStyle(
                            color: Color(0xFF0095F6),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. STATISTICS GRID (Replaced old receiving receipt count with modern visual metrics)
          const Text(
            'WaterBuddy Stats',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: OpsColors.ink,
            ),
          ),
          const SizedBox(height: 10),

          ordersAsync.when(
            data: (list) {
              final completed =
                  list.where((o) => o.status == 'DELIVERED').toList();
              final totalSpent =
                  completed.fold<num>(0, (acc, o) => acc + o.amount);
              final totalLitres =
                  completed.fold<num>(0, (acc, o) => acc + o.tankSize);

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _buildStatCard(
                    icon: Icons.local_shipping_rounded,
                    color: WbColors.blue,
                    value: completed.length.toDouble(),
                    label: 'Bookings Completed',
                    prefix: '',
                    suffix: '',
                  ),
                  _buildStatCard(
                    icon: Icons.payments_rounded,
                    color: WbColors.green,
                    value: totalSpent.toDouble(),
                    label: 'Total Spent',
                    prefix: '₹',
                    suffix: '',
                  ),
                  _buildStatCard(
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF38BDF8),
                    value: totalLitres.toDouble(),
                    label: 'Water Ordered',
                    prefix: '',
                    suffix: 'L',
                  ),
                  _buildStatCard(
                    icon: Icons.home_work_rounded,
                    color: const Color(0xFFA78BFA),
                    value: -1,
                    label: 'Standard Account',
                    staticText: 'Active',
                  ),
                ],
              );
            },
            loading: () => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: List.generate(
                4,
                (_) => const WbShimmer(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 20,
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // 3. SETTINGS ACTIONS
          const Text(
            'Account Preferences',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: OpsColors.ink,
            ),
          ),
          const SizedBox(height: 10),

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
            onTap: () => context.push(RouteNames.payments),
          ),
          _ProfileAction(
            icon: Icons.edit_rounded,
            title: 'Edit profile',
            subtitle: 'Manage your name and contact details',
            onTap: () => _showEditProfileBottomSheet(context, user),
          ),
          _ProfileAction(
            icon: Icons.support_agent_rounded,
            title: 'Support & Help',
            subtitle: supportSubtitle,
            onTap: () {
              launchUrl(Uri(
                scheme: 'mailto',
                path: supportEmail,
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
              await signOutToRoleSelection(context: context, ref: ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    double value = 0,
    String prefix = '',
    String suffix = '',
    String? staticText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              staticText != null
                  ? Text(
                      staticText,
                      style: const TextStyle(
                        color: WbColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : WbAnimatedCounter(
                      value: value,
                      prefix: prefix,
                      suffix: suffix,
                      style: const TextStyle(
                        color: WbColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: WbColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});
  final User user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  LoadingButtonState _saveState = LoadingButtonState.idle;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.user.displayName ?? 'WaterBuddy User');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saveState = LoadingButtonState.loading);
    try {
      await widget.user.updateDisplayName(name);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
        'name': name,
        'displayName': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _saveState = LoadingButtonState.success);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _saveState = LoadingButtonState.idle);
      if (mounted) {
        WaterBuddyToast.show(context, 'Unable to update profile: $e',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            autofocus: true,
            style: const TextStyle(
                color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Full name',
              labelStyle: const TextStyle(color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF0095F6), width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 24),
          LoadingFeedbackButton(
            onPressed: _saveProfile,
            label: 'Save Changes',
            loadingLabel: 'Saving Profile...',
            successLabel: 'Profile Saved!',
            buttonState: _saveState,
            backgroundColor: const Color(0xFF0095F6),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

Future<void> _showEditProfileBottomSheet(
    BuildContext context, User user) async {
  final updated = await showWaterBuddyBottomSheet<bool>(
    context: context,
    child: _EditProfileSheet(user: user),
  );
  if (updated == true && context.mounted) {
    WaterBuddyToast.show(context, 'Profile updated successfully!');
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
