import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../providers/app_providers.dart';
import '../models/home_dashboard.dart';

class HomeDashboardController extends StateNotifier<HomeDashboard> {
  HomeDashboardController(this._auth, this._firestore)
      : super(const HomeDashboard(
          brandName: 'WaterBuddy',
          userName: 'Loading...',
          userAvatarUrl: '',
          heroBadgeLabel: 'Set delivery point',
          mapImageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCC0t58EFVl-jJwFWMSegJqXIkOykl4aieFbREjMvSfCHqOZXspE3Ir3tkeFd4tsAh6L-VrP4UmC3vHU8tZ-SWPQpdG_Fklv7V1nGJhdBhXSs8adVwv776yEPaHgSJb7rVUlVsJR8nEGuiPqWzYJ7I3gprtxxzxGjVH-RwPlYttcYg-DkvSktCr9THVB7pWv4kUFV8qPXMp0Y2BMKZZN2Qj6prGSdzXYYPEg_HXA_TRYsnh41F7rFhCXGwsJkAyDI4OF6jOKmcZb-w',
          mapImageAlt: 'Map view',
          capacityTitle: 'Select Tank Capacity',
          capacitySubtitle: 'High-quality spring water delivered to your doorstep.',
          tankOptions: [
            TankOption(
              id: 'small',
              label: 'Small',
              capacityLabel: '10,000L',
              priceLabel: '\$120',
              iconKey: 'opacity',
            ),
            TankOption(
              id: 'medium',
              label: 'Medium',
              capacityLabel: '15,000L',
              priceLabel: '\$165',
              iconKey: 'water_drop',
              isRecommended: true,
            ),
            TankOption(
              id: 'large',
              label: 'Large',
              capacityLabel: '20,000L',
              priceLabel: '\$210',
              iconKey: 'waves',
            ),
          ],
          bottomNavItems: [
            BottomNavItemData(id: 'home', label: 'Home', iconKey: 'home'),
            BottomNavItemData(id: 'history', label: 'History', iconKey: 'history'),
            BottomNavItemData(id: 'book', label: 'Book Now', iconKey: 'water_drop'),
            BottomNavItemData(id: 'profile', label: 'Profile', iconKey: 'person'),
          ],
        )) {
    _loadUserData();
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(userName: 'Guest');
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData != null) {
        state = state.copyWith(
          userName: userData['name'] as String? ?? 'User',
          userAvatarUrl: userData['avatarUrl'] as String? ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }
}

final homeDashboardControllerProvider =
    StateNotifierProvider<HomeDashboardController, HomeDashboard>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return HomeDashboardController(auth, firestore);
});

final homeDashboardProvider = Provider<HomeDashboard>((ref) {
  return ref.watch(homeDashboardControllerProvider);
});

final selectedTankIdProvider = StateProvider<String?>((ref) => null);
