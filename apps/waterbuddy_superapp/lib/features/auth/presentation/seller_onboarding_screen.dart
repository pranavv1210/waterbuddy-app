import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class SellerOnboardingScreen extends ConsumerStatefulWidget {
  const SellerOnboardingScreen({super.key});

  @override
  ConsumerState<SellerOnboardingScreen> createState() => _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState extends ConsumerState<SellerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _companyName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  final _aadhaar = TextEditingController();
  final _capacity = TextEditingController();
  final _vehicle = TextEditingController();
  final _licenseUrl = TextEditingController();
  final _aadhaarUrl = TextEditingController();
  final _rcUrl = TextEditingController();
  final _photoUrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_fullName, _companyName, _mobile, _email, _password, _address, _aadhaar, _capacity, _vehicle, _licenseUrl, _aadhaarUrl, _rcUrl, _photoUrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tanker Owner Onboarding')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_fullName, 'Full Name'),
            _field(_companyName, 'Company Name (optional)', requiredField: false),
            _field(_mobile, 'Mobile Number'),
            _field(_email, 'Email'),
            _field(_password, 'Password', obscure: true),
            _field(_address, 'Address'),
            _field(_aadhaar, 'Aadhaar Number'),
            _field(_capacity, 'Tanker Capacity'),
            _field(_vehicle, 'Tanker Vehicle Number'),
            _field(_licenseUrl, 'License Upload URL'),
            _field(_aadhaarUrl, 'Aadhaar Upload URL'),
            _field(_rcUrl, 'Vehicle RC Upload URL'),
            _field(_photoUrl, 'Tanker Photos URL'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Submitting...' : 'Create Seller Account'),
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool obscure = false, bool requiredField = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        validator: requiredField ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
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
      if (!mounted) return;
      context.go(RouteNames.sellerWaiting);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to complete seller signup.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

