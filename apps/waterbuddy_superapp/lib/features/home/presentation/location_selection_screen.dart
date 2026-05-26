import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';

import '../../orders/providers/order_providers.dart';

class LocationSelectionScreen extends ConsumerStatefulWidget {
  const LocationSelectionScreen({super.key, this.pickupAddress});

  final String? pickupAddress;

  @override
  ConsumerState<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState
    extends ConsumerState<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitAddress(String value) async {
    final address = value.trim();
    if (address.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    final result = <String, dynamic>{
      'address': address,
      'location': {
        'latitude': 12.9716,
        'longitude': 77.5946,
        'address': address,
      },
    };

    try {
      final matches = await locationFromAddress(address)
          .timeout(const Duration(seconds: 4));
      if (matches.isNotEmpty) {
        result['location'] = {
          'latitude': matches.first.latitude,
          'longitude': matches.first.longitude,
          'address': address,
        };
      }
    } catch (_) {
      // Keep the typed address and fall back to Bengaluru coordinates.
    }

    if (mounted) context.pop(result);
  }

  void _openSavedAddresses(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved delivery addresses yet')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: locations.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Saved delivery addresses',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }
            final loc = locations[index - 1];
            return ListTile(
              leading: const Icon(Icons.water_drop_rounded,
                  color: Color(0xFF0EA5E9)),
              title: Text(
                loc['address'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Use this water delivery address'),
              onTap: () {
                Navigator.pop(context);
                context.pop({
                  'location': loc['location'],
                  'address': loc['address'],
                });
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0F172A);
    const waterBlue = Color(0xFF0EA5E9);
    final history = ref.watch(orderHistoryProvider);
    final savedLocations = history.maybeWhen(
      data: (orders) {
        final uniqueLocations = <String, Map<String, dynamic>>{};
        for (final order in orders) {
          if (order.deliveryAddress != null) {
            uniqueLocations[order.deliveryAddress!] = {
              'address': order.deliveryAddress,
              'location': order.location,
            };
          }
        }
        return uniqueLocations.values.toList();
      },
      orElse: () => <Map<String, dynamic>>[],
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Water Delivery Address',
          style: TextStyle(color: primary, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: waterBlue.withValues(alpha: 0.28)),
                  boxShadow: [
                    BoxShadow(
                      color: waterBlue.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: waterBlue.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: waterBlue,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _submitAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your water delivery address',
                          border: InputBorder.none,
                          hintStyle: const TextStyle(color: Colors.grey),
                          suffixIcon: _submitting
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search_rounded),
                                  onPressed: () => _submitAddress(
                                    _searchController.text,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickOption(
                      icon: Icons.map_rounded,
                      label: 'Choose on map',
                      onTap: () => context.pop({'selectOnMap': true}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickOption(
                      icon: Icons.home_work_rounded,
                      label: 'Saved addresses',
                      onTap: () => _openSavedAddresses(savedLocations),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1, height: 1),
            Expanded(
              child: history.when(
                data: (orders) {
                  final uniqueLocations = <String, Map<String, dynamic>>{};
                  for (final order in orders) {
                    if (order.deliveryAddress != null) {
                      uniqueLocations[order.deliveryAddress!] = {
                        'address': order.deliveryAddress,
                        'location': order.location,
                      };
                    }
                  }

                  final locations = uniqueLocations.values.toList();
                  if (locations.isEmpty) {
                    return const Center(
                      child: Text(
                        'No recent delivery addresses',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: locations.length,
                    separatorBuilder: (_, __) =>
                        const Divider(indent: 70, height: 1),
                    itemBuilder: (context, index) {
                      final loc = locations[index];
                      return ListTile(
                        leading: const Icon(Icons.water_drop_rounded,
                            color: waterBlue),
                        title: Text(
                          loc['address'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: const Text(
                          'Previous water delivery address',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Colors.grey),
                        onTap: () => context.pop({
                          'location': loc['location'],
                          'address': loc['address'],
                        }),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickOption extends StatelessWidget {
  const _QuickOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: const Color(0xFF0F172A)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
