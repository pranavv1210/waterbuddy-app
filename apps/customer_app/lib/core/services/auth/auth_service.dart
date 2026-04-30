import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Check GoogleSignIn implementation:
      // Ensure: final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // Handle cancellation gracefully
      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled by user.');
        return null;
      }

      // 2. Then:
      // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Then:
      // final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,);
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Then:
      // await FirebaseAuth.instance.signInWithCredential(credential);
      final userCredential = await _auth.signInWithCredential(credential);
      
      final user = userCredential.user;
      if (user != null) {
        await createUserInFirestore();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint(e.toString());
      throw AuthFailure(_authErrorMessage(e));
    } catch (e) {
      debugPrint(e.toString());
      throw AuthFailure('Google sign-in failed. Please try again.');
    }
  }

  Future<void> signInWithPhone({
    required String phoneNumber,
    required PhoneCodeSent codeSent,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      codeSent: codeSent,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<String> sendOtp({
    required String phoneNumber,
    Duration timeout = const Duration(seconds: 60),
    Future<void> Function(UserCredential credential)? onVerificationCompleted,
  }) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: (credential) async {
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          if (onVerificationCompleted != null) {
            await onVerificationCompleted(userCredential);
          }
        } on FirebaseAuthException catch (exception) {
          if (!completer.isCompleted) {
            completer.completeError(AuthFailure(_authErrorMessage(exception)));
          }
        }
      },
      verificationFailed: (exception) {
        if (!completer.isCompleted) {
          completer.completeError(AuthFailure(_authErrorMessage(exception)));
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        await createUserInFirestore();
      }
      
      return userCredential;
    } on FirebaseAuthException catch (exception) {
      throw AuthFailure(_authErrorMessage(exception));
    }
  }

  Future<void> createUserInFirestore() async {
    try {
      // 1. Get current user
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return;
      }

      final uid = user.uid;

      // 2. Check Firestore
      final userRef = _firestore.collection('users').doc(uid);
      final snapshot = await userRef.get();

      // 3. IF document does NOT exist: Create user
      if (!snapshot.exists) {
        final userData = {
          'uid': uid,
          'phone': user.phoneNumber,
          'email': user.email,
          'name': user.displayName,
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await userRef.set(userData);
        debugPrint('User created');
      } else {
        // 4. IF document exists: Do NOT overwrite, optionally update missing fields
        final existingData = snapshot.data() ?? {};
        final Map<String, dynamic> updates = {};

        // Only update fields that are missing in Firestore but available in Auth
        if (existingData['phone'] == null && user.phoneNumber != null) {
          updates['phone'] = user.phoneNumber;
        }
        if (existingData['email'] == null && user.email != null) {
          updates['email'] = user.email;
        }
        if (existingData['name'] == null && user.displayName != null) {
          updates['name'] = user.displayName;
        }
        if (existingData['photoUrl'] == null && user.photoURL != null) {
          updates['photoUrl'] = user.photoURL;
        }

        if (updates.isNotEmpty) {
          await userRef.update(updates);
        }
        debugPrint('User exists');
      }
    } on FirebaseException catch (exception) {
      debugPrint('Firestore error: ${exception.message}');
      throw AuthFailure(
        exception.message ?? 'Unable to save user profile. Please try again.',
      );
    } catch (e) {
      debugPrint('Unexpected error in createUserInFirestore: $e');
      throw AuthFailure('Unable to save user profile. Please try again.');
    }
  }

  Future<void> createUserIfMissing({
    required String uid,
    required String phone,
    required String role,
  }) async {
    await createUserInFirestore();
  }

  Future<void> signOut() => _auth.signOut();

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
      case 'quota-exceeded':
        return 'OTP quota exceeded. Please try again later.';
      default:
        return exception.message ?? 'Authentication failed. Please try again.';
    }
  }
}
