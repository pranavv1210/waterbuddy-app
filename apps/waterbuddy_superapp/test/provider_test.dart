import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterbuddy_superapp/core/auth/app_role.dart';
import 'package:waterbuddy_superapp/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Riverpod State Providers Tests', () {
    test('selectedRoleProvider starts as null and updates correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initially null (before restore completes or if no saved role)
      expect(container.read(selectedRoleProvider), isNull);

      // Select a role and verify
      await container.read(selectedRoleProvider.notifier).set(AppRole.consumer);
      expect(container.read(selectedRoleProvider), equals(AppRole.consumer));
    });
  });
}
