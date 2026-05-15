import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';

class DriverOnboardingScreen extends ConsumerStatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  ConsumerState<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends ConsumerState<DriverOnboardingScreen> with SingleTickerProviderStateMixin {
  bool _isSignUp = true;
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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8B5CF6)),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6D28D9)),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isSignUp ? 'Driver Registration' : 'Driver Login',
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isSignUp ? 'Provide your details and documents' : 'Enter your mobile number to log in',
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),

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
                                  _field(_driverPhoto, 'Driver Photo URL', Icons.camera_alt_outlined),
                                  _field(_licenseUpload, 'License Upload URL', Icons.link),
                                  _field(_aadhaarUpload, 'Aadhaar Upload URL', Icons.link),
                                  _field(_panUpload, 'PAN Upload URL', Icons.link),
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
                                    backgroundColor: const Color(0xFF8B5CF6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  child: Text(_isSignUp ? 'Continue to OTP' : 'Send OTP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isSignUp ? 'Already have an account?' : 'Don\\'t have an account?',
                                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                    ),
                                    TextButton(
                                      onPressed: _toggleMode,
                                      child: Text(
                                        _isSignUp ? 'Log In' : 'Sign Up',
                                        style: const TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w600),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {bool requiredField = true, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: requiredField ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.03),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFA78BFA))),
          errorStyle: const TextStyle(height: 0),
        ),
      ),
    );
  }
}

