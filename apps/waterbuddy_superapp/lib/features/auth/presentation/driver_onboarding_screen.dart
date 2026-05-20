import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/document_upload_field.dart';
import '../../../widgets/kaveri_auth_layout.dart';

class DriverOnboardingScreen extends ConsumerStatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  ConsumerState<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends ConsumerState<DriverOnboardingScreen> with SingleTickerProviderStateMixin {
  bool _isSignUp = false; // Default to login mode like Sanchari Kaveri!
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _licenseNumber = TextEditingController();
  final _aadhaar = TextEditingController();
  final _pan = TextEditingController();
  final _driverPhoto = TextEditingController();
  final _licenseUpload = TextEditingController();
  final _aadhaarUpload = TextEditingController();
  final _panUpload = TextEditingController();
  final _address = TextEditingController();
  final _emergency = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    for (final c in [_fullName, _mobile, _email, _licenseNumber, _aadhaar, _pan, _driverPhoto, _licenseUpload, _aadhaarUpload, _panUpload, _address, _emergency]) {
      c.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isSignUp = !_isSignUp);
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSignUp) {
          _toggleMode();
        } else {
          context.go(RouteNames.roleSelection);
        }
      },
      child: KaveriAuthLayout(
        activeRole: AppRole.driver,
        title: 'Login as Driver',
        subtitle: _isSignUp ? 'Register a new Driver profile' : 'Enter mobile details to login',
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isSignUp ? 'Create Driver Account' : 'Welcome Back Driver',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  if (_isSignUp) ...[
                    _buildSectionTitle('Personal Info'),
                    _field(_fullName, 'Full Name', Icons.person_outline),
                    _field(_email, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    _field(_address, 'Address', Icons.location_on_outlined),
                    _field(_emergency, 'Emergency Contact', Icons.contact_phone_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Documents & Uploads'),
                    _field(_licenseNumber, 'Driver License Number', Icons.card_membership_outlined),
                    _field(_aadhaar, 'Aadhaar Number', Icons.badge_outlined),
                    _field(_pan, 'PAN Number', Icons.credit_card_outlined),
                    const SizedBox(height: 12),
                    DocumentUploadField(
                      controller: _driverPhoto,
                      label: 'Driver Photo',
                      themeColor: const Color(0xFF0EA5E9),
                      isPhoto: true,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    DocumentUploadField(
                      controller: _licenseUpload,
                      label: 'Driver License Document',
                      themeColor: const Color(0xFF0EA5E9),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    DocumentUploadField(
                      controller: _aadhaarUpload,
                      label: 'Aadhaar Card Document',
                      themeColor: const Color(0xFF0EA5E9),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    DocumentUploadField(
                      controller: _panUpload,
                      label: 'PAN Card Document',
                      themeColor: const Color(0xFF0EA5E9),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Login Details'),
                  ],

                  _field(_mobile, 'Mobile Number', Icons.phone_outlined, keyboardType: TextInputType.phone),

                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (_isSignUp && !_formKey.currentState!.validate()) return;
                      if (!_isSignUp && _mobile.text.trim().isEmpty) return;

                      context.push(
                        RouteNames.authDriverOtp,
                        extra: _isSignUp
                            ? {
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
                              }
                            : {
                                'phoneNumber': _mobile.text.trim(),
                                'isSignUp': false,
                              },
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF0EA5E9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(_isSignUp ? 'Continue to OTP' : 'Send OTP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp ? 'Already have an account?' : "Don't have an account?",
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                      TextButton(
                        onPressed: _toggleMode,
                        child: Text(
                          _isSignUp ? 'Log In' : 'Sign Up',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool requiredField = true,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: requiredField ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF38BDF8)),
          ),
        ),
      ),
    );
  }
}
