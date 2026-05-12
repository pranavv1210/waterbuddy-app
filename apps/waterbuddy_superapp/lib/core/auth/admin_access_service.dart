import 'package:firebase_auth/firebase_auth.dart';

class AdminAccessService {
  const AdminAccessService();

  bool isAuthorizedAdmin(User user) {
    final uidAllowed = _csvSet(const String.fromEnvironment('ADMIN_UIDS'));
    final emailAllowed = _csvSet(const String.fromEnvironment('ADMIN_EMAILS'));
    final phoneAllowed = _csvSet(const String.fromEnvironment('ADMIN_PHONES'));

    return uidAllowed.contains(user.uid) ||
        (user.email != null && emailAllowed.contains(user.email!.trim().toLowerCase())) ||
        (user.phoneNumber != null &&
            phoneAllowed.contains(user.phoneNumber!.trim().toLowerCase()));
  }

  Set<String> _csvSet(String raw) {
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map((value) => value.toLowerCase())
        .toSet();
  }
}
