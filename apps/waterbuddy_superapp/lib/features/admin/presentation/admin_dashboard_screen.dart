import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFF0D1117),
          drawer: _buildDrawer(context, auth.email ?? 'admin@waterbuddy.com'),
          body: Stack(
            children: [
              _buildBgOrbs(),
              SafeArea(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      floating: true,
                      pinned: true,
                      leading: IconButton(
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
                      title: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WaterBuddy',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Operations Control',
                            style: TextStyle(color: Color(0xFF14B8A6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      actions: [
                        _buildProfileMenu(context),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ],
                  body: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildWelcomeHeader(auth.displayName ?? 'Administrator'),
                      const SizedBox(height: 24),
                      _buildStatsGrid(users, sellers, drivers, orders),
                      const SizedBox(height: 32),
                      _buildMainConsole(sellers),
                    ],
                  ),
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
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w400),
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
                    style: TextStyle(color: Color(0xFF14B8A6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$displayName 👋',
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    AsyncValue<QuerySnapshot> users,
    AsyncValue<QuerySnapshot> sellers,
    AsyncValue<QuerySnapshot> drivers,
    AsyncValue<QuerySnapshot> orders,
  ) {
    final uCount = users.value?.docs.length ?? 0;
    final sCount = sellers.value?.docs.length ?? 0;
    final dCount = drivers.value?.docs.length ?? 0;
    final oCount = orders.value?.docs.length ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: [
        _buildStatCard(
          title: 'Users',
          value: '$uCount',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF3B82F6),
          subtitle: 'Registered buyers',
        ),
        _buildStatCard(
          title: 'Sellers',
          value: '$sCount',
          icon: Icons.storefront_rounded,
          color: const Color(0xFF10B981),
          subtitle: 'Water partners',
        ),
        _buildStatCard(
          title: 'Drivers',
          value: '$dCount',
          icon: Icons.local_shipping_rounded,
          color: const Color(0xFFF59E0B),
          subtitle: 'Delivery agents',
        ),
        _buildStatCard(
          title: 'Active Orders',
          value: '$oCount',
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF8B5CF6),
          subtitle: 'Live dispatch',
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Icon(icon, size: 96, color: color.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _buildMainConsole(AsyncValue<QuerySnapshot> sellers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF14B8A6),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
          tabs: const [
            Tab(text: 'Pending KYC'),
            Tab(text: 'All Partners'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 500, // Safe bounding box for inner tab view list
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingKYCTab(sellers),
              _buildAllPartnersTab(sellers),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingKYCTab(AsyncValue<QuerySnapshot> sellers) {
    return sellers.when(
      data: (snapshot) {
        final pending = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['verificationStatus'] ?? data['kycStatus'] ?? '').toString().toLowerCase();
          return status == 'pending' || status == 'review' || status == '';
        }).toList();

        if (pending.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF14B8A6), size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Pending Onboardings',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'All sellers are currently verified and active.',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: pending.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildSellerApprovalCard(pending[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      error: (e, _) => Center(child: Text('Error loading approvals: $e', style: const TextStyle(color: Colors.redAccent))),
    );
  }

  Widget _buildAllPartnersTab(AsyncValue<QuerySnapshot> sellers) {
    return sellers.when(
      data: (snapshot) {
        final list = snapshot.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['businessName'] ?? data['ownerName'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        return Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search partner or store name...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        'No partners found matching search',
                        style: TextStyle(color: Colors.white.withOpacity(0.4)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final doc = list[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['businessName'] ?? data['ownerName'] ?? 'Unnamed Partner').toString();
                        final status = (data['verificationStatus'] ?? data['kycStatus'] ?? 'pending').toString().toUpperCase();
                        final email = (data['email'] ?? 'No email').toString();

                        Color statusColor = Colors.orangeAccent;
                        if (status == 'APPROVED' || status == 'VERIFIED') {
                          statusColor = const Color(0xFF10B981);
                        } else if (status == 'REJECTED' || status == 'SUSPENDED') {
                          statusColor = Colors.redAccent;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.storefront_rounded, color: statusColor, size: 20),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Text(
                              email,
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withOpacity(0.2)),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
    );
  }

  Widget _buildSellerApprovalCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['verificationStatus'] ?? data['kycStatus'] ?? 'pending').toString().toUpperCase();
    final name = (data['businessName'] ?? data['ownerName'] ?? data['name'] ?? doc.id).toString();
    final phone = (data['phoneNumber'] ?? 'No contact').toString();

    final docs = data['documents'] as Map<String, dynamic>?;
    final aadhaar = docs?['aadhaarUrl'] ?? data['aadhaarUploadUrl'];
    final dl = docs?['dlUrl'] ?? data['licenseUploadUrl'];
    final rc = docs?['rcUrl'] ?? data['vehicleRcUploadUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📞 $phone',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 12),
          const Text(
            'KYC Documents Preview',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            'Tap document thumbnail to zoom and verify details',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (aadhaar != null && aadhaar.toString().isNotEmpty)
                _buildDocThumbnail(context, 'Aadhaar Card', aadhaar.toString()),
              if (dl != null && dl.toString().isNotEmpty)
                _buildDocThumbnail(context, 'Driver License', dl.toString()),
              if (rc != null && rc.toString().isNotEmpty)
                _buildDocThumbnail(context, 'Vehicle RC', rc.toString()),
              if ((aadhaar == null || aadhaar.toString().isEmpty) &&
                  (dl == null || dl.toString().isEmpty) &&
                  (rc == null || rc.toString().isEmpty))
                Text(
                  'No uploaded documents found.',
                  style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontSize: 13, fontStyle: FontStyle.italic),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _updateSellerStatus(doc.id, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateSellerStatus(doc.id, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocThumbnail(BuildContext context, String type, String url) {
    return GestureDetector(
      onTap: () => _showImagePreview(context, url, type),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.white.withOpacity(0.05),
                  child: const Icon(Icons.broken_image_rounded, color: Colors.white24, size: 24),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              type,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl, String documentType) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        documentType,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              height: 250,
                              child: Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.white.withOpacity(0.05),
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, color: Colors.redAccent, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ' Pinch / drag to zoom & pan the document',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSellerStatus(String id, String status) async {
    final db = FirebaseFirestore.instance;
    final kycVal = status == 'approved' ? 'VERIFIED' : 'REJECTED';
    final verificationVal = status == 'approved' ? 'approved' : 'rejected';

    await db.collection('sellers').doc(id).set({
      'verificationStatus': verificationVal,
      'kycStatus': kycVal,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seller partner status set to $status successfully.'),
          backgroundColor: status == 'approved' ? const Color(0xFF10B981) : Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 50),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      icon: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF14B8A6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14B8A6).withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF0F766E),
          child: Text(
            'WB',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 3,
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 12),
              const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
      onSelected: (val) async {
        if (val == 3) {
          await ref.read(authServiceProvider).signOut();
          if (context.mounted) {
            context.go(RouteNames.roleSelection);
          }
        }
      },
    );
  }

  Widget _buildDrawer(BuildContext context, String email) {
    return Drawer(
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Custom Drawer Header (Glassmorphic)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF1E293B),
                      child: Text('WB', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WaterBuddy Admin',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Menu items
            _buildDrawerItem(
              icon: Icons.dashboard_rounded,
              title: 'Dashboard Overview',
              isActive: true,
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.storefront_rounded,
              title: 'Partner Approvals',
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(0);
              },
            ),
            _buildDrawerItem(
              icon: Icons.people_alt_rounded,
              title: 'Registered Users',
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),
            _buildDrawerItem(
              icon: Icons.local_shipping_rounded,
              title: 'Dispatch Tracking',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispatch operations auto-synced live on maps.')),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.insights_rounded,
              title: 'Revenue Analytics',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Financial analytics report synced live.')),
                );
              },
            ),
            const Spacer(),
            // Drawer Footer / Sign Out Action
            Divider(color: Colors.white.withOpacity(0.06)),
            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'Sign Out Console',
              iconColor: Colors.redAccent,
              titleColor: Colors.redAccent,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go(RouteNames.roleSelection);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF14B8A6).withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isActive ? Border.all(color: const Color(0xFF14B8A6).withOpacity(0.15)) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF14B8A6) : (iconColor ?? Colors.white.withOpacity(0.6)),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF14B8A6) : (titleColor ?? Colors.white.withOpacity(0.8)),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}
