import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/order.dart';
import '../../../providers/app_providers.dart';

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(driverAssignedOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Dashboard')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No assigned deliveries'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (_, index) => _DriverOrderCard(order: orders[index], ref: ref),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

class _DriverOrderCard extends StatelessWidget {
  const _DriverOrderCard({required this.order, required this.ref});
  final Order order;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final address = order.location['address'] as String? ?? '';
    final lat = order.location['latitude'] as num?;
    final lng = order.location['longitude'] as num?;
    final customerPhone = order.location['customerPhone'] as String? ?? '';
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address.isEmpty ? 'Delivery location unavailable' : address),
            Text('Status: ${order.status}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: lat == null || lng == null
                      ? null
                      : () async {
                          final uri = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=${lat.toDouble()},${lng.toDouble()}');
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                  child: const Text('Navigate'),
                ),
                OutlinedButton(
                  onPressed: customerPhone.isEmpty
                      ? null
                      : () async {
                          await launchUrl(Uri(scheme: 'tel', path: customerPhone));
                        },
                  child: const Text('Call'),
                ),
                FilledButton(
                  onPressed: () => ref.read(orderServiceProvider).updateOrderStatus(
                        order.id,
                        order.status == 'DRIVER_ASSIGNED' ? 'ON_THE_WAY' : 'ARRIVED',
                      ),
                  child: Text(order.status == 'DRIVER_ASSIGNED' ? 'Start' : 'Mark Arrived'),
                ),
                FilledButton(
                  onPressed: () => ref.read(orderServiceProvider).updateOrderStatus(order.id, 'DELIVERED'),
                  child: const Text('Mark Delivered'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
