import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../orders/providers/order_providers.dart';

class LocationSelectionScreen extends ConsumerStatefulWidget {
  const LocationSelectionScreen({super.key, this.pickupAddress});
  final String? pickupAddress;

  @override
  ConsumerState<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends ConsumerState<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0F172A);
    final history = ref.watch(orderHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Drop',
          style: TextStyle(color: primary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Text('For me', style: TextStyle(color: primary, fontSize: 12)),
                Icon(Icons.keyboard_arrow_down, color: primary, size: 16),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Column(
                     children: [
                       Container(
                         width: 8,
                         height: 8,
                         decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                       ),
                       Container(width: 1, height: 20, color: Colors.grey[300]),
                       Container(
                         width: 8,
                         height: 8,
                         decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                       ),
                     ],
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text(
                            widget.pickupAddress ?? 'Current Location',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                         const Divider(height: 20),
                         TextField(
                           controller: _searchController,
                           autofocus: true,
                           decoration: const InputDecoration(
                             hintText: 'Drop location',
                             border: InputBorder.none,
                             hintStyle: TextStyle(color: Colors.grey),
                           ),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
          ),

          // Quick Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _QuickOption(
                  icon: Icons.location_on_outlined,
                  label: 'Select on map',
                  onTap: () {
                    // Navigate back with map select signal or similar
                    context.pop({'selectOnMap': true});
                  },
                ),
                const SizedBox(width: 12),
                _QuickOption(
                  icon: Icons.add,
                  label: 'Add stops',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(thickness: 1, height: 1),

          // Recent Searches List
          Expanded(
            child: history.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(child: Text('No recent searches'));
                }
                
                final uniqueLocations = <String, Map<String, dynamic>>{};
                for (var order in orders) {
                   if (order.deliveryAddress != null && order.location != null) {
                      uniqueLocations[order.deliveryAddress!] = {
                        'address': order.deliveryAddress,
                        'location': order.location,
                      };
                   }
                }
                
                final locations = uniqueLocations.values.toList();

                return ListView.separated(
                  itemCount: locations.length,
                  separatorBuilder: (_, __) => const Divider(indent: 70, height: 1),
                  itemBuilder: (context, index) {
                    final loc = locations[index];
                    return ListTile(
                      leading: const Icon(Icons.history, color: Colors.grey),
                      title: Text(
                        loc['address'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: const Text('Bangalore, Karnataka, India', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                      onTap: () {
                        context.pop({'location': loc['location'], 'address': loc['address']});
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickOption extends StatelessWidget {
  const _QuickOption({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
