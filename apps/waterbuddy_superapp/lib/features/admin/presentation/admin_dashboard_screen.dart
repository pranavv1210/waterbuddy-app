import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/operations_ui.dart';

String _approvalStatus(Map<String, dynamic> data) {
  final raw = (data['verificationStatus'] ??
          data['kycStatus'] ??
          data['approvalStatus'] ??
          'pending')
      .toString()
      .trim()
      .toLowerCase();
  if (raw.isEmpty || raw == 'submitted' || raw == 'review') return 'pending';
  if (raw == 'verified') return 'approved';
  return raw;
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _tab = 0;

  static const _tabs = [
    OpsTab(label: 'Overview', icon: Icons.dashboard_rounded),
    OpsTab(label: 'Approvals', icon: Icons.verified_user_rounded),
    OpsTab(label: 'Orders', icon: Icons.radar_rounded),
    OpsTab(label: 'Users', icon: Icons.people_alt_rounded),
    OpsTab(label: 'Payments', icon: Icons.payments_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<bool>(
      future: ref.read(authServiceProvider).isAuthorizedAdmin(user),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.data != true) {
          return Scaffold(
            backgroundColor: OpsColors.surface,
            body: OpsEmptyState(
              icon: Icons.gpp_bad_rounded,
              title: 'Access blocked',
              message:
                  'This account is not authorized for the WaterBuddy admin console.',
              action: FilledButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go(RouteNames.roleSelection);
                },
                child: const Text('Sign out'),
              ),
            ),
          );
        }

        return OpsScaffold(
          title: 'Admin Control',
          subtitle: user.email ?? 'Operations console',
          accent: OpsColors.green,
          tabs: _tabs,
          activeIndex: _tab,
          onTabChanged: (index) => setState(() => _tab = index),
          actions: [
            _AdminProfileMenu(
              name: user.displayName ?? 'Admin',
              email: user.email ?? 'WaterBuddy admin',
            ),
          ],
          body: IndexedStack(
            index: _tab,
            children: const [
              _AdminOverview(),
              _ApprovalsView(),
              _AdminOrdersView(),
              _UsersView(),
              _PaymentsView(),
            ],
          ),
        );
      },
    );
  }
}

class _AdminProfileMenu extends ConsumerWidget {
  const _AdminProfileMenu({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Admin profile and settings',
      offset: const Offset(0, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
          case 'security':
          case 'settings':
          case 'support':
            _showAdminSheet(context, value);
            break;
          case 'logout':
            await ref.read(authServiceProvider).signOut();
            await ref.read(selectedRoleProvider.notifier).clear();
            if (context.mounted) context.go(RouteNames.roleSelection);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 240,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: OpsColors.green.withValues(alpha: 0.12),
                  child: Text(
                    name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      color: OpsColors.green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: OpsColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: OpsColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.admin_panel_settings_rounded),
            title: Text('Admin profile'),
          ),
        ),
        const PopupMenuItem(
          value: 'security',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.shield_rounded),
            title: Text('Security access'),
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.settings_rounded),
            title: Text('Console settings'),
          ),
        ),
        const PopupMenuItem(
          value: 'support',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.support_agent_rounded),
            title: Text('Support'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.logout_rounded, color: OpsColors.red),
            title: Text('Logout', style: TextStyle(color: OpsColors.red)),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: CircleAvatar(
          backgroundColor: OpsColors.green.withValues(alpha: 0.12),
          child: Text(
            name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase(),
            style: const TextStyle(
              color: OpsColors.green,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminSheet(BuildContext context, String section) {
    final title = switch (section) {
      'security' => 'Security access',
      'settings' => 'Console settings',
      'support' => 'Support',
      _ => 'Admin profile',
    };
    final message = switch (section) {
      'security' =>
        'Admin access is controlled by the allowlist and admins collection.',
      'settings' =>
        'Operational settings for approvals, payments, users, and alerts belong here.',
      'support' =>
        'For operational issues, use waterbuddyapp.wb@gmail.com with the affected user or order ID.',
      _ =>
        'This admin profile controls seller approvals, driver approvals, user suspension, order monitoring, and payments.',
    };

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: OpsColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              OpsCard(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: OpsColors.muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminOverview extends ConsumerWidget {
  const _AdminOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    final sellers = ref.watch(sellersProvider);
    final drivers = ref.watch(driversProvider);
    final orders = ref.watch(allOrdersProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _AdminHeader(
          title: 'Live operations',
          subtitle: 'Counts come directly from Firestore collections.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = _adminCardWidth(constraints.maxWidth);
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: width,
                  child: _CountMetric(
                    title: 'Users',
                    icon: Icons.people_alt_rounded,
                    async: users,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _CountMetric(
                    title: 'Sellers',
                    icon: Icons.storefront_rounded,
                    async: sellers,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _CountMetric(
                    title: 'Drivers',
                    icon: Icons.local_shipping_rounded,
                    async: drivers,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _CountMetric(
                    title: 'Orders',
                    icon: Icons.water_drop_rounded,
                    async: orders,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        orders.when(
          data: (snapshot) {
            final active = snapshot.docs.where((doc) {
              final status = (doc.data()['status'] ?? '').toString();
              return status != 'DELIVERED' && status != 'CANCELLED';
            }).toList();
            if (active.isEmpty) {
              return const OpsCard(
                child: Text(
                  'No active deliveries at the moment.',
                  style: TextStyle(
                      color: OpsColors.muted, fontWeight: FontWeight.w600),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AdminHeader(
                  title: 'Active delivery monitor',
                  subtitle: 'Current non-final orders.',
                ),
                for (final doc in active.take(8))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderAdminCard(doc: doc),
                  ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (error, _) => Text(error.toString()),
        ),
      ],
    );
  }
}

double _adminCardWidth(double maxWidth) {
  if (maxWidth < 720) return maxWidth;
  return (maxWidth - 16) / 2;
}

class _CountMetric extends StatelessWidget {
  const _CountMetric({
    required this.title,
    required this.icon,
    required this.async,
  });

  final String title;
  final IconData icon;
  final AsyncValue<QuerySnapshot<Map<String, dynamic>>> async;

  @override
  Widget build(BuildContext context) {
    final count = async.value?.docs.length;
    return OpsCard(
      child: Row(
        children: [
          Icon(icon, color: OpsColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == null ? '-' : '$count',
                  style: const TextStyle(
                    color: OpsColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OpsColors.muted,
                    fontWeight: FontWeight.w700,
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

class _ApprovalsView extends ConsumerWidget {
  const _ApprovalsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellers = ref.watch(sellersProvider);
    final drivers = ref.watch(driversProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _AdminHeader(
          title: 'Partner approvals',
          subtitle: 'Approve, reject, or suspend real partner records.',
        ),
        _ApprovalSection(
          title: 'Tanker owners',
          collection: 'sellers',
          async: sellers,
          primaryNameKeys: const ['ownerName', 'fullName', 'businessName'],
        ),
        const SizedBox(height: 24),
        _ApprovalSection(
          title: 'Drivers',
          collection: 'drivers',
          async: drivers,
          primaryNameKeys: const ['driverName', 'fullName'],
        ),
      ],
    );
  }
}

class _ApprovalSection extends ConsumerWidget {
  const _ApprovalSection({
    required this.title,
    required this.collection,
    required this.async,
    required this.primaryNameKeys,
  });

  final String title;
  final String collection;
  final AsyncValue<QuerySnapshot<Map<String, dynamic>>> async;
  final List<String> primaryNameKeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      data: (snapshot) {
        final pending = snapshot.docs.where((doc) {
          final status = _approvalStatus(doc.data());
          return status == 'pending' || status == 'under_review';
        }).toList();

        if (pending.isEmpty) {
          return OpsCard(
            child: Text(
              '$title: no pending approvals.',
              style: const TextStyle(
                color: OpsColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: OpsColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (final doc in pending)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ApprovalCard(
                  collection: collection,
                  doc: doc,
                  name: _nameFrom(doc.data(), primaryNameKeys),
                ),
              ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (error, _) => Text(error.toString()),
    );
  }

  static String _nameFrom(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return 'Unnamed partner';
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.collection,
    required this.doc,
    required this.name,
  });

  final String collection;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String name;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final contact = _contactFrom(data, doc.id);
    final meta = _approvalMeta(collection, data);

    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: OpsColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const OpsStatusPill(label: 'PENDING', color: OpsColors.amber),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contact,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: OpsColors.muted),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meta,
              style: const TextStyle(
                color: OpsColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: () => _setStatus(collection, doc, 'approved'),
                child: const Text('Approve'),
              ),
              OutlinedButton(
                onPressed: () => _setStatus(collection, doc, 'rejected'),
                child: const Text('Reject'),
              ),
              OutlinedButton(
                onPressed: () => _setStatus(collection, doc, 'suspended'),
                child: const Text('Suspend'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _setStatus(
    String collection,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
  ) async {
    final data = doc.data();
    final uid = (data['uid'] ?? doc.id).toString();
    final role = collection == 'drivers' ? 'driver' : 'seller';
    final now = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance.collection(collection).doc(doc.id).set({
      'verificationStatus': status,
      'kycStatus': status,
      'approvedAt': status == 'approved' ? now : null,
      'rejectedAt': status == 'rejected' ? now : null,
      'suspendedAt': status == 'suspended' ? now : null,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'role': role,
      'isVerified': status == 'approved',
      'isBlocked': status == 'suspended',
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  static String _contactFrom(Map<String, dynamic> data, String fallback) {
    final email = data['email']?.toString().trim();
    final phone = (data['phoneNumber'] ?? data['phone'])?.toString().trim();
    if (email != null &&
        email.isNotEmpty &&
        phone != null &&
        phone.isNotEmpty) {
      return '$email  |  $phone';
    }
    if (email != null && email.isNotEmpty) return email;
    if (phone != null && phone.isNotEmpty) return phone;
    return fallback;
  }

  static String _approvalMeta(String collection, Map<String, dynamic> data) {
    if (collection == 'sellers') {
      final business = data['businessName']?.toString().trim();
      final capacity = data['tankerCapacity']?.toString().trim();
      final vehicle = data['vehicleNumber']?.toString().trim();
      return [
        if (business != null && business.isNotEmpty) business,
        if (capacity != null && capacity.isNotEmpty) '${capacity}L tanker',
        if (vehicle != null && vehicle.isNotEmpty) vehicle,
      ].join('  |  ');
    }

    final license = (data['driverLicenseNumber'] ?? data['licenseNumber'])
        ?.toString()
        .trim();
    final address = data['address']?.toString().trim();
    return [
      if (license != null && license.isNotEmpty) 'DL $license',
      if (address != null && address.isNotEmpty) address,
    ].join('  |  ');
  }
}

class _AdminOrdersView extends ConsumerWidget {
  const _AdminOrdersView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(allOrdersProvider);
    return orders.when(
      data: (snapshot) {
        if (snapshot.docs.isEmpty) {
          return const OpsEmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No orders',
            message:
                'Water tanker bookings will appear here once customers place orders.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _OrderAdminCard(doc: snapshot.docs[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _OrderAdminCard extends StatelessWidget {
  const _OrderAdminCard({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final status = (data['status'] ?? 'UNKNOWN').toString();
    final location = Map<String, dynamic>.from(data['location'] as Map? ?? {});
    return OpsCard(
      child: Row(
        children: [
          const Icon(Icons.water_drop_rounded, color: OpsColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['tankSize'] ?? '-'}L order',
                  style: const TextStyle(
                    color: OpsColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  (location['address'] ?? doc.id).toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: OpsColors.muted),
                ),
              ],
            ),
          ),
          OpsStatusPill(
            label: formatOrderStatus(status),
            color: orderStatusColor(status),
          ),
        ],
      ),
    );
  }
}

class _UsersView extends ConsumerWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    return users.when(
      data: (snapshot) {
        if (snapshot.docs.isEmpty) {
          return const OpsEmptyState(
            icon: Icons.people_alt_outlined,
            title: 'No users',
            message:
                'Registered consumer, seller, driver, and admin profiles will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _UserAdminCard(doc: snapshot.docs[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _UserAdminCard extends StatelessWidget {
  const _UserAdminCard({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final blocked = data['isBlocked'] as bool? ?? false;
    final name = (data['fullName'] ?? data['displayName'] ?? doc.id).toString();
    final role = (data['role'] ?? 'consumer').toString();
    final contact =
        (data['email'] ?? data['phoneNumber'] ?? 'No contact').toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final identity = Row(
          children: [
            CircleAvatar(
              backgroundColor: OpsColors.green.withValues(alpha: 0.1),
              child: const Icon(Icons.person_rounded, color: OpsColors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OpsColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '$role  |  $contact',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: OpsColors.muted),
                  ),
                ],
              ),
            ),
          ],
        );

        final action = OutlinedButton(
          onPressed: () =>
              FirebaseFirestore.instance.collection('users').doc(doc.id).set({
            'isBlocked': !blocked,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
          child: Text(blocked ? 'Activate' : 'Suspend'),
        );

        return OpsCard(
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: 12),
                    action,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 12),
                    action,
                  ],
                ),
        );
      },
    );
  }
}

class _PaymentsView extends ConsumerWidget {
  const _PaymentsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(allOrdersProvider);
    return orders.when(
      data: (snapshot) {
        final paid = snapshot.docs.where((doc) {
          return (doc.data()['paymentStatus'] ?? '').toString() == 'PAID';
        }).length;
        final pending = snapshot.docs.where((doc) {
          return (doc.data()['paymentStatus'] ?? 'PENDING').toString() ==
              'PENDING';
        }).length;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _AdminHeader(
              title: 'Payments',
              subtitle: 'Payment status from order records.',
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = _adminCardWidth(constraints.maxWidth);
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: width,
                      child: OpsCard(
                        child: _PaymentMetric(
                          label: 'Paid orders',
                          value: '$paid',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: OpsCard(
                        child: _PaymentMetric(
                          label: 'Pending orders',
                          value: '$pending',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _PaymentMetric extends StatelessWidget {
  const _PaymentMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: OpsColors.ink,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: OpsColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: OpsColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: OpsColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
