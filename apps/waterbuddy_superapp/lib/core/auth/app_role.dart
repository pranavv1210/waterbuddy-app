import '../constants/app_constants.dart';

enum AppRole {
  consumer(AppConstants.consumerRole, 'Consumer'),
  seller(AppConstants.sellerRole, 'Tanker Owner'),
  driver(AppConstants.driverRole, 'Driver'),
  admin(AppConstants.adminRole, 'Admin');

  const AppRole(this.value, this.label);

  final String value;
  final String label;

  static AppRole? fromValue(String? value) {
    for (final role in AppRole.values) {
      if (role.value == value ||
          (role == AppRole.consumer && value == 'customer')) {
        return role;
      }
    }
    return null;
  }
}
