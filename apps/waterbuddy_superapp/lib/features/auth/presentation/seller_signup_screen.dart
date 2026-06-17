import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/document_upload_field.dart';
import '../../../widgets/loading_feedback_button.dart';
import '../../../widgets/premium_ui.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';
import '../../../widgets/waterbuddy_toast.dart';

class SellerSignupScreen extends ConsumerStatefulWidget {
  const SellerSignupScreen({super.key});

  @override
  ConsumerState<SellerSignupScreen> createState() => _SellerSignupScreenState();
}

class _SellerSignupScreenState extends ConsumerState<SellerSignupScreen> {
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  int _currentStep = 0;

  // Step 1 – Personal
  final _fullName = TextEditingController();
  final _companyName = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();

  // Step 2 – Account
  final _email = TextEditingController();
  final _password = TextEditingController();

  // Step 3 – Tanker
  final _capacity = TextEditingController();
  final _vehicle = TextEditingController();
  final _aadhaar = TextEditingController();
  final _pan = TextEditingController();

  // Step 4 – Documents
  final _licenseUrl = TextEditingController();
  final _aadhaarUrl = TextEditingController();
  final _panUrl = TextEditingController();
  final _rcUrl = TextEditingController();
  final _photoUrl = TextEditingController();

  bool _drivesSelf = true;
  bool _assignDrivers = false;
  LoadingButtonState _btnState = LoadingButtonState.idle;

  static const _stepLabels = [
    'Personal Info',
    'Account Setup',
    'Tanker Details',
    'Documents',
  ];

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _companyName,
      _mobile,
      _address,
      _email,
      _password,
      _capacity,
      _vehicle,
      _aadhaar,
      _pan,
      _licenseUrl,
      _aadhaarUrl,
      _panUrl,
      _rcUrl,
      _photoUrl,
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
    return WaterBuddyAuthLayout(
      activeRole: AppRole.seller,
      title: 'Tanker Owner Registration',
      subtitle: _stepLabels[_currentStep],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WbStepIndicator(
            currentStep: _currentStep,
            totalSteps: _stepLabels.length,
            accentColor: const Color(0xFF14B8A6),
            stepLabels: _stepLabels,
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
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
            child: _buildStep(_currentStep),
          ),
          const SizedBox(height: 20),
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            key: const ValueKey(0),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WbPremiumTextField(
                controller: _fullName,
                label: 'Full Name',
                icon: Icons.person_rounded,
                accentColor: const Color(0xFF14B8A6),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _companyName,
                label: 'Company Name (optional)',
                icon: Icons.business_rounded,
                accentColor: const Color(0xFF14B8A6),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _mobile,
                label: 'Mobile Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                accentColor: const Color(0xFF14B8A6),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _address,
                label: 'Business Address',
                icon: Icons.location_on_rounded,
                accentColor: const Color(0xFF14B8A6),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WbPremiumTextField(
                controller: _email,
                label: 'Email Address',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                accentColor: const Color(0xFF14B8A6),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _password,
                label: 'Password',
                icon: Icons.lock_rounded,
                obscureText: true,
                accentColor: const Color(0xFF14B8A6),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Driver setup
              _ToggleChip(
                label: 'I drive myself',
                icon: Icons.drive_eta_rounded,
                value: _drivesSelf,
                accentColor: const Color(0xFF14B8A6),
                onChanged: (v) => setState(() => _drivesSelf = v),
              ),
              const SizedBox(height: 10),
              _ToggleChip(
                label: 'I assign drivers',
                icon: Icons.people_rounded,
                value: _assignDrivers,
                accentColor: const Color(0xFF14B8A6),
                onChanged: (v) => setState(() => _assignDrivers = v),
              ),
            ],
          ),
        );
      case 2:
        return Form(
          key: _formKeys[2],
          child: Column(
            key: const ValueKey(2),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WbPremiumTextField(
                controller: _capacity,
                label: 'Tanker Capacity (Litres)',
                icon: Icons.water_drop_rounded,
                keyboardType: TextInputType.number,
                accentColor: const Color(0xFF14B8A6),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _vehicle,
                label: 'Vehicle Number',
                icon: Icons.local_shipping_rounded,
                accentColor: const Color(0xFF14B8A6),
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
                accentColor: const Color(0xFF14B8A6),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              WbPremiumTextField(
                controller: _pan,
                label: 'PAN Number',
                icon: Icons.credit_card_rounded,
                accentColor: const Color(0xFF14B8A6),
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        );
      case 3:
      default:
        return Form(
          key: _formKeys[3],
          child: Column(
            key: const ValueKey(3),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DocumentUploadField(
                controller: _licenseUrl,
                label: 'Driver License',
                themeColor: const Color(0xFF14B8A6),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _aadhaarUrl,
                label: 'Aadhaar Card',
                themeColor: const Color(0xFF14B8A6),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _panUrl,
                label: 'PAN Card',
                themeColor: const Color(0xFF14B8A6),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _rcUrl,
                label: 'Vehicle RC',
                themeColor: const Color(0xFF14B8A6),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _photoUrl,
                label: 'Tanker Photos',
                themeColor: const Color(0xFF14B8A6),
                isPhoto: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildNavButtons() {
    final isLast = _currentStep == _stepLabels.length - 1;
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back, size: 18),
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
                  onPressed:
                      _btnState == LoadingButtonState.idle ? _submit : null,
                  label: 'Register Tanker',
                  loadingLabel: 'Registering...',
                  successLabel: 'Registered!',
                  buttonState: _btnState,
                  backgroundColor: const Color(0xFF14B8A6),
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

  Future<void> _submit() async {
    if (!_formKeys[3].currentState!.validate()) return;
    if (!_drivesSelf && !_assignDrivers) {
      WaterBuddyToastService.warning(
          context, 'Select how this tanker will be driven.');
      return;
    }
    setState(() => _btnState = LoadingButtonState.loading);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signUpWithEmailPassword(
          email: _email.text.trim(), password: _password.text.trim());
      unawaited(_syncSellerProfile(auth).catchError((_) {}));
      setState(() => _btnState = LoadingButtonState.success);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) context.go(RouteNames.sellerWaiting);
    } on AuthFailure catch (e) {
      setState(() => _btnState = LoadingButtonState.idle);
      if (mounted) WaterBuddyToastService.error(context, e.message);
    } catch (_) {
      setState(() => _btnState = LoadingButtonState.idle);
      if (mounted) {
        WaterBuddyToastService.error(
            context, 'Registration failed. Try again.');
      }
    }
  }

  Future<void> _syncSellerProfile(AuthService auth) async {
    await auth.upsertSellerProfile(
      fullName: _fullName.text.trim(),
      companyName: _companyName.text.trim(),
      phoneNumber: _mobile.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      aadhaarNumber: _aadhaar.text.trim(),
      tankerCapacity: _capacity.text.trim(),
      tankerVehicleNumber: _vehicle.text.trim(),
      licenseUrl: _licenseUrl.text.trim(),
      aadhaarUrl: _aadhaarUrl.text.trim(),
      rcUrl: _rcUrl.text.trim(),
      tankerPhotoUrls: _photoUrl.text.trim(),
      panNumber: _pan.text.trim(),
      panUploadUrl: _panUrl.text.trim(),
    );
    if (!_drivesSelf) return;
    await auth.upsertOwnerDriverProfile(
      fullName: _fullName.text.trim(),
      phoneNumber: _mobile.text.trim(),
      email: _email.text.trim(),
      licenseNumber: _vehicle.text.trim(),
      aadhaarNumber: _aadhaar.text.trim(),
      driverPhotoUrl: _photoUrl.text.trim(),
      licenseUploadUrl: _licenseUrl.text.trim(),
      aadhaarUploadUrl: _aadhaarUrl.text.trim(),
      address: _address.text.trim(),
      panNumber: _pan.text.trim(),
      panUploadUrl: _panUrl.text.trim(),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value ? accentColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? accentColor : WbColors.line,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: value ? accentColor : WbColors.muted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: value ? accentColor : WbColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? accentColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: value ? accentColor : WbColors.line, width: 1.5),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
