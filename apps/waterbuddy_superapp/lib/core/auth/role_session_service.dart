import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'app_role.dart';

class RoleSessionService {
  Future<AppRole?> getSelectedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return AppRole.fromValue(prefs.getString(AppConstants.roleStorageKey));
  }

  Future<void> setSelectedRole(AppRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.roleStorageKey, role.value);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.roleStorageKey);
  }
}
