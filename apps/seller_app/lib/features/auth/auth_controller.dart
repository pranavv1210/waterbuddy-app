import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth/auth_service.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.verificationId,
    this.phoneNumber,
    this.errorMessage,
    this.successMessage,
    this.isVerified = false,
  });

  final bool isLoading;
  final String? verificationId;
  final String? phoneNumber;
  final String? errorMessage;
  final String? successMessage;
  final bool isVerified;

  bool get isCodeSent => verificationId != null;

  AuthState copyWith({
    bool? isLoading,
    String? verificationId,
    String? phoneNumber,
    String? errorMessage,
    String? successMessage,
    bool? isVerified,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearVerificationId = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      verificationId:
          clearVerificationId ? null : verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authService) : super(const AuthState());

  final AuthService _authService;

  Future<bool> sendOtp(String inputPhoneNumber) async {
    final sanitized = _normalizePhoneNumber(inputPhoneNumber);
    if (sanitized == null) {
      state = state.copyWith(
        errorMessage: 'Enter a valid phone number.',
        clearSuccess: true,
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      phoneNumber: sanitized,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final verificationId = await _authService.sendOtp(
        phoneNumber: sanitized,
        onVerificationCompleted: (credential) async {
          final user = credential.user;
          if (user == null) {
            return;
          }

          await _authService.createUserIfMissing(
            uid: user.uid,
            phone: user.phoneNumber ?? sanitized,
            role: AppConstants.sellerRole,
          );

          state = state.copyWith(
            isLoading: false,
            isVerified: true,
            successMessage: 'Phone verified successfully.',
            clearError: true,
          );
        },
      );

      state = state.copyWith(
        isLoading: false,
        verificationId: verificationId,
        successMessage: 'OTP sent successfully.',
        clearError: true,
      );
      return true;
    } on AuthFailure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        clearSuccess: true,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to send OTP right now. Please try again.',
        clearSuccess: true,
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String smsCode) async {
    final verificationId = state.verificationId;
    final phone = state.phoneNumber;

    if (verificationId == null || phone == null) {
      state = state.copyWith(
        errorMessage: 'OTP session expired. Please request OTP again.',
        clearSuccess: true,
      );
      return false;
    }

    final code = smsCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      state = state.copyWith(
        errorMessage: 'Enter a valid 6-digit OTP.',
        clearSuccess: true,
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final credential = await _authService.verifyOtp(
        verificationId: verificationId,
        smsCode: code,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Unable to sign in. Please try again.');
      }

      await _authService.createUserIfMissing(
        uid: user.uid,
        phone: user.phoneNumber ?? phone,
        role: AppConstants.sellerRole,
      );

      state = state.copyWith(
        isLoading: false,
        isVerified: true,
        successMessage: 'Login successful.',
        clearError: true,
      );
      return true;
    } on AuthFailure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        clearSuccess: true,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to verify OTP. Please try again.',
        clearSuccess: true,
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  String? _normalizePhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'\s+|-'), '');
    if (cleaned.startsWith('+') && cleaned.length >= 11) {
      return cleaned;
    }

    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      return '+91$digits';
    }

    return null;
  }
}
