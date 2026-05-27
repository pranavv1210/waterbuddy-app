import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session_actions.dart';
import '../../../models/tank_category.dart';
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
    OpsTab(label: 'Dashboard', icon: Icons.dashboard_rounded),
    OpsTab(label: 'Orders', icon: Icons.radar_rounded),
    OpsTab(label: 'Tank Categories', icon: Icons.water_drop_rounded),
    OpsTab(label: 'Pricing', icon: Icons.currency_rupee_rounded),
    OpsTab(label: 'Approvals', icon: Icons.verified_user_rounded),
    OpsTab(label: 'Drivers', icon: Icons.badge_rounded),
    OpsTab(label: 'Tank Owners', icon: Icons.local_shipping_rounded),
    OpsTab(label: 'Consumers', icon: Icons.people_alt_rounded),
    OpsTab(label: 'Payments', icon: Icons.payments_rounded),
    OpsTab(label: 'Notifications', icon: Icons.campaign_rounded),
    OpsTab(label: 'Support', icon: Icons.support_agent_rounded),
    OpsTab(label: 'Settings', icon: Icons.tune_rounded),
    OpsTab(label: 'Profile', icon: Icons.admin_panel_settings_rounded),
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
                  await signOutToRoleSelection(context: context, ref: ref);
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
          actions: const [],
          body: IndexedStack(
            index: _tab,
            children: const [
              _AdminOverview(),
              _AdminOrdersView(),
              _TankCategoriesView(),
              _PricingView(),
              _ApprovalsView(),
              _RoleCollectionView(
                title: 'Drivers',
                collection: 'drivers',
                icon: Icons.badge_rounded,
                roleLabel: 'driver',
              ),
              _RoleCollectionView(
                title: 'Tank Owners',
                collection: 'sellers',
                icon: Icons.local_shipping_rounded,
                roleLabel: 'seller',
              ),
              _RoleCollectionView(
                title: 'Consumers',
                collection: 'users',
                icon: Icons.person_rounded,
                roleLabel: 'consumer',
                roleFilter: 'consumer',
              ),
              _PaymentsView(),
              _NotificationsView(),
              _SupportView(),
              _AdminSettingsView(),
              _AdminProfileView(),
            ],
          ),
        );
      },
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

class _TankCategoriesView extends ConsumerWidget {
  const _TankCategoriesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(tankCategoriesProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AdminHeader(
          title: 'Tank category control',
          subtitle:
              'Add, edit, disable, or delete bookable tanker categories from Firestore.',
          action: FilledButton.icon(
            onPressed: () => _showTankCategoryForm(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add tank'),
          ),
        ),
        categories.when(
          data: (items) {
            if (items.isEmpty) {
              return OpsEmptyState(
                icon: Icons.water_drop_outlined,
                title: 'No tank categories configured',
                message:
                    'Create the first tank category before customers can book water.',
                action: FilledButton.icon(
                  onPressed: () => _showTankCategoryForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add tank category'),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = _adminCardWidth(constraints.maxWidth);
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final category in items)
                      SizedBox(
                        width: width,
                        child: _TankCategoryAdminCard(category: category),
                      ),
                  ],
                );
              },
            );
          },
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (error, _) => Text(error.toString()),
        ),
      ],
    );
  }
}

class _TankCategoryAdminCard extends StatelessWidget {
  const _TankCategoryAdminCard({required this.category});

  final TankCategory category;

  @override
  Widget build(BuildContext context) {
    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_tankIcon(category.iconKey), color: OpsColors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OpsColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OpsStatusPill(
                label: category.active ? 'ACTIVE' : 'DISABLED',
                color: category.active ? OpsColors.green : OpsColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ConfigLine(label: 'Litres', value: '${category.litres}L'),
          _ConfigLine(label: 'Base price', value: 'Rs ${category.basePrice}'),
          _ConfigLine(
            label: 'Surge multiplier',
            value: '${category.surgeMultiplier}x',
          ),
          _ConfigLine(
            label: 'ETA',
            value: category.estimatedDeliveryTime,
          ),
          _ConfigLine(
            label: 'Radius',
            value: '${category.serviceRadius} km',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: () =>
                    _showTankCategoryForm(context, category: category),
                child: const Text('Edit'),
              ),
              OutlinedButton(
                onPressed: () => _toggleCategory(category),
                child: Text(category.active ? 'Disable' : 'Enable'),
              ),
              OutlinedButton(
                onPressed: () => _deleteCategory(context, category),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _tankIcon(String key) {
    return switch (key) {
      'opacity' || 'drop' => Icons.opacity_rounded,
      'waves' => Icons.waves_rounded,
      'truck' => Icons.local_shipping_rounded,
      _ => Icons.water_drop_rounded,
    };
  }

  static Future<void> _toggleCategory(TankCategory category) {
    return FirebaseFirestore.instance
        .collection('tank_categories')
        .doc(category.id)
        .set({
      'active': !category.active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> _deleteCategory(
    BuildContext context,
    TankCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tank category?'),
        content: Text(
          '${category.displayName} will stop appearing for customers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseFirestore.instance
        .collection('tank_categories')
        .doc(category.id)
        .delete();
  }
}

Future<void> _showTankCategoryForm(
  BuildContext context, {
  TankCategory? category,
}) async {
  final id = TextEditingController(text: category?.id ?? '');
  final name = TextEditingController(text: category?.displayName ?? '');
  final litres = TextEditingController(text: category?.litres.toString() ?? '');
  final basePrice =
      TextEditingController(text: category?.basePrice.toString() ?? '');
  final surge =
      TextEditingController(text: category?.surgeMultiplier.toString() ?? '1');
  final eta =
      TextEditingController(text: category?.estimatedDeliveryTime ?? '');
  final icon = TextEditingController(text: category?.iconKey ?? 'water_drop');
  final order =
      TextEditingController(text: category?.displayOrder.toString() ?? '1');
  final radius =
      TextEditingController(text: category?.serviceRadius.toString() ?? '5');
  final night =
      TextEditingController(text: category?.nightCharge.toString() ?? '0');
  final extra = TextEditingController(
      text: category?.extraDistanceCharge.toString() ?? '0');
  final description = TextEditingController(text: category?.description ?? '');
  var active = category?.active ?? true;
  var express = category?.expressAvailable ?? true;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      category == null
                          ? 'Add tank category'
                          : 'Edit tank category',
                      style: const TextStyle(
                        color: OpsColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AdminTextField(
                      controller: id,
                      label: 'Tank ID',
                      enabled: category == null,
                    ),
                    _AdminTextField(controller: name, label: 'Display name'),
                    _AdminTextField(
                      controller: litres,
                      label: 'Litres',
                      keyboardType: TextInputType.number,
                    ),
                    _AdminTextField(
                      controller: basePrice,
                      label: 'Base price',
                      keyboardType: TextInputType.number,
                    ),
                    _AdminTextField(
                      controller: surge,
                      label: 'Surge multiplier',
                      keyboardType: TextInputType.number,
                    ),
                    _AdminTextField(
                      controller: eta,
                      label: 'Estimated delivery time',
                    ),
                    _AdminTextField(
                      controller: icon,
                      label: 'Icon key',
                    ),
                    _AdminTextField(
                      controller: order,
                      label: 'Display order',
                      keyboardType: TextInputType.number,
                    ),
                    _AdminTextField(
                      controller: radius,
                      label: 'Service radius km',
                      keyboardType: TextInputType.number,
                    ),
                    _AdminTextField(
                      controller: night,
                      label: 'Night charge',
                      keyboardType: TextInputType.number,
                    ),
                    _AdminTextField(
                      controller: extra,
                      label: 'Extra distance charge',
                      keyboardType: TextInputType.number,
                    ),
                    _AdminTextField(
                      controller: description,
                      label: 'Description',
                      maxLines: 2,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: active,
                      title: const Text('Active for booking'),
                      onChanged: (value) => setSheetState(() => active = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: express,
                      title: const Text('Express available'),
                      onChanged: (value) =>
                          setSheetState(() => express = value),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        final tankId = id.text.trim();
                        if (tankId.isEmpty || name.text.trim().isEmpty) return;
                        await FirebaseFirestore.instance
                            .collection('tank_categories')
                            .doc(tankId)
                            .set({
                          'displayName': name.text.trim(),
                          'litres': int.tryParse(litres.text.trim()) ?? 0,
                          'basePrice': num.tryParse(basePrice.text.trim()) ?? 0,
                          'surgeMultiplier':
                              double.tryParse(surge.text.trim()) ?? 1,
                          'estimatedDeliveryTime': eta.text.trim(),
                          'iconKey': icon.text.trim(),
                          'active': active,
                          'displayOrder':
                              int.tryParse(order.text.trim()) ?? 999,
                          'serviceRadius':
                              double.tryParse(radius.text.trim()) ?? 5,
                          'expressAvailable': express,
                          'nightCharge': num.tryParse(night.text.trim()) ?? 0,
                          'extraDistanceCharge':
                              num.tryParse(extra.text.trim()) ?? 0,
                          'description': description.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                          if (category == null)
                            'createdAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Save category'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  for (final controller in [
    id,
    name,
    litres,
    basePrice,
    surge,
    eta,
    icon,
    order,
    radius,
    night,
    extra,
    description,
  ]) {
    controller.dispose();
  }
}

class _PricingView extends ConsumerWidget {
  const _PricingView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(platformConfigProvider);
    return config.when(
      data: (snapshot) => _PlatformConfigEditor(
        title: 'Pricing and payout rules',
        subtitle:
            'Control surge, cancellation charges, commission, and payout percentages.',
        fields: const [
          _ConfigFieldSpec('surgeEnabled', 'Surge pricing enabled', 'bool'),
          _ConfigFieldSpec('peakHourMultiplier', 'Peak hour multiplier', 'num'),
          _ConfigFieldSpec(
              'emergencyMultiplier', 'Emergency multiplier', 'num'),
          _ConfigFieldSpec('holidayMultiplier', 'Holiday multiplier', 'num'),
          _ConfigFieldSpec('cancellationCharge', 'Cancellation charge', 'num'),
          _ConfigFieldSpec(
              'platformCommission', 'Platform commission %', 'num'),
          _ConfigFieldSpec('driverPayoutPercent', 'Driver payout %', 'num'),
          _ConfigFieldSpec('ownerPayoutPercent', 'Owner payout %', 'num'),
          _ConfigFieldSpec('codEnabled', 'COD enabled', 'bool'),
        ],
        data: snapshot.data() ?? const {},
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _AdminSettingsView extends ConsumerWidget {
  const _AdminSettingsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(platformConfigProvider);
    return config.when(
      data: (snapshot) => _PlatformConfigEditor(
        title: 'Dispatch and service settings',
        subtitle:
            'Control booking availability, service radius, assignment rules, support contact, and maintenance mode.',
        fields: const [
          _ConfigFieldSpec('bookingsEnabled', 'Bookings enabled', 'bool'),
          _ConfigFieldSpec('maintenanceMode', 'Maintenance mode', 'bool'),
          _ConfigFieldSpec('dispatchRadiusKm', 'Dispatch radius km', 'num'),
          _ConfigFieldSpec('topSellerLimit', 'Nearest seller limit', 'num'),
          _ConfigFieldSpec(
              'autoDriverAssignment', 'Auto driver assignment', 'bool'),
          _ConfigFieldSpec(
              'selfDriveEnabled', 'Owner self-drive enabled', 'bool'),
          _ConfigFieldSpec('serviceCity', 'Service city', 'text'),
          _ConfigFieldSpec('supportEmail', 'Support email', 'text'),
          _ConfigFieldSpec('supportNumber', 'Support number', 'text'),
          _ConfigFieldSpec('razorpayMode', 'Razorpay mode', 'text'),
        ],
        data: snapshot.data() ?? const {},
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _PlatformConfigEditor extends StatefulWidget {
  const _PlatformConfigEditor({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.data,
  });

  final String title;
  final String subtitle;
  final List<_ConfigFieldSpec> fields;
  final Map<String, dynamic> data;

  @override
  State<_PlatformConfigEditor> createState() => _PlatformConfigEditorState();
}

class _PlatformConfigEditorState extends State<_PlatformConfigEditor> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _switches = {};

  @override
  void initState() {
    super.initState();
    _syncFromData();
  }

  @override
  void didUpdateWidget(covariant _PlatformConfigEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _syncFromData();
  }

  void _syncFromData() {
    for (final field in widget.fields) {
      if (field.type == 'bool') {
        _switches[field.key] = widget.data[field.key] as bool? ?? false;
      } else {
        _controllers[field.key] ??= TextEditingController();
        _controllers[field.key]!.text =
            (widget.data[field.key] ?? '').toString();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final patch = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    for (final field in widget.fields) {
      if (field.type == 'bool') {
        patch[field.key] = _switches[field.key] ?? false;
      } else if (field.type == 'num') {
        patch[field.key] =
            num.tryParse(_controllers[field.key]?.text.trim() ?? '') ?? 0;
      } else {
        patch[field.key] = _controllers[field.key]?.text.trim() ?? '';
      }
    }
    await FirebaseFirestore.instance
        .collection('configs')
        .doc('platform')
        .set(patch, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AdminHeader(title: widget.title, subtitle: widget.subtitle),
        OpsCard(
          child: Column(
            children: [
              for (final field in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: field.type == 'bool'
                      ? SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            field.label,
                            style: const TextStyle(
                              color: OpsColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          value: _switches[field.key] ?? false,
                          onChanged: (value) =>
                              setState(() => _switches[field.key] = value),
                        )
                      : _AdminTextField(
                          controller: _controllers[field.key]!,
                          label: field.label,
                          keyboardType: field.type == 'num'
                              ? TextInputType.number
                              : TextInputType.text,
                        ),
                ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save configuration'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfigFieldSpec {
  const _ConfigFieldSpec(this.key, this.label, this.type);
  final String key;
  final String label;
  final String type;
}

class _RoleCollectionView extends ConsumerWidget {
  const _RoleCollectionView({
    required this.title,
    required this.collection,
    required this.icon,
    required this.roleLabel,
    this.roleFilter,
  });

  final String title;
  final String collection;
  final IconData icon;
  final String roleLabel;
  final String? roleFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream =
        FirebaseFirestore.instance.collection(collection).snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs.where((doc) {
          if (roleFilter == null) return true;
          return (doc.data()['role'] ?? '').toString() == roleFilter;
        }).toList();
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _AdminHeader(
                title: title,
                subtitle:
                    'Manage live $roleLabel records, approvals, and account access.',
              );
            }
            return _RoleRecordCard(
              doc: docs[index - 1],
              collection: collection,
              icon: icon,
              roleLabel: roleLabel,
            );
          },
        );
      },
    );
  }
}

class _RoleRecordCard extends StatelessWidget {
  const _RoleRecordCard({
    required this.doc,
    required this.collection,
    required this.icon,
    required this.roleLabel,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String collection;
  final IconData icon;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final name = (data['ownerName'] ??
            data['driverName'] ??
            data['fullName'] ??
            data['displayName'] ??
            data['businessName'] ??
            doc.id)
        .toString();
    final contact =
        (data['email'] ?? data['phoneNumber'] ?? data['phone'] ?? doc.id)
            .toString();
    final status = _approvalStatus(data);
    final blocked = data['isBlocked'] as bool? ?? status == 'suspended';

    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: OpsColors.blue),
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
                      contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: OpsColors.muted),
                    ),
                  ],
                ),
              ),
              OpsStatusPill(
                label: blocked ? 'SUSPENDED' : status.toUpperCase(),
                color: blocked ? OpsColors.red : orderStatusColor(status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (collection != 'users')
                FilledButton(
                  onPressed: () => _setPartnerStatus('approved'),
                  child: const Text('Approve'),
                ),
              OutlinedButton(
                onPressed: () => _setPartnerStatus('suspended'),
                child: const Text('Suspend'),
              ),
              OutlinedButton(
                onPressed: () => _setPartnerStatus('active'),
                child: const Text('Activate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setPartnerStatus(String status) async {
    final patch = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (collection == 'users') {
      patch['isBlocked'] = status == 'suspended';
    } else {
      patch['verificationStatus'] = status == 'active' ? 'approved' : status;
      patch['isBlocked'] = status == 'suspended';
    }
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(doc.id)
        .set(patch, SetOptions(merge: true));
    await FirebaseFirestore.instance.collection('users').doc(doc.id).set({
      'role': roleLabel,
      'isBlocked': status == 'suspended',
      'isVerified': status != 'suspended',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  String _targetRole = 'all';

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _message.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('admin_notifications').add({
      'title': _title.text.trim(),
      'message': _message.text.trim(),
      'targetRole': _targetRole,
      'status': 'queued',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _title.clear();
    _message.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification queued')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _AdminHeader(
          title: 'Notification control',
          subtitle:
              'Queue role-targeted push, maintenance, emergency, or promotional messages.',
        ),
        OpsCard(
          child: Column(
            children: [
              _AdminTextField(controller: _title, label: 'Title'),
              _AdminTextField(
                controller: _message,
                label: 'Message',
                maxLines: 3,
              ),
              DropdownButtonFormField<String>(
                value: _targetRole,
                decoration: const InputDecoration(labelText: 'Target role'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All users')),
                  DropdownMenuItem(value: 'consumer', child: Text('Consumers')),
                  DropdownMenuItem(value: 'driver', child: Text('Drivers')),
                  DropdownMenuItem(value: 'seller', child: Text('Tank owners')),
                ],
                onChanged: (value) =>
                    setState(() => _targetRole = value ?? 'all'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _send,
                  child: const Text('Queue notification'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _CollectionFeed(
          title: 'Queued notifications',
          collection: 'admin_notifications',
          emptyMessage: 'No notifications have been queued yet.',
        ),
      ],
    );
  }
}

class _SupportView extends StatelessWidget {
  const _SupportView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _AdminHeader(
          title: 'Support and escalations',
          subtitle:
              'Complaints, disputes, cancellation issues, and payment tickets from Firestore.',
        ),
        _CollectionFeed(
          title: 'Support tickets',
          collection: 'support_tickets',
          emptyMessage: 'No support tickets recorded yet.',
        ),
        SizedBox(height: 16),
        _CollectionFeed(
          title: 'Complaints',
          collection: 'complaints',
          emptyMessage: 'No complaints recorded yet.',
        ),
      ],
    );
  }
}

class _CollectionFeed extends StatelessWidget {
  const _CollectionFeed({
    required this.title,
    required this.collection,
    required this.emptyMessage,
  });

  final String title;
  final String collection;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        return OpsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: OpsColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 12),
              if (!snapshot.hasData)
                const LinearProgressIndicator(minHeight: 2)
              else if (docs.isEmpty)
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    color: OpsColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                for (final doc in docs.take(12))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      (doc.data()['title'] ??
                              doc.data()['subject'] ??
                              doc.data()['message'] ??
                              doc.id)
                          .toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      (doc.data()['status'] ?? collection).toString(),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfigLine extends StatelessWidget {
  const _ConfigLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: OpsColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: OpsColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  const _AdminTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.enabled = true,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: OpsColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: OpsColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: OpsColors.blue, width: 1.5),
          ),
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(
                      'Customer ${data['customerName'] ?? '-'} | Payment ${data['paymentStatus'] ?? 'PENDING'}',
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
              OpsStatusPill(
                label: formatOrderStatus(status),
                color: orderStatusColor(status),
              ),
            ],
          ),
          if (status != 'DELIVERED' && status != 'CANCELLED') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  onPressed: () => FirebaseFirestore.instance
                      .collection('orders')
                      .doc(doc.id)
                      .set({
                    'status': 'CANCELLED',
                    'cancelledBy': 'admin',
                    'cancellationReason': 'Admin force cancelled',
                    'cancelledAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true)),
                  child: const Text('Force cancel'),
                ),
                OutlinedButton(
                  onPressed: () => _showManualAssignDialog(context, doc),
                  child: const Text('Manual assign'),
                ),
                OutlinedButton(
                  onPressed: () => FirebaseFirestore.instance
                      .collection('orders')
                      .doc(doc.id)
                      .set({
                    'adminResolved': true,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true)),
                  child: const Text('Mark resolved'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> _showManualAssignDialog(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> order,
  ) async {
    final owner =
        TextEditingController(text: order.data()['sellerId']?.toString() ?? '');
    final driver =
        TextEditingController(text: order.data()['driverId']?.toString() ?? '');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AdminTextField(controller: owner, label: 'Seller UID'),
            _AdminTextField(controller: driver, label: 'Driver UID'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(order.id)
                  .set({
                'sellerId':
                    owner.text.trim().isEmpty ? null : owner.text.trim(),
                'driverId':
                    driver.text.trim().isEmpty ? null : driver.text.trim(),
                'status':
                    driver.text.trim().isEmpty ? 'ACCEPTED' : 'DRIVER_ASSIGNED',
                'assignedAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
    owner.dispose();
    driver.dispose();
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
        final delivered = snapshot.docs.where((doc) {
          return (doc.data()['status'] ?? '').toString() == 'DELIVERED';
        }).toList();
        final cancelled = snapshot.docs.where((doc) {
          return (doc.data()['status'] ?? '').toString() == 'CANCELLED';
        }).length;
        final totalRevenue = delivered.fold<num>(0, (total, doc) {
          return total + (doc.data()['amount'] as num? ?? 0);
        });

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _AdminHeader(
              title: 'Payments',
              subtitle:
                  'Revenue, payout, refund, and settlement status from order records.',
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
                    SizedBox(
                      width: width,
                      child: OpsCard(
                        child: _PaymentMetric(
                          label: 'Delivered revenue',
                          value: 'Rs ${totalRevenue.toInt()}',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: OpsCard(
                        child: _PaymentMetric(
                          label: 'Cancelled refunds',
                          value: '$cancelled',
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

class _AdminProfileView extends ConsumerWidget {
  const _AdminProfileView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        OpsCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: OpsColors.green.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: OpsColors.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Admin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OpsColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      user?.email ?? 'WaterBuddy admin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: OpsColors.muted),
                    ),
                  ],
                ),
              ),
              const OpsStatusPill(label: 'ADMIN', color: OpsColors.green),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OpsCard(
          child: Column(
            children: [
              const _SettingsRow(
                icon: Icons.shield_rounded,
                title: 'Security access',
                subtitle: 'Allowlist and admins collection control access.',
              ),
              const Divider(height: 24),
              _SettingsRow(
                icon: Icons.settings_rounded,
                title: 'Console settings',
                subtitle:
                    'Approvals, users, payments, and operations settings.',
                onTap: () => context.push(RouteNames.appSettings),
              ),
              const Divider(height: 24),
              const _SettingsRow(
                icon: Icons.support_agent_rounded,
                title: 'Support',
                subtitle: 'waterbuddyapp.wb@gmail.com',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await signOutToRoleSelection(context: context, ref: ref);
            },
            icon: const Icon(Icons.logout_rounded, color: OpsColors.red),
            label: const Text('Logout'),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, color: OpsColors.blue),
        const SizedBox(width: 12),
        Expanded(
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: OpsColors.muted),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(Icons.chevron_right_rounded, color: OpsColors.muted),
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: row,
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
  const _AdminHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            action!,
          ],
        ],
      ),
    );
  }
}
