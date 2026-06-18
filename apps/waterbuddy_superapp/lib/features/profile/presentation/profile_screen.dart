import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/session_actions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/loading_feedback_button.dart';
import '../../../widgets/operations_ui.dart';
import '../../../widgets/premium_ui.dart';
import '../../../widgets/waterbuddy_bottom_sheet.dart';
import '../../../widgets/waterbuddy_toast.dart';
import '../../orders/providers/order_providers.dart';

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

    if (user == null) {
      return const Scaffold(
        body: OpsEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Not signed in',
          message: 'Please sign in to view your WaterBuddy profile.',
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: WbColors.surface,
        body: Stack(
          children: [
            const AbstractWaterBackground(),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go(RouteNames.home),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: WbColors.line),
                                boxShadow: [
                                  BoxShadow(
                                    color: WbColors.ink.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: WbColors.ink,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Profile',
                                  style: TextStyle(
                                    color: WbColors.ink,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Account details & settings',
                                  style: TextStyle(
                                    color: WbColors.muted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Profile Card
                        _ProfileHeroCard(user: user)
                            .animate(delay: 80.ms)
                            .fadeIn()
                            .slideY(begin: 0.06),

                        const SizedBox(height: 20),

                        // Stats
                        const Text(
                          'Activity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: WbColors.ink,
                            letterSpacing: -0.2,
                          ),
                        ).animate(delay: 140.ms).fadeIn(),

                        const SizedBox(height: 10),

                        ordersAsync.when(
                          data: (list) {
                            final completed = list
                                .where((o) => o.status == 'DELIVERED')
                                .toList();
                            final totalSpent = completed.fold<num>(
                                0, (acc, o) => acc + o.amount);
                            final totalLitres = completed.fold<num>(
                                0, (acc, o) => acc + o.tankSize);

                            return _StatsGrid(
                              completedCount: completed.length,
                              totalSpent: totalSpent.toDouble(),
                              totalLitres: totalLitres.toDouble(),
                            ).animate(delay: 180.ms).fadeIn();
                          },
                          loading: () => _StatsGridLoading()
                              .animate(delay: 180.ms)
                              .fadeIn(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 24),

                        // Settings
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: WbColors.ink,
                            letterSpacing: -0.2,
                          ),
                        ).animate(delay: 220.ms).fadeIn(),

                        const SizedBox(height: 10),

                        ...{
                          (Icons.history_rounded, 'Order History',
                              'View current and completed tanker bookings',
                              WbColors.blue,
                              false): () => context.go(RouteNames.orders),
                          (Icons.payment_rounded, 'Payments',
                              'Open payment records for your orders',
                              WbColors.green,
                              false): () =>
                              context.push(RouteNames.payments),
                          (Icons.edit_rounded, 'Edit Profile',
                              'Manage your name and contact details',
                              const Color(0xFF8B5CF6),
                              false): () =>
                              _showEditProfileBottomSheet(context, user),
                          (Icons.support_agent_rounded, 'Support & Help',
                              supportSubtitle,
                              WbColors.amber,
                              false): () {
                            launchUrl(Uri(
                              scheme: 'mailto',
                              path: supportEmail,
                              query: 'subject=WaterBuddy support',
                            ));
                          },
                        }
                            .entries
                            .toList()
                            .asMap()
                            .entries
                            .map((e) {
                          final i = e.key;
                          final action = e.value;
                          final meta = action.key;
                          return _ProfileAction(
                            icon: meta.$1,
                            title: meta.$2,
                            subtitle: meta.$3,
                            accentColor: meta.$4,
                            destructive: meta.$5,
                            onTap: action.value,
                          )
                              .animate(delay: (260 + i * 50).ms)
                              .fadeIn()
                              .slideY(begin: 0.06);
                        }),

                        _ProfileAction(
                          icon: Icons.logout_rounded,
                          title: 'Sign Out',
                          subtitle: 'Sign out from this device',
                          accentColor: WbColors.red,
                          destructive: true,
                          onTap: () async {
                            await signOutToRoleSelection(
                                context: context, ref: ref);
                          },
                        ).animate(delay: 460.ms).fadeIn().slideY(begin: 0.06),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 28,
      opacity: 0.92,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0369A1)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: WbColors.blue.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: user.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          user.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: WbColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Info
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
                          color: WbColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? user.phoneNumber ?? 'No contact info',
                  style: const TextStyle(
                    color: WbColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        WbColors.blue.withValues(alpha: 0.12),
                        WbColors.deepBlue.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: WbColors.blue.withValues(alpha: 0.20)),
                  ),
                  child: const Text(
                    'Consumer Account',
                    style: TextStyle(
                      color: WbColors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.completedCount,
    required this.totalSpent,
    required this.totalLitres,
  });

  final int completedCount;
  final double totalSpent;
  final double totalLitres;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_shipping_rounded,
            color: WbColors.blue,
            value: completedCount.toDouble(),
            label: 'Deliveries',
            suffix: '',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.payments_rounded,
            color: WbColors.green,
            value: totalSpent,
            label: 'Total Spent',
            prefix: '₹',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.water_drop_rounded,
            color: WbColors.blue,
            value: totalLitres,
            label: 'Litres',
            suffix: 'L',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.prefix = '',
    this.suffix = '',
  });

  final IconData icon;
  final Color color;
  final double value;
  final String label;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 20,
      opacity: 0.90,
      padding: const EdgeInsets.all(14),
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          WbAnimatedCounter(
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
    );
  }
}

class _StatsGridLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
            child: const WbShimmer(
                width: double.infinity, height: 90, borderRadius: 20),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileAction extends StatefulWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accentColor,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accentColor;
  final bool destructive;

  @override
  State<_ProfileAction> createState() => _ProfileActionState();
}

class _ProfileActionState extends State<_ProfileAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.destructive ? WbColors.red : widget.accentColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassPanel(
            radius: 20,
            opacity: 0.88,
            shadow: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.icon, color: iconColor, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.destructive ? WbColors.red : WbColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WbColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: WbColors.muted.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Sheet
// ─────────────────────────────────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: WbColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Update your display name',
                      style: TextStyle(
                        color: WbColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: WbColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: WbColors.line),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: WbColors.muted, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          WbPremiumTextField(
            controller: _nameController,
            label: 'Full name',
            icon: Icons.person_rounded,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          LoadingFeedbackButton(
            onPressed: _saveProfile,
            label: 'Save Changes',
            loadingLabel: 'Saving...',
            successLabel: 'Saved!',
            buttonState: _saveState,
            backgroundColor: WbColors.blue,
          ),
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
