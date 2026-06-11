import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/document_upload_field.dart';
import '../../../widgets/loading_feedback_button.dart';
import '../../../widgets/premium_ui.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';
import '../../../widgets/waterbuddy_toast.dart';
import '../../../features/auth/auth_controller.dart';

class DriverSignupScreen extends ConsumerStatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  ConsumerState<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends ConsumerState<DriverSignupScreen> {
  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());
  int _currentStep = 0;

  // Step 1 – Personal
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _emergency = TextEditingController();

  // Step 2 – License & Docs
  final _licenseNumber = TextEditingController();
  final _aadhaar = TextEditingController();
  final _pan = TextEditingController();
  final _driverPhoto = TextEditingController();
  final _licenseUpload = TextEditingController();
  final _aadhaarUpload = TextEditingController();
  final _panUpload = TextEditingController();

  // Step 3 – Phone / OTP
  final _mobile = TextEditingController();
  LoadingButtonState _btnState = LoadingButtonState.idle;

  static const _stepLabels = [
    'Personal Info',
    'Documents',
    'Verify Phone',
  ];

  @override
  void dispose() {
    for (final c in [
      _fullName, _email, _address, _emergency,
      _licenseNumber, _aadhaar, _pan, _driverPhoto,
      _licenseUpload, _aadhaarUpload, _panUpload,
      _mobile,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (!_formKeys[_currentStep].currentState!.validate()) return;
    HapticFeedback.selectionClick();
    setState(() => _currentStep++);
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        WaterBuddyToast.show(context, next.errorMessage!, isError: true);
      }
    });

    return WaterBuddyAuthLayout(
      activeRole: AppRole.driver,
      title: 'Driver Registration',
      subtitle: _stepLabels[_currentStep],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WbStepIndicator(
            currentStep: _currentStep,
            totalSteps: _stepLabels.length,
            accentColor: const Color(0xFF6366F1),
            stepLabels: _stepLabels,
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            child: _buildStep(_currentStep, authState),
          ),
          const SizedBox(height: 20),
          _buildNavButtons(authState),
        ],
      ),
    );
  }

  Widget _buildStep(int step, AuthState authState) {
    switch (step) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            key: const ValueKey(0),
            children: [
              WbPremiumTextField(
                controller: _fullName,
                label: 'Full Name',
                icon: Icons.person_rounded,
                accentColor: const Color(0xFF6366F1),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _email,
                label: 'Email Address',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                accentColor: const Color(0xFF6366F1),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _address,
                label: 'Residential Address',
                icon: Icons.location_on_rounded,
                accentColor: const Color(0xFF6366F1),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _emergency,
                label: 'Emergency Contact',
                icon: Icons.contact_phone_rounded,
                keyboardType: TextInputType.phone,
                accentColor: const Color(0xFF6366F1),
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKeys[1],
          child: Column(
            key: const ValueKey(1),
            children: [
              WbPremiumTextField(
                controller: _licenseNumber,
                label: 'Driver License Number',
                icon: Icons.card_membership_rounded,
                accentColor: const Color(0xFF6366F1),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _aadhaar,
                label: 'Aadhaar Number',
                icon: Icons.badge_rounded,
                keyboardType: TextInputType.number,
                accentColor: const Color(0xFF6366F1),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _pan,
                label: 'PAN Number',
                icon: Icons.credit_card_rounded,
                accentColor: const Color(0xFF6366F1),
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DocumentUploadField(
                controller: _driverPhoto,
                label: 'Driver Photo',
                themeColor: const Color(0xFF6366F1),
                isPhoto: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _licenseUpload,
                label: 'Driver License Document',
                themeColor: const Color(0xFF6366F1),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _aadhaarUpload,
                label: 'Aadhaar Document',
                themeColor: const Color(0xFF6366F1),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _panUpload,
                label: 'PAN Document',
                themeColor: const Color(0xFF6366F1),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        );
      case 2:
      default:
        return Form(
          key: _formKeys[2],
          child: Column(
            key: const ValueKey(2),
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.18)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: Color(0xFF6366F1), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "We'll send a one-time OTP to verify your identity",
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              WbPremiumTextField(
                controller: _mobile,
                label: 'Mobile Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                accentColor: const Color(0xFF6366F1),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 10) return 'Enter valid 10-digit number';
                  return null;
                },
              ),
            ],
          ),
        );
    }
  }

  Widget _buildNavButtons(AuthState authState) {
    final isLast = _currentStep == _stepLabels.length - 1;
    final btnState = authState.isLoading
        ? LoadingButtonState.loading
        : _btnState;

    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: WbColors.ink,
                side: const BorderSide(color: WbColors.line),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        WaterBuddyDesignSystem.radiusPill)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: isLast ? 1 : 2,
          child: isLast
              ? LoadingFeedbackButton(
                  onPressed: btnState == LoadingButtonState.idle
                      ? _sendOtp
                      : null,
                  label: 'Send OTP & Verify',
                  loadingLabel: 'Sending OTP...',
                  successLabel: 'OTP Sent!',
                  buttonState: btnState,
                  backgroundColor: const Color(0xFF6366F1),
                )
              : FilledButton.icon(
                  onPressed: _nextStep,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Next'),
                  style: FilledButton.styleFrom(
                    backgroundColor: WbColors.ink,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            WaterBuddyDesignSystem.radiusPill)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKeys[2].currentState!.validate()) return;
    setState(() => _btnState = LoadingButtonState.loading);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(_mobile.text.trim(), role: AppRole.driver);
    if (!ok || !mounted) {
      setState(() => _btnState = LoadingButtonState.idle);
      return;
    }
    setState(() => _btnState = LoadingButtonState.success);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    context.push(
      RouteNames.authDriverOtp,
      extra: {
        'fullName': _fullName.text.trim(),
        'phoneNumber': _mobile.text.trim(),
        'email': _email.text.trim(),
        'licenseNumber': _licenseNumber.text.trim(),
        'aadhaarNumber': _aadhaar.text.trim(),
        'panNumber': _pan.text.trim(),
        'driverPhotoUrl': _driverPhoto.text.trim(),
        'licenseUploadUrl': _licenseUpload.text.trim(),
        'aadhaarUploadUrl': _aadhaarUpload.text.trim(),
        'panUploadUrl': _panUpload.text.trim(),
        'address': _address.text.trim(),
        'emergencyContact': _emergency.text.trim(),
        'isSignUp': true,
      },
    );
    setState(() => _btnState = LoadingButtonState.idle);
  }
}
