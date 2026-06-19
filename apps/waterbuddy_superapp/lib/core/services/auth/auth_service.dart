import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../auth/app_role.dart';
import '../../auth/admin_access_service.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  AuthService(this._auth, this._firestore, this._adminAccessService);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AdminAccessService _adminAccessService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '979686341816-gi2haph462optrduomb8m8rqm99jfc54.apps.googleusercontent.com',
  );
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle({
    required AppRole role,
    String? phoneNumber,
  }) async {
    try {
      final googleUser = await _googleSignIn.signIn().timeout(
            const Duration(seconds: 12),
          );
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 8),
      );
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await _auth.signInWithCredential(credential).timeout(
                const Duration(seconds: 10),
              );
      unawaited(
        upsertUserProfile(
          role: role,
          phoneNumber: phoneNumber,
          authProvider: 'google',
          isVerified: true,
        ).catchError((_) {}),
      );
      return userCredential;
    } on TimeoutException {
      throw const AuthFailure(
        'Google sign-in timed out. Check the Google setup and try again.',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authErrorMessage(e));
    } catch (_) {
      throw const AuthFailure('Google sign-in failed. Please try again.');
    }
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const AuthFailure(
          'Login timed out. Check your connection and try again.');
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authErrorMessage(e));
    }
  }

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth
          .createUserWithEmailAndPassword(
              email: email.trim(), password: password)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const AuthFailure(
          'Signup timed out. Check your connection and try again.');
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authErrorMessage(e));
    }
  }

  Future<String> sendOtp({
    required String phoneNumber,
    Duration timeout = const Duration(seconds: 60),
    Future<void> Function(UserCredential credential)? onVerificationCompleted,
  }) async {
    final completer = Completer<String>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        timeout: timeout,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            await onVerificationCompleted?.call(userCredential);
          } catch (_) {
            if (!completer.isCompleted) {
              completer.completeError(
                const AuthFailure(
                  'Auto verification failed. Enter the OTP manually.',
                ),
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException exception) {
          if (!completer.isCompleted) {
            completer.completeError(AuthFailure(_authErrorMessage(exception)));
          }
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );

      return await completer.future.timeout(
        timeout + const Duration(seconds: 5),
        onTimeout: () => throw const AuthFailure(
          'OTP request timed out. Please try again.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authErrorMessage(e));
    }
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      return await _auth.signInWithCredential(credential).timeout(
            const Duration(seconds: 12),
          );
    } on TimeoutException {
      throw const AuthFailure(
        'OTP verification timed out. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authErrorMessage(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authErrorMessage(e));
    }
  }

  Future<void> upsertUserProfile({
    required AppRole role,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? authProvider,
    bool? isVerified,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('User not authenticated.');
    }

    if (role == AppRole.admin && !await isAuthorizedAdmin(user)) {
      await signOut();
      throw const AuthFailure('Unauthorized access');
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();
    await userRef.set({
      'uid': user.uid,
      'role': role.value,
      'fullName': fullName ?? user.displayName,
      'displayName': fullName ?? user.displayName,
      'email': email ?? user.email,
      'phoneNumber': phoneNumber ?? user.phoneNumber,
      'photoUrl': photoUrl ?? user.photoURL,
      'authProvider': authProvider,
      'isVerified': isVerified ?? false,
      'createdAt': now,
      'isBlocked': false,
    }, SetOptions(merge: true));

    if (role == AppRole.seller) {
      await _firestore.collection('sellers').doc(user.uid).set({
        'uid': user.uid,
        'ownerName': fullName ?? user.displayName,
        'email': email ?? user.email,
        'phoneNumber': phoneNumber ?? user.phoneNumber,
        'isOnline': false,
        'verificationStatus': 'pending',
        'createdAt': now,
      }, SetOptions(merge: true));
    }

    if (role == AppRole.driver) {
      await _firestore.collection('drivers').doc(user.uid).set({
        'uid': user.uid,
        'driverName': fullName ?? user.displayName,
        'email': email ?? user.email,
        'phone': phoneNumber ?? user.phoneNumber,
        'isOnline': false,
        'verificationStatus': 'pending',
        'createdAt': now,
      }, SetOptions(merge: true));
    }

    if (role == AppRole.admin) {
      await _firestore.collection('admins').doc(user.uid).set({
        'uid': user.uid,
        'role': 'admin',
        'accessLevel': 'super',
        'createdAt': now,
      }, SetOptions(merge: true));
    }
  }

  Future<void> upsertSellerProfile({
    required String fullName,
    required String companyName,
    required String phoneNumber,
    required String email,
    required String address,
    required String aadhaarNumber,
    required String tankerCapacity,
    required String tankerVehicleNumber,
    required String licenseUrl,
    required String aadhaarUrl,
    required String rcUrl,
    required String tankerPhotoUrls,
    String? panNumber,
    String? panUploadUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('User not authenticated.');
    final now = FieldValue.serverTimestamp();
    await upsertUserProfile(
      role: AppRole.seller,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      authProvider: 'email_password',
      isVerified: true,
    );
    await _firestore.collection('sellers').doc(user.uid).set({
      'uid': user.uid,
      'ownerName': fullName,
      'businessName': companyName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'aadhaarNumber': aadhaarNumber,
      'panNumber': panNumber,
      'tankerCapacity': tankerCapacity,
      'vehicleNumber': tankerVehicleNumber,
      'licenseUploadUrl': licenseUrl,
      'aadhaarUploadUrl': aadhaarUrl,
      'panUploadUrl': panUploadUrl,
      'vehicleRcUploadUrl': rcUrl,
      'tankerPhotosUrl': tankerPhotoUrls,
      'verificationStatus': 'pending',
      'isOnline': false,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> upsertDriverProfile({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String licenseNumber,
    required String aadhaarNumber,
    required String driverPhotoUrl,
    required String licenseUploadUrl,
    required String aadhaarUploadUrl,
    required String address,
    required String emergencyContact,
    String? panNumber,
    String? panUploadUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('User not authenticated.');
    final now = FieldValue.serverTimestamp();
    await upsertUserProfile(
      role: AppRole.driver,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      authProvider: 'otp',
      isVerified: true,
    );
    await _firestore.collection('drivers').doc(user.uid).set({
      'uid': user.uid,
      'driverName': fullName,
      'phone': phoneNumber,
      'email': email,
      'driverLicenseNumber': licenseNumber,
      'aadhaarNumber': aadhaarNumber,
      'panNumber': panNumber,
      'driverPhotoUrl': driverPhotoUrl,
      'licenseUploadUrl': licenseUploadUrl,
      'aadhaarUploadUrl': aadhaarUploadUrl,
      'panUploadUrl': panUploadUrl,
      'address': address,
      'emergencyContact': emergencyContact,
      'verificationStatus': 'pending',
      'isOnline': false,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> upsertOwnerDriverProfile({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String licenseNumber,
    required String aadhaarNumber,
    required String driverPhotoUrl,
    required String licenseUploadUrl,
    required String aadhaarUploadUrl,
    required String address,
    String? panNumber,
    String? panUploadUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('User not authenticated.');

    final now = FieldValue.serverTimestamp();
    await _firestore.collection('drivers').doc(user.uid).set({
      'uid': user.uid,
      'sellerId': user.uid,
      'driverName': fullName,
      'phone': phoneNumber,
      'email': email,
      'driverLicenseNumber': licenseNumber,
      'aadhaarNumber': aadhaarNumber,
      'panNumber': panNumber,
      'driverPhotoUrl': driverPhotoUrl,
      'licenseUploadUrl': licenseUploadUrl,
      'aadhaarUploadUrl': aadhaarUploadUrl,
      'panUploadUrl': panUploadUrl,
      'address': address,
      'ownerDriver': true,
      'verificationStatus': 'pending',
      'isOnline': false,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<String?> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  Future<String> getSellerVerificationStatus(String uid) async {
    final doc = await _firestore.collection('sellers').doc(uid).get();
    final data = doc.data();
    final value = (data?['verificationStatus'] ?? data?['kycStatus'])
        ?.toString()
        .toLowerCase();
    if (value == null || value.isEmpty) return 'pending';
    if (value == 'submitted' || value == 'review' || value == 'under_review') {
      return 'pending';
    }
    if (value == 'verified') return 'approved';
    return value;
  }

  Future<bool> isAuthorizedAdmin(User user) async {
    if (!_adminAccessService.isAuthorizedAdmin(user)) return false;
    if (user.email == 'waterbuddyapp.wb@gmail.com' ||
        user.email == 'admin@waterbuddy.com') {
      return true;
    }
    final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
    return adminDoc.exists;
  }

  Future<bool> isBlocked(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['isBlocked'] as bool? ?? false;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
  String _authErrorMessage(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check the code and try again.';
      case 'session-expired':
        return 'OTP has expired. Please request a new code.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return exception.message ?? 'Authentication failed. Please try again.';
    }
  }
}
