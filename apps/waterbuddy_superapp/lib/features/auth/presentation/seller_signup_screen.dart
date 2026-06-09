import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/document_upload_field.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';

class SellerSignupScreen extends ConsumerStatefulWidget {
  const SellerSignupScreen({super.key});

  @override
  ConsumerState<SellerSignupScreen> createState() => _SellerSignupScreenState();
}

class _SellerSignupScreenState extends ConsumerState<SellerSignupScreen> {
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
  bool _drivesSelf = true;
  bool _assignDrivers = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _companyName,
      _mobile,
      _email,
      _password,
      _address,
      _aadhaar,
      _pan,
      _capacity,
      _vehicle,
      _licenseUrl,
      _aadhaarUrl,
      _panUrl,
      _rcUrl,
      _photoUrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WaterBuddyAuthLayout(
      activeRole: AppRole.seller,
      title: 'Tanker Owner Registration',
      subtitle: 'Create your tanker profile',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF111827), size: 18),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'Create Tanker Account',
                    style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Personal Info'),
              _field(_fullName, 'Full Name', Icons.person_outline),
              _field(_companyName, 'Company Name (optional)',
                  Icons.business_outlined,
                  requiredField: false),
              _field(_mobile, 'Mobile Number', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              _field(_address, 'Address', Icons.location_on_outlined),
              const SizedBox(height: 20),
              _buildSectionTitle('Tanker Details'),
              _field(_capacity, 'Tanker Capacity (Litres)',
                  Icons.water_drop_outlined),
              _field(_vehicle, 'Tanker Vehicle Number',
                  Icons.local_shipping_outlined),
              const SizedBox(height: 20),
              _buildSectionTitle('Documents & Uploads'),
              _field(_aadhaar, 'Aadhaar Number', Icons.badge_outlined),
              _field(_pan, 'PAN Number', Icons.credit_card_outlined),
              const SizedBox(height: 12),
              DocumentUploadField(
                controller: _licenseUrl,
                label: 'Driver License Document',
                themeColor: const Color(0xFF0095F6),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _aadhaarUrl,
                label: 'Aadhaar Card Document',
                themeColor: const Color(0xFF0095F6),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _panUrl,
                label: 'PAN Card Document',
                themeColor: const Color(0xFF0095F6),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _rcUrl,
                label: 'Vehicle RC Document',
                themeColor: const Color(0xFF0095F6),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _photoUrl,
                label: 'Tanker Photos',
                themeColor: const Color(0xFF0095F6),
                isPhoto: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Driver Setup'),
              CheckboxListTile(
                value: _drivesSelf,
                onChanged: (value) =>
                    setState(() => _drivesSelf = value ?? false),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF0095F6),
                checkColor: Colors.white,
                title: const Text(
                  'I drive myself',
                  style: TextStyle(
                      color: Color(0xFF111827), fontWeight: FontWeight.w700),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _assignDrivers,
                onChanged: (value) =>
                    setState(() => _assignDrivers = value ?? false),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF0095F6),
                checkColor: Colors.white,
                title: const Text(
                  'I assign drivers',
                  style: TextStyle(
                      color: Color(0xFF111827), fontWeight: FontWeight.w700),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Account Details'),
              _field(_email, 'Email Address', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              _field(_password, 'Password', Icons.lock_outline, obscure: true),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0095F6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Register Tanker',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ],
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
        style: const TextStyle(
            color: Color(0xFF111827), fontSize: 15, fontWeight: FontWeight.w700),
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
        style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
        validator: requiredField
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0095F6), width: 2),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_drivesSelf && !_assignDrivers) {
      setState(() => _error = 'Select how this tanker will be driven.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);

      await auth.signUpWithEmailPassword(
          email: _email.text.trim(), password: _password.text.trim());
      unawaited(_syncSellerProfile(auth).catchError((_) {}));

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

