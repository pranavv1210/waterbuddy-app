import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';

class DriverOnboardingScreen extends ConsumerStatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  ConsumerState<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends ConsumerState<DriverOnboardingScreen> {
  final _fullName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _licenseNumber = TextEditingController();
  final _aadhaar = TextEditingController();
  final _driverPhoto = TextEditingController();
  final _licenseUpload = TextEditingController();
  final _aadhaarUpload = TextEditingController();
  final _address = TextEditingController();
  final _emergency = TextEditingController();

  @override
  void dispose() {
    for (final c in [_fullName, _mobile, _email, _licenseNumber, _aadhaar, _driverPhoto, _licenseUpload, _aadhaarUpload, _address, _emergency]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Onboarding')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_fullName, 'Full Name'),
          _field(_mobile, 'Mobile Number'),
          _field(_email, 'Email'),
          _field(_licenseNumber, 'Driver License Number'),
          _field(_aadhaar, 'Aadhaar Number'),
          _field(_driverPhoto, 'Driver Photo URL'),
          _field(_licenseUpload, 'License Upload URL'),
          _field(_aadhaarUpload, 'Aadhaar Upload URL'),
          _field(_address, 'Address'),
          _field(_emergency, 'Emergency Contact'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              context.push(
                RouteNames.authDriverOtp,
                extra: {
                  'fullName': _fullName.text.trim(),
                  'phoneNumber': _mobile.text.trim(),
                  'email': _email.text.trim(),
                  'licenseNumber': _licenseNumber.text.trim(),
                  'aadhaarNumber': _aadhaar.text.trim(),
                  'driverPhotoUrl': _driverPhoto.text.trim(),
                  'licenseUploadUrl': _licenseUpload.text.trim(),
                  'aadhaarUploadUrl': _aadhaarUpload.text.trim(),
                  'address': _address.text.trim(),
                  'emergencyContact': _emergency.text.trim(),
                },
              );
            },
            child: const Text('Continue to OTP'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(controller: controller, decoration: InputDecoration(labelText: label)),
    );
  }
}

