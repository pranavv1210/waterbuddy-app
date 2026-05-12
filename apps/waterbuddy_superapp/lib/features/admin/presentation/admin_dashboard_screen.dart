import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).value;
    if (auth == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final users = ref.watch(usersProvider);
    final sellers = ref.watch(sellersProvider);
    final drivers = ref.watch(driversProvider);
    final orders = ref.watch(allOrdersProvider);
    return FutureBuilder<bool>(
      future: ref.read(authServiceProvider).isAuthorizedAdmin(auth),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data != true) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unauthorized access'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async => ref.read(authServiceProvider).signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _countTile('Users', users.value?.docs.length ?? 0),
          _countTile('Sellers', sellers.value?.docs.length ?? 0),
          _countTile('Drivers', drivers.value?.docs.length ?? 0),
          _countTile('Live Orders', orders.value?.docs.length ?? 0),
          const SizedBox(height: 16),
          const Text('Seller approvals', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...sellers.when(
            data: (snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final status = (data['verificationStatus'] ?? '').toString();
              return ListTile(
                title: Text((data['businessName'] ?? data['ownerName'] ?? doc.id).toString()),
                subtitle: Text('verificationStatus: $status'),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    FilledButton(
                      onPressed: () => doc.reference.set({'verificationStatus': 'approved'}, SetOptions(merge: true)),
                      child: const Text('Approve'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => doc.reference.set({'verificationStatus': 'rejected'}, SetOptions(merge: true)),
                      child: const Text('Reject'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => doc.reference.set({'verificationStatus': 'suspended'}, SetOptions(merge: true)),
                      child: const Text('Suspend'),
                    ),
                  ],
                ),
              );
            }).toList(),
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (error, _) => [Text(error.toString())],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _countTile(String label, int count) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      ),
    );
  }
}
