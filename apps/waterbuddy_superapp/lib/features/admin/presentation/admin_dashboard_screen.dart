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
              final status = (data['verificationStatus'] ?? data['kycStatus'] ?? '').toString();
              
              final docs = data['documents'] as Map<String, dynamic>?;
              final aadhaar = docs?['aadhaarUrl'] ?? data['aadhaarUploadUrl'];
              final dl = docs?['dlUrl'] ?? data['licenseUploadUrl'];
              final rc = docs?['rcUrl'] ?? data['vehicleRcUploadUrl'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (data['businessName'] ?? data['ownerName'] ?? data['name'] ?? doc.id).toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text('Status: $status'),
                      const SizedBox(height: 12),
                      const Text('KYC Documents:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (aadhaar != null && aadhaar.toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Column(
                                  children: [
                                    const Text('Aadhaar', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Image.network(aadhaar.toString(), width: 100, height: 100, fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(width: 100, height: 100, color: Colors.grey, child: const Icon(Icons.error))),
                                  ],
                                ),
                              ),
                            if (dl != null && dl.toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Column(
                                  children: [
                                    const Text('DL', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Image.network(dl.toString(), width: 100, height: 100, fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(width: 100, height: 100, color: Colors.grey, child: const Icon(Icons.error))),
                                  ],
                                ),
                              ),
                            if (rc != null && rc.toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Column(
                                  children: [
                                    const Text('RC', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Image.network(rc.toString(), width: 100, height: 100, fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(width: 100, height: 100, color: Colors.grey, child: const Icon(Icons.error))),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => doc.reference.set({'verificationStatus': 'approved', 'kycStatus': 'VERIFIED'}, SetOptions(merge: true)),
                            style: FilledButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Approve'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => doc.reference.set({'verificationStatus': 'rejected', 'kycStatus': 'REJECTED'}, SetOptions(merge: true)),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
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
