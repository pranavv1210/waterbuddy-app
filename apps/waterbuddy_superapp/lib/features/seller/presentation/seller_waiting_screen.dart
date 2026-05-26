import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session_actions.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/operations_ui.dart';

class SellerWaitingScreen extends ConsumerWidget {
  const SellerWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final exists = snapshot.data?.exists ?? false;
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final status = _normalStatus(data['verificationStatus']);

        if (snapshot.hasData && !exists) {
          _ensurePendingSellerDoc(user.uid, user.email, user.displayName);
        }

        if (status == 'approved') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(RouteNames.sellerDashboard);
          });
        }

        return Scaffold(
          backgroundColor: OpsColors.surface,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: OpsColors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: OpsColors.green.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: OpsColors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WaterBuddy Partner',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: OpsColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Tanker owner verification',
                            style: TextStyle(
                              color: OpsColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      onPressed: () async {
                        await signOutToRoleSelection(
                            context: context, ref: ref);
                      },
                      icon: const Icon(Icons.logout_rounded,
                          color: OpsColors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                OpsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _statusTitle(status),
                              style: const TextStyle(
                                color: OpsColors.ink,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          OpsStatusPill(
                            label: status.toUpperCase(),
                            color: _statusColor(status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage(status),
                        style: const TextStyle(
                          color: OpsColors.muted,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: status == 'approved'
                            ? () => context.go(RouteNames.sellerDashboard)
                            : () => ref
                                .invalidate(sellerVerificationStatusProvider),
                        icon: Icon(status == 'approved'
                            ? Icons.dashboard_rounded
                            : Icons.refresh_rounded),
                        label: Text(status == 'approved'
                            ? 'Open Dashboard'
                            : 'Refresh Status'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OpsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Submitted business details',
                        style: TextStyle(
                          color: OpsColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(
                        icon: Icons.storefront_rounded,
                        label: 'Business',
                        value: _first(
                            data,
                            const [
                              'businessName',
                              'companyName',
                              'ownerName',
                              'fullName',
                            ],
                            fallback: user.displayName ?? 'Tanker owner'),
                      ),
                      _DetailRow(
                        icon: Icons.person_rounded,
                        label: 'Owner',
                        value: _first(data, const ['ownerName', 'fullName'],
                            fallback: user.displayName ?? 'Not added'),
                      ),
                      _DetailRow(
                        icon: Icons.call_rounded,
                        label: 'Mobile',
                        value: _first(data, const ['phoneNumber', 'phone'],
                            fallback: user.phoneNumber ?? 'Not added'),
                      ),
                      _DetailRow(
                        icon: Icons.mail_rounded,
                        label: 'Email',
                        value: _first(data, const ['email'],
                            fallback: user.email ?? 'Not added'),
                      ),
                      _DetailRow(
                        icon: Icons.local_shipping_rounded,
                        label: 'Tanker',
                        value: '${_first(data, const [
                                  'tankerCapacity'
                                ], fallback: '-')} L'
                            '  |  ${_first(data, const [
                                  'vehicleNumber'
                                ], fallback: 'Vehicle pending')}',
                      ),
                      _DetailRow(
                        icon: Icons.location_on_rounded,
                        label: 'Address',
                        value: _first(data, const ['address'],
                            fallback: 'Address pending'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OpsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Approval checklist',
                        style: TextStyle(
                          color: OpsColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 14),
                      _ReviewStep(
                        title: 'Profile submitted',
                        subtitle: 'Your owner and tanker details are saved.',
                        done: true,
                      ),
                      _ReviewStep(
                        title: 'Admin review',
                        subtitle:
                            'WaterBuddy verifies documents and tanker details.',
                        done: false,
                      ),
                      _ReviewStep(
                        title: 'Dashboard unlocked',
                        subtitle:
                            'Orders, drivers, fleet and earnings open after approval.',
                        done: false,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _ensurePendingSellerDoc(
    String uid,
    String? email,
    String? displayName,
  ) async {
    await FirebaseFirestore.instance.collection('sellers').doc(uid).set({
      'uid': uid,
      'ownerName': displayName ?? 'Tanker owner',
      'email': email,
      'verificationStatus': 'pending',
      'isOnline': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _normalStatus(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    if (raw == null || raw.isEmpty || raw == 'submitted') return 'pending';
    if (raw == 'verified') return 'approved';
    return raw;
  }

  static String _statusTitle(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Verification rejected';
      case 'suspended':
        return 'Account suspended';
      default:
        return 'Verification in progress';
    }
  }

  static String _statusMessage(String status) {
    switch (status) {
      case 'approved':
        return 'Your tanker owner dashboard is ready. Opening it now.';
      case 'rejected':
        return 'Your submission needs correction. Contact WaterBuddy support before resubmitting.';
      case 'suspended':
        return 'This partner account is currently blocked from operations.';
      default:
        return 'Admin approval is required before orders, fleet controls, driver assignment, and earnings become visible.';
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return OpsColors.green;
      case 'rejected':
      case 'suspended':
        return OpsColors.red;
      default:
        return OpsColors.amber;
    }
  }

  static String _first(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: OpsColors.blue, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: OpsColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: OpsColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.title,
    required this.subtitle,
    required this.done,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? OpsColors.green : OpsColors.line;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? OpsColors.green : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.hourglass_top_rounded,
                color: done ? Colors.white : OpsColors.muted,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: OpsColors.line,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: OpsColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: OpsColors.muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
