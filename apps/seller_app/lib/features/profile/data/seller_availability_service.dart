import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SellerAvailabilityService {
  SellerAvailabilityService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> setAvailability(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    debugPrint('Setting seller availability: $isOnline for user: ${user.uid}');

    await _firestore.collection('sellers').doc(user.uid).set({
      'isOnline': isOnline,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('Seller availability updated successfully');
  }

  Stream<bool> watchAvailability(String sellerId) {
    return _firestore
        .collection('sellers')
        .doc(sellerId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data() as Map<String, dynamic>;
      return data['isOnline'] as bool? ?? false;
    });
  }

  Future<bool> isOnline(String sellerId) async {
    final doc = await _firestore.collection('sellers').doc(sellerId).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    return data['isOnline'] as bool? ?? false;
  }
}
