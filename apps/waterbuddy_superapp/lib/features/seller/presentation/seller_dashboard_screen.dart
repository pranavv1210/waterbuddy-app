import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/order.dart';
import '../../../providers/app_providers.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(sellerOnlineProvider);
    final searchingOrders = ref.watch(searchingOrdersProvider);
    final activeOrders = ref.watch(sellerActiveOrdersProvider);
    final drivers = ref.watch(driversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        actions: [
          Switch(
            value: online,
            onChanged: (value) => ref.read(sellerOnlineProvider.notifier).setOnline(value),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Nearby order feed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...searchingOrders.when(
            data: (orders) => orders
                .map((order) => _OrderCard(
                      order: order,
                      actionLabel: 'Accept',
                      onAction: () => ref.read(orderServiceProvider).acceptOrder(order.id, ref.read(currentUserProvider)!.uid),
                    ))
                .toList(),
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (error, _) => [Text(error.toString())],
          ),
          const SizedBox(height: 20),
          const Text('Active deliveries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...activeOrders.when(
            data: (orders) => orders
                .map((order) => _OrderCard(
                      order: order,
                      actionLabel: order.status == 'ASSIGNED'
                          ? 'Start Delivery'
                          : order.status == 'ON_THE_WAY'
                              ? 'Mark Arrived'
                              : 'Mark Delivered',
                      onAction: () => ref.read(orderServiceProvider).updateOrderStatus(
                            order.id,
                            order.status == 'ASSIGNED'
                                ? 'ON_THE_WAY'
                                : order.status == 'ON_THE_WAY'
                                    ? 'ARRIVED'
                                    : 'DELIVERED',
                          ),
                      assignDriverChild: drivers.when(
                        data: (snapshot) {
                          final list = snapshot.docs.where((d) {
                            final data = d.data();
                            return data['sellerId'] == ref.read(currentUserProvider)?.uid;
                          }).toList();
                          if (list.isEmpty) return const SizedBox.shrink();
                          return DropdownButtonFormField<String>(
                            value: order.driverId,
                            hint: const Text('Assign driver'),
                            items: list
                                .map((doc) => DropdownMenuItem(
                                      value: doc.id,
                                      child: Text((doc.data()['driverName'] ?? doc.id).toString()),
                                    ))
                                .toList(),
                            onChanged: (driverId) {
                              if (driverId == null) return;
                              ref.read(orderServiceProvider).assignDriver(
                                    orderId: order.id,
                                    sellerId: ref.read(currentUserProvider)!.uid,
                                    driverId: driverId,
                                  );
                            },
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ))
                .toList(),
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (error, _) => [Text(error.toString())],
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.actionLabel,
    required this.onAction,
    this.assignDriverChild,
  });

  final Order order;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget? assignDriverChild;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ${order.id}', maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(order.location['address'] as String? ?? 'Address unavailable'),
            Text('Status: ${order.status}'),
            if (assignDriverChild != null) ...[
              const SizedBox(height: 8),
              assignDriverChild!,
            ],
            const SizedBox(height: 8),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
