import 'package:cloud_firestore/cloud_firestore.dart';

class TankCategory {
  const TankCategory({
    required this.id,
    required this.displayName,
    required this.litres,
    required this.basePrice,
    required this.surgeMultiplier,
    required this.iconKey,
    required this.active,
    required this.displayOrder,
    required this.serviceRadius,
    required this.expressAvailable,
    required this.nightCharge,
    required this.extraDistanceCharge,
    required this.description,
  });

  factory TankCategory.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TankCategory(
      id: doc.id,
      displayName: (data['name'] ?? data['displayName'] ?? doc.id).toString(),
      litres: (data['litres'] as num?)?.toInt() ?? 0,
      basePrice: (data['price'] ?? data['basePrice'] as num?) ?? 0,
      surgeMultiplier: (data['surgeMultiplier'] as num?)?.toDouble() ?? 1,
      iconKey: _normalizeIconType(
        (data['iconType'] ?? data['iconKey'] ?? 'drop').toString(),
      ),
      active: (data['isActive'] ?? data['active']) as bool? ?? true,
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 999,
      serviceRadius: (data['serviceRadius'] as num?)?.toDouble() ?? 5,
      expressAvailable: data['expressAvailable'] as bool? ?? true,
      nightCharge: (data['nightCharge'] as num?) ?? 0,
      extraDistanceCharge: (data['extraDistanceCharge'] as num?) ?? 0,
      description: (data['description'] ?? '').toString(),
    );
  }

  final String id;
  final String displayName;
  final int litres;
  final num basePrice;
  final double surgeMultiplier;
  final String iconKey;
  final bool active;
  final int displayOrder;
  final double serviceRadius;
  final bool expressAvailable;
  final num nightCharge;
  final num extraDistanceCharge;
  final String description;

  num get effectivePrice => (basePrice * surgeMultiplier).round();
  String get iconType => iconKey;

  static String _normalizeIconType(String value) {
    switch (value) {
      case 'opacity':
      case 'water_drop':
      case 'drop':
        return 'drop';
      case 'truck':
      case 'tanker':
        return 'tanker';
      case 'waves':
      case 'water':
        return 'water';
      default:
        return 'drop';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'name': displayName,
      'litres': litres,
      'basePrice': basePrice,
      'price': basePrice,
      'surgeMultiplier': surgeMultiplier,
      'iconKey': iconKey,
      'iconType': iconType,
      'active': active,
      'isActive': active,
      'displayOrder': displayOrder,
      'serviceRadius': serviceRadius,
      'expressAvailable': expressAvailable,
      'nightCharge': nightCharge,
      'extraDistanceCharge': extraDistanceCharge,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
