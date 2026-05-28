import 'package:cloud_firestore/cloud_firestore.dart';

class SystemSettings {
  const SystemSettings({
    required this.bookingsEnabled,
    required this.codEnabled,
    required this.cancellationCharge,
    required this.deliveryCharge,
    required this.dispatchRadiusKm,
    required this.supportNumber,
    required this.supportEmail,
    required this.serviceCity,
    required this.maintenanceMode,
  });

  factory SystemSettings.defaults() {
    return const SystemSettings(
      bookingsEnabled: true,
      codEnabled: true,
      cancellationCharge: 0,
      deliveryCharge: 0,
      dispatchRadiusKm: 10,
      supportNumber: '',
      supportEmail: 'waterbuddyapp.wb@gmail.com',
      serviceCity: 'Bengaluru',
      maintenanceMode: false,
    );
  }

  factory SystemSettings.fromMap(Map<String, dynamic>? data) {
    final defaults = SystemSettings.defaults();
    if (data == null) return defaults;
    return SystemSettings(
      bookingsEnabled:
          data['bookingsEnabled'] as bool? ?? defaults.bookingsEnabled,
      codEnabled: data['codEnabled'] as bool? ?? defaults.codEnabled,
      cancellationCharge:
          (data['cancellationCharge'] as num?) ?? defaults.cancellationCharge,
      deliveryCharge:
          (data['deliveryCharge'] as num?) ?? defaults.deliveryCharge,
      dispatchRadiusKm: (data['dispatchRadiusKm'] as num?)?.toDouble() ??
          defaults.dispatchRadiusKm,
      supportNumber:
          (data['supportNumber'] ?? defaults.supportNumber).toString(),
      supportEmail: (data['supportEmail'] ?? defaults.supportEmail).toString(),
      serviceCity: (data['serviceCity'] ?? defaults.serviceCity).toString(),
      maintenanceMode:
          data['maintenanceMode'] as bool? ?? defaults.maintenanceMode,
    );
  }

  final bool bookingsEnabled;
  final bool codEnabled;
  final num cancellationCharge;
  final num deliveryCharge;
  final double dispatchRadiusKm;
  final String supportNumber;
  final String supportEmail;
  final String serviceCity;
  final bool maintenanceMode;

  bool get serviceAvailable => bookingsEnabled && !maintenanceMode;

  Map<String, dynamic> toFirestore() {
    return {
      'bookingsEnabled': bookingsEnabled,
      'codEnabled': codEnabled,
      'cancellationCharge': cancellationCharge,
      'deliveryCharge': deliveryCharge,
      'dispatchRadiusKm': dispatchRadiusKm,
      'supportNumber': supportNumber,
      'supportEmail': supportEmail,
      'serviceCity': serviceCity,
      'maintenanceMode': maintenanceMode,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
