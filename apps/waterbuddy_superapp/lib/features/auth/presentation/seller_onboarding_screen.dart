import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/document_upload_field.dart';
import '../../../widgets/kaveri_auth_layout.dart';

class SellerOnboardingScreen extends ConsumerStatefulWidget {
  const SellerOnboardingScreen({super.key});

  @override
  ConsumerState<SellerOnboardingScreen> createState() => _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState extends ConsumerState<SellerOnboardingScreen> with SingleTickerProviderStateMixin {
  bool _isSignUp = false; // Start on Login page, matching Sanchari Kaveri defaults!
  final _formKey = GlobalKey<FormState>();
  
  final _fullName = TextEditingController();
  final _companyName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  final _aadhaar = TextEditingController();
  final _pan = TextEditingController();
  final _capacity = TextEditingController();
  final _vehicle = TextEditingController();
  
  final _licenseUrl = TextEditingController();
  final _aadhaarUrl = TextEditingController();
  final _panUrl = TextEditingController();
  final _rcUrl = TextEditingController();
  final _photoUrl = TextEditingController();
  
  bool _loading = false;
  String? _error;

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
    for (final c in [_fullName, _companyName, _mobile, _email, _password, _address, _aadhaar, _pan, _capacity, _vehicle, _licenseUrl, _aadhaarUrl, _panUrl, _rcUrl, _photoUrl]) {
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
        activeRole: AppRole.seller,
        title: 'Login as Tanker Owner',
        subtitle: _isSignUp ? 'Register a new Tanker profile' : 'Enter mobile details and password to login',
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
                    _isSignUp ? 'Create Tanker Account' : 'Welcome Back Owner',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  if (_isSignUp) ...[
                    _buildSectionTitle('Personal Info'),
                    _field(_fullName, 'Full Name', Icons.person_outline),
                    _field(_companyName, 'Company Name (optional)', Icons.business_outlined, requiredField: false),
                    _field(_mobile, 'Mobile Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                    _field(_address, 'Address', Icons.location_on_outlined),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Tanker Details'),
                    _field(_capacity, 'Tanker Capacity (Litres)', Icons.water_drop_outlined),
                    _field(_vehicle, 'Tanker Vehicle Number', Icons.local_shipping_outlined),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Documents & Uploads'),
                    _field(_aadhaar, 'Aadhaar Number', Icons.badge_outlined),
                    _field(_pan, 'PAN Number', Icons.credit_card_outlined),
                    const SizedBox(height: 12),
                    DocumentUploadField(
                      controller: _licenseUrl,
                      label: 'Driver License Document',
                      themeColor: const Color(0xFF0EA5E9),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    DocumentUploadField(
                      controller: _aadhaarUrl,
                      label: 'Aadhaar Card Document',
                      themeColor: const Color(0xFF0EA5E9),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    DocumentUploadField(
                      controller: _panUrl,
                      label: 'PAN Card Document',
                      themeColor: const Color(0xFF0EA5E9),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    DocumentUploadField(
                      controller: _rcUrl,
                      label: 'Vehicle RC Document',
                      themeColor: const Color(0xFF0EA5E9),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    DocumentUploadField(
                      controller: _photoUrl,
                      label: 'Tanker Photos',
                      themeColor: const Color(0xFF0EA5E9),
                      isPhoto: true,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Account Details'),
                  ],
                  
                  _field(_email, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  _field(_password, 'Password', Icons.lock_outline, obscure: true),
                  
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF0EA5E9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isSignUp ? 'Register Tanker' : 'Log In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                  ],
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
    bool obscure = false,
    bool requiredField = true,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
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

  Future<void> _submit() async {
    if (_isSignUp && !_formKey.currentState!.validate()) return;
    if (!_isSignUp && (_email.text.trim().isEmpty || _password.text.trim().isEmpty)) {
      setState(() => _error = 'Please enter email and password');
      return;
    }
    
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final auth = ref.read(authServiceProvider);
      
      if (_isSignUp) {
        await auth.signUpWithEmailPassword(email: _email.text.trim(), password: _password.text.trim());
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
        );
      } else {
        await auth.signInWithEmailPassword(email: _email.text.trim(), password: _password.text.trim());
      }
      
      if (!mounted) return;
      context.go(RouteNames.sellerWaiting);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to complete action.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
