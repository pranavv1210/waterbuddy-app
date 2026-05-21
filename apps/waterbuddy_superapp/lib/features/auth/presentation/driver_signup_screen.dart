import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/document_upload_field.dart';
import '../../../widgets/waterbuddy_auth_layout.dart';

class DriverSignupScreen extends ConsumerStatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  ConsumerState<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends ConsumerState<DriverSignupScreen> {
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

  @override
  void dispose() {
    for (final c in [_fullName, _mobile, _email, _licenseNumber, _aadhaar, _pan, _driverPhoto, _licenseUpload, _aadhaarUpload, _panUpload, _address, _emergency]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WaterBuddyAuthLayout(
      activeRole: AppRole.driver,
      title: 'Driver Registration',
      subtitle: 'Create your Driver profile',
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'Create Driver Account',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
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
                themeColor: const Color(0xFFF59E0B),
                isPhoto: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _licenseUpload,
                label: 'Driver License Document',
                themeColor: const Color(0xFFF59E0B),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _aadhaarUpload,
                label: 'Aadhaar Card Document',
                themeColor: const Color(0xFFF59E0B),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              DocumentUploadField(
                controller: _panUpload,
                label: 'PAN Card Document',
                themeColor: const Color(0xFFF59E0B),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              
              _buildSectionTitle('Login Details'),
              _field(_mobile, 'Mobile Number', Icons.phone_outlined, keyboardType: TextInputType.phone),

              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  if (_mobile.text.trim().isEmpty) return;

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
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFD97706),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Continue to OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
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
            borderSide: const BorderSide(color: Color(0xFFF59E0B)),
          ),
        ),
      ),
    );
  }
}
