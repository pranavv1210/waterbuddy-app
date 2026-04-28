import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../routes/route_names.dart';
import '../models/home_dashboard.dart';
import '../providers/home_providers.dart';
import '../providers/order_creation_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final selectedTankId = ref.watch(selectedTankIdProvider) ?? 'medium';

    return _HomeScreenBody(
      state: dashboard,
      selectedTankId: selectedTankId,
      onTankSelected: (tankId) {
        ref.read(selectedTankIdProvider.notifier).state = tankId;
      },
    );
  }
}

class _HomeScreenBody extends ConsumerStatefulWidget {
  const _HomeScreenBody({
    required this.state,
    required this.selectedTankId,
    required this.onTankSelected,
  });

  final HomeDashboard state;
  final String selectedTankId;
  final ValueChanged<String> onTankSelected;

  @override
  ConsumerState<_HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends ConsumerState<_HomeScreenBody> {
  // Dynamic structure as requested
  final List<Map<String, dynamic>> tankOptionsData = [
    {'id': 'small', 'size': 'Small Tank', 'litres': 10000, 'icon': Icons.opacity_rounded, 'basePrice': 500},
    {'id': 'medium', 'size': 'Medium Tank', 'litres': 15000, 'icon': Icons.water_drop_rounded, 'basePrice': 750},
    {'id': 'large', 'size': 'Large Tank', 'litres': 20000, 'icon': Icons.waves_rounded, 'basePrice': 1000},
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const primary = Color(0xFF0F2B5B);
    const accent = Color(0xFF0EA5E9);

    return Scaffold(
      body: Stack(
        children: [
          // 1. FULL SCREEN MAP BACKGROUND
          Positioned.fill(
            child: Image.network(
              'https://api.mapbox.com/styles/v1/mapbox/light-v10/static/77.5946,12.9716,12,0/800x1200?access_token=YOUR_MAPBOX_TOKEN', // Static map placeholder
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
            ),
          ),

          // 2. TOP BAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'WaterBuddy',
                      style: TextStyle(
                        color: primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _TopIconButton(
                        icon: Icons.notifications_none_rounded,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: user?.photoURL != null
                              ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                              : Container(
                                  color: accent,
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. CENTER: User location marker (static)
          const Center(
            child: _LocationMarker(),
          ),

          // 4. FLOATING ACTION BUTTON: "Locate me"
          Positioned(
            bottom: 340,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.white,
              foregroundColor: primary,
              mini: true,
              child: const Icon(Icons.my_location),
            ),
          ),

          // 5. TANK SELECTION & BOOK BUTTON
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Tank Size',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: tankOptionsData.map((data) {
                      final isSelected = widget.selectedTankId == data['id'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onTankSelected(data['id']),
                          child: _TankCard(
                            data: data,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final orderController = ref.read(orderCreationControllerProvider.notifier);
                        final selectedOption = tankOptionsData.firstWhere((t) => t['id'] == widget.selectedTankId);
                        
                        final orderId = await orderController.createOrder(
                          tankSize: (selectedOption['litres'] as int).toDouble(),
                          tankLabel: selectedOption['size'],
                          location: {'latitude': 0.0, 'longitude': 0.0},
                          paymentType: 'COD',
                        );
                        
                        if (orderId != null && mounted) {
                          context.go('${RouteNames.searching}?orderId=$orderId');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Book Water',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
}

class _LocationMarker extends StatelessWidget {
  const _LocationMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF0F2B5B).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFF0F2B5B),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.white, blurRadius: 4, spreadRadius: 2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TankCard extends StatelessWidget {
  const _TankCard({
    required this.data,
    required this.isSelected,
  });

  final Map<String, dynamic> data;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2B5B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F2B5B) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              data['icon'],
              color: isSelected ? Colors.white : const Color(0xFF0F2B5B),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              data['size'].split(' ')[0],
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0F2B5B),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              '${data['litres'] ~/ 1000}k L',
              style: TextStyle(
                color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₹${data['basePrice']}', // Dynamic placeholder
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0F2B5B),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF64748B)),
        onPressed: onPressed,
      ),
    );
  }
}
