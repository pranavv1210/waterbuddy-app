import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Stream<User?> authStateChanges() => _auth.authStateChanges();

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

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (exception) {
      throw AuthFailure(_authErrorMessage(exception));
    }
  }

  Future<void> createUserIfMissing({
    required String uid,
    required String phone,
    required String role,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        return;
      }

      await userRef.set({
        'id': uid,
        'phone': phone,
        'role': role,
      });
    } on FirebaseException catch (exception) {
      throw AuthFailure(
        exception.message ?? 'Unable to save user profile. Please try again.',
      );
    }
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
