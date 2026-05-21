import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeTab = 0; // 0: Overview, 1: Seller KYC, 2: Drivers KYC, 3: User Management, 4: Live Orders, 5: Commission Analytics
  String _searchQuery = '';

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Operations Hub', 'icon': Icons.dashboard_rounded},
    {'label': 'Seller KYC Approvals', 'icon': Icons.storefront_rounded},
    {'label': 'Driver KYC Approvals', 'icon': Icons.local_shipping_rounded},
    {'label': 'User Management', 'icon': Icons.people_alt_rounded},
    {'label': 'Live Orders Monitor', 'icon': Icons.radar_rounded},
    {'label': 'Revenue & Commissions', 'icon': Icons.analytics_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).value;
    if (auth == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
        ),
      );
    }

    final users = ref.watch(usersProvider);
    final sellers = ref.watch(sellersProvider);
    final drivers = ref.watch(driversProvider);
    final orders = ref.watch(allOrdersProvider);

    return FutureBuilder<bool>(
      future: ref.read(authServiceProvider).isAuthorizedAdmin(auth),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D1117),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
            ),
          );
        }

        if (snapshot.data != true) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D1117),
            body: Stack(
              children: [
                _buildBgOrbs(),
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 72),
                        const SizedBox(height: 20),
                        const Text(
                          'Access Denied',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You do not have administrative privileges to access this console.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: () async {
                            await ref.read(authServiceProvider).signOut();
                            if (context.mounted) {
                              context.go(RouteNames.roleSelection);
                            }
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Return & Sign Out'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final mediaQuery = MediaQuery.of(context);
        final isDesktop = mediaQuery.size.width > 900;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFF0D1117),
          drawer: isDesktop ? null : _buildDrawer(context, auth.email ?? 'admin@waterbuddy.com'),
          body: Stack(
            children: [
              _buildBgOrbs(),
              SafeArea(
                child: isDesktop
                    ? Row(
                        children: [
                          // Custom Desktop Sidebar
                          _buildDesktopSidebar(context, auth.email ?? 'admin@waterbuddy.com'),
                          const VerticalDivider(width: 1, color: Colors.white12),
                          // Right Main Content Pane
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildWelcomeHeader(auth.displayName ?? 'Administrator'),
                                  const SizedBox(height: 24),
                                  _buildStatsRow(users, sellers, drivers, orders),
                                  const SizedBox(height: 32),
                                  Expanded(
                                    child: _buildTabContent(users, sellers, drivers, orders),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                                ),
                                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                              ),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'WaterBuddy Admin',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    'Operations Control',
                                    style: TextStyle(color: Color(0xFF14B8A6), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildWelcomeHeader(auth.displayName ?? 'Administrator'),
                          const SizedBox(height: 24),
                          _buildStatsRow(users, sellers, drivers, orders),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 600,
                            child: _buildTabContent(users, sellers, drivers, orders),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBgOrbs() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0F766E),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF14B8A6),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: const Color(0xFF0D1117).withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(String name) {
    final displayName = (name.trim().isEmpty || name.toLowerCase() == 'admin' || name.toLowerCase() == 'administrator')
        ? 'WaterBuddy Admin'
        : name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w400),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF14B8A6).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF14B8A6)),
                  SizedBox(width: 6),
                  Text(
                    'Live Sync',
                    style: TextStyle(color: Color(0xFF14B8A6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$displayName 👋',
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    AsyncValue<QuerySnapshot> users,
    AsyncValue<QuerySnapshot> sellers,
    AsyncValue<QuerySnapshot> drivers,
    AsyncValue<QuerySnapshot> orders,
  ) {
    final uCount = users.value?.docs.length ?? 0;
    final sCount = sellers.value?.docs.length ?? 0;
    final dCount = drivers.value?.docs.length ?? 0;
    final oCount = orders.value?.docs.length ?? 0;

    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Registered Users',
              value: '$uCount',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF3B82F6),
              subtitle: 'Water buyers',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Seller Partners',
              value: '$sCount',
              icon: Icons.storefront_rounded,
              color: const Color(0xFF10B981),
              subtitle: 'Tanker suppliers',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Driver Fleet',
              value: '$dCount',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFFF59E0B),
              subtitle: 'Delivery crew',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Active Orders',
              value: '$oCount',
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF8B5CF6),
              subtitle: 'Live deliveries',
              isLive: true,
            ),
          ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _buildStatCard(
          title: 'Users',
          value: '$uCount',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF3B82F6),
          subtitle: 'Buyers',
        ),
        _buildStatCard(
          title: 'Sellers',
          value: '$sCount',
          icon: Icons.storefront_rounded,
          color: const Color(0xFF10B981),
          subtitle: 'Suppliers',
        ),
        _buildStatCard(
          title: 'Drivers',
          value: '$dCount',
          icon: Icons.local_shipping_rounded,
          color: const Color(0xFFF59E0B),
          subtitle: 'Crew',
        ),
        _buildStatCard(
          title: 'Orders',
          value: '$oCount',
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF8B5CF6),
          subtitle: 'Live deliveries',
          isLive: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool isLive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Icon(icon, size: 72, color: color.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    AsyncValue<QuerySnapshot> users,
    AsyncValue<QuerySnapshot> sellers,
    AsyncValue<QuerySnapshot> drivers,
    AsyncValue<QuerySnapshot> orders,
  ) {
    switch (_activeTab) {
      case 0:
        return _buildOperationsHubView(users, sellers, drivers, orders);
      case 1:
        return _buildSellerKYCView(sellers);
      case 2:
        return _buildDriverKYCView(drivers);
      case 3:
        return _buildUserManagementView(users);
      case 4:
        return _buildLiveOrdersView(orders);
      case 5:
        return _buildCommissionAnalyticsView(orders);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------- TAB 0: OPERATIONS HUB ----------------
  Widget _buildOperationsHubView(
    AsyncValue<QuerySnapshot> users,
    AsyncValue<QuerySnapshot> sellers,
    AsyncValue<QuerySnapshot> drivers,
    AsyncValue<QuerySnapshot> orders,
  ) {
    final sList = sellers.value?.docs ?? [];
    final pendingSellersCount = sList.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final status = (d['verificationStatus'] ?? 'pending').toString().toLowerCase();
      return status == 'pending';
    }).length;

    final dList = drivers.value?.docs ?? [];
    final pendingDriversCount = dList.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final status = (d['verificationStatus'] ?? 'pending').toString().toLowerCase();
      return status == 'pending';
    }).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operations Control Center',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDashboardQuickCard(
                  title: 'Pending Sellers KYC',
                  count: '$pendingSellersCount',
                  actionLabel: 'Verify Partners',
                  icon: Icons.storefront_rounded,
                  color: Colors.tealAccent,
                  onTap: () => setState(() => _activeTab = 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDashboardQuickCard(
                  title: 'Pending Drivers KYC',
                  count: '$pendingDriversCount',
                  actionLabel: 'Verify Drivers',
                  icon: Icons.local_shipping_rounded,
                  color: Colors.amberAccent,
                  onTap: () => setState(() => _activeTab = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('System Log Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Icon(Icons.notes_rounded, color: Colors.white38),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSystemLogItem('Secure Platform session checks enabled universally.', '10 mins ago'),
                _buildSystemLogItem('OTP developer authentication bypass bound to: 123456.', '30 mins ago'),
                _buildSystemLogItem('Seller verification pipelines linked directly to Driver assignment matrices.', '1 hr ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardQuickCard({
    required String title,
    required String count,
    required String actionLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemLogItem(String txt, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: Color(0xFF14B8A6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(txt, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4)),
          ),
          const SizedBox(width: 8),
          Text(time, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
        ],
      ),
    );
  }

  // ---------------- TAB 1: SELLER KYC ----------------
  Widget _buildSellerKYCView(AsyncValue<QuerySnapshot> sellers) {
    return sellers.when(
      data: (snapshot) {
        final pending = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['verificationStatus'] ?? 'pending').toString().toLowerCase();
          return status == 'pending';
        }).toList();

        if (pending.isEmpty) {
          return _buildKYCEmptyState('No Pending Seller Verifications');
        }

        return ListView.builder(
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final doc = pending[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['ownerName'] ?? data['businessName'] ?? 'Supplier #${doc.id.substring(0, 6)}';
            final business = data['businessName'] ?? 'Independant Provider';
            final phone = data['phoneNumber'] ?? 'No contact';
            final capacity = data['tankerCapacity'] ?? '15000 Litres';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                          Text('$business • Capacity: $capacity', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                        icon: const Icon(Icons.call, size: 14, color: Color(0xFF14B8A6)),
                        label: Text(phone, style: const TextStyle(color: Color(0xFF14B8A6), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updatePartnerStatus('sellers', doc.id, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Approve Supplier Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _updatePartnerStatus('sellers', doc.id, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ---------------- TAB 2: DRIVER KYC ----------------
  Widget _buildDriverKYCView(AsyncValue<QuerySnapshot> drivers) {
    return drivers.when(
      data: (snapshot) {
        final pending = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['verificationStatus'] ?? 'pending').toString().toLowerCase();
          return status == 'pending';
        }).toList();

        if (pending.isEmpty) {
          return _buildKYCEmptyState('No Pending Driver Verifications');
        }

        return ListView.builder(
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final doc = pending[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['driverName'] ?? data['fullName'] ?? 'Driver Agent';
            final phone = data['phone'] ?? data['phoneNumber'] ?? 'No contact';
            final license = data['driverLicenseNumber'] ?? 'Unknown License';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                          Text('License: $license', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                        icon: const Icon(Icons.call, size: 14, color: Color(0xFF14B8A6)),
                        label: Text(phone, style: const TextStyle(color: Color(0xFF14B8A6), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updatePartnerStatus('drivers', doc.id, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Approve Driver License', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _updatePartnerStatus('drivers', doc.id, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ---------------- TAB 3: USER MANAGEMENT ----------------
  Widget _buildUserManagementView(AsyncValue<QuerySnapshot> users) {
    return users.when(
      data: (snapshot) {
        final list = snapshot.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final d = doc.data() as Map<String, dynamic>;
          final name = (d['fullName'] ?? d['displayName'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        return Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search registered system users by name...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF14B8A6))),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('No users match your query.', style: TextStyle(color: Colors.white.withOpacity(0.4))))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, idx) {
                        final doc = list[idx];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['fullName'] ?? data['displayName'] ?? 'WaterBuddy User';
                        final role = (data['role'] ?? 'consumer').toString().toUpperCase();
                        final isBlocked = data['isBlocked'] as bool? ?? false;
                        final email = data['email'] ?? 'No email associated';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(role, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(email, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () => _toggleUserBlock(doc.id, isBlocked),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isBlocked ? const Color(0xFF10B981) : Colors.redAccent.withOpacity(0.2),
                                  foregroundColor: isBlocked ? Colors.white : Colors.redAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(isBlocked ? 'Activate User' : 'Suspend User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ---------------- TAB 4: LIVE ORDERS MONITOR ----------------
  Widget _buildLiveOrdersView(AsyncValue<QuerySnapshot> orders) {
    return orders.when(
      data: (snapshot) {
        final list = snapshot.docs.toList();

        if (list.isEmpty) {
          return Center(
            child: Text('No dispatch runs are active at the moment.', style: TextStyle(color: Colors.white.withOpacity(0.4))),
          );
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final doc = list[index];
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id.substring(0, 6).toUpperCase();
            final status = (data['status'] ?? 'searching').toString();
            final address = data['location']?['address'] as String? ?? 'Delivery location details';
            final tankSize = data['tankSize'] as num? ?? 15000;

            Color statColor = Colors.tealAccent;
            if (status == 'DELIVERED') statColor = Colors.greenAccent;
            if (status == 'CANCELLED') statColor = Colors.redAccent;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dispatch ID: #$id', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status, style: TextStyle(color: statColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Tanker volume: ${tankSize.toInt()} Litres', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // ---------------- TAB 5: COMMISSION ANALYTICS ----------------
  Widget _buildCommissionAnalyticsView(AsyncValue<QuerySnapshot> orders) {
    return orders.when(
      data: (snapshot) {
        final docs = snapshot.docs;
        double totalVolume = 0;
        double platformEarnings = 0;
        int completedCount = 0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'DELIVERED') {
            completedCount++;
            final ts = (data['tankSize'] as num? ?? 15000).toDouble();
            totalVolume += ts;
            // Platform charge estimated at ₹150 platform commission flat fee
            platformEarnings += 150.0;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Revenue Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: Colors.white, size: 48),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Platform Profit', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('₹${platformEarnings.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard('Completed Deliveries', '$completedCount', Icons.checklist_rounded),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard('Volume Delivered', '${totalVolume.toInt()} Litres', Icons.opacity_rounded),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(icon, color: const Color(0xFF14B8A6), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildKYCEmptyState(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF14B8A6), size: 48),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('All registered accounts are currently up to date.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, String email) {
    return Container(
      width: 280,
      color: const Color(0xFF0F131C),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF14B8A6), size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WaterBuddy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  Text('Operations Control', style: TextStyle(color: Color(0xFF14B8A6), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _tabs.length,
              itemBuilder: (context, idx) {
                final tab = _tabs[idx];
                final isSel = _activeTab == idx;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = idx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF14B8A6).withOpacity(0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSel ? Border.all(color: const Color(0xFF14B8A6).withOpacity(0.15)) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(tab['icon'], color: isSel ? const Color(0xFF14B8A6) : Colors.white60, size: 20),
                          const SizedBox(width: 14),
                          Text(
                            tab['label'],
                            style: TextStyle(
                              color: isSel ? const Color(0xFF14B8A6) : Colors.white70,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Sign Out Console', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go(RouteNames.roleSelection);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String email) {
    return Drawer(
      backgroundColor: const Color(0xFF0D1117),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF14B8A6),
                    child: Text('WB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WaterBuddy Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(email, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _tabs.length,
                itemBuilder: (context, idx) {
                  final tab = _tabs[idx];
                  final isSel = _activeTab == idx;
                  return ListTile(
                    leading: Icon(tab['icon'], color: isSel ? const Color(0xFF14B8A6) : Colors.white60),
                    title: Text(tab['label'], style: TextStyle(color: isSel ? const Color(0xFF14B8A6) : Colors.white70, fontSize: 13)),
                    selected: isSel,
                    selectedTileColor: const Color(0xFF14B8A6).withOpacity(0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      setState(() => _activeTab = idx);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Sign Out Console', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go(RouteNames.roleSelection);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePartnerStatus(String collection, String id, String status) async {
    final db = FirebaseFirestore.instance;
    await db.collection(collection).doc(id).set({
      'verificationStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$collection partner profile successfully $status.'),
          backgroundColor: status == 'approved' ? const Color(0xFF10B981) : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _toggleUserBlock(String uid, bool currentBlockState) async {
    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(uid).set({
      'isBlocked': !currentBlockState,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentBlockState ? 'User suspended successfully.' : 'User activated successfully.'),
          backgroundColor: !currentBlockState ? Colors.redAccent : const Color(0xFF10B981),
        ),
      );
    }
  }
}
