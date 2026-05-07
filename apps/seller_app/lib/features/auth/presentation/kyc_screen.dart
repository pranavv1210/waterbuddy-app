import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _dlCtrl = TextEditingController(); // Added DL
  final _vehicleCtrl = TextEditingController();
  String _tankerSize = '10000'; // Default to 10000L
  
  File? _aadhaarFile;
  File? _dlFile;
  File? _rcFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    _dlCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<String?> _uploadFile(File file, String userId, String docType) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('kyc_documents')
          .child(userId)
          .child('${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading $docType: $e');
      return null;
    }
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_aadhaarFile == null || _dlFile == null || _rcFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('Not logged in');
      
      // Upload files
      final aadhaarUrl = await _uploadFile(_aadhaarFile!, user.uid, 'aadhaar');
      final dlUrl = await _uploadFile(_dlFile!, user.uid, 'dl');
      final rcUrl = await _uploadFile(_rcFile!, user.uid, 'rc');

      await ref.read(firestoreProvider).collection('sellers').doc(user.uid).set({
        'name': _nameCtrl.text.trim(),
        'aadhaarNumber': _aadhaarCtrl.text.trim(),
        'panNumber': _panCtrl.text.trim().toUpperCase(),
        'drivingLicense': _dlCtrl.text.trim().toUpperCase(),
        'vehicleNumber': _vehicleCtrl.text.trim().toUpperCase(),
        'tankerCapacity': int.tryParse(_tankerSize) ?? 10000,
        'kycStatus': 'PENDING', // Changed to PENDING
        'documents': {
          'aadhaarUrl': aadhaarUrl,
          'dlUrl': dlUrl,
          'rcUrl': rcUrl,
        },
        'isOnline': false,
        'latitude': null,
        'longitude': null,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (mounted) {
        context.go(RouteNames.underReview);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    TextInputType type = TextInputType.text,
    TextCapitalization cap = TextCapitalization.none,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        textCapitalization: cap,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF475569)),
          prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Future<void> _pickImage(void Function(File) onPicked) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => onPicked(File(image.path)));
    }
  }

  Widget _buildUploadButton(String label, IconData icon, File? selectedFile, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selectedFile != null ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedFile != null ? const Color(0xFF10B981) : const Color(0xFF10B981).withOpacity(0.5), 
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              selectedFile != null ? Icons.check_circle : icon, 
              color: const Color(0xFF10B981), 
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              selectedFile != null ? 'Document Selected' : label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              selectedFile != null ? 'Tap to change' : 'Tap to upload photo',
              style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep slate black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Partner KYC',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF10B981)),
                  SizedBox(height: 24),
                  Text(
                    'Verifying Documents...',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This securely authenticates your identity.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Let\'s get you verified.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We need some details to ensure community safety and trust.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text('PERSONAL DETAILS', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 12)),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_nameCtrl, 'Full Name (As per Aadhaar)', Icons.person),
                    _buildTextField(_aadhaarCtrl, 'Aadhaar Number', Icons.credit_card, type: TextInputType.number),
                    _buildUploadButton('Upload Aadhaar Front & Back', Icons.camera_alt_outlined, _aadhaarFile, () => _pickImage((f) => _aadhaarFile = f)),
                    
                    _buildTextField(_panCtrl, 'PAN Number', Icons.credit_card_outlined, cap: TextCapitalization.characters),
                    
                    const SizedBox(height: 24),
                    const Text('VEHICLE & LICENSE DETAILS', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 12)),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_dlCtrl, 'Driving License Number', Icons.badge_outlined, cap: TextCapitalization.characters),
                    _buildUploadButton('Upload Driving License', Icons.image_outlined, _dlFile, () => _pickImage((f) => _dlFile = f)),
                    
                    _buildTextField(_vehicleCtrl, 'Vehicle Registration (RC) Number', Icons.local_shipping, cap: TextCapitalization.characters),
                    
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _tankerSize,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF10B981)),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                          items: ['10000', '15000', '20000'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text('$value Litres Capacity'),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() => _tankerSize = newValue);
                            }
                          },
                        ),
                      ),
                    ),
                    
                    _buildUploadButton('Upload RC Book Photo', Icons.document_scanner, _rcFile, () => _pickImage((f) => _rcFile = f)),
                    
                    const SizedBox(height: 40),
                    
                    ElevatedButton(
                      onPressed: _submitKyc,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                      ),
                      child: const Text(
                        'COMPLETE VERIFICATION',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
