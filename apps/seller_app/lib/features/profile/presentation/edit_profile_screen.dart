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

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _dlCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  String _tankerSize = '10000';
  
  File? _rcFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isFetching = true;
  
  String? _existingRcUrl;
  
  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return;
      
      final doc = await ref.read(firestoreProvider).collection('sellers').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _originalData = data;
        
        setState(() {
          _nameCtrl.text = data['name'] ?? '';
          _aadhaarCtrl.text = data['aadhaarNumber'] ?? '';
          _panCtrl.text = data['panNumber'] ?? '';
          _dlCtrl.text = data['drivingLicense'] ?? '';
          _vehicleCtrl.text = data['vehicleNumber'] ?? '';
          _tankerSize = (data['tankerCapacity'] ?? 10000).toString();
          
          if (data['documents'] != null) {
            _existingRcUrl = data['documents']['rcUrl'];
          }
          _isFetching = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isFetching = false);
    }
  }

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

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('Not logged in');
      
      // Check if critical fields changed
      final bool criticalChanged = 
          _aadhaarCtrl.text != _originalData['aadhaarNumber'] ||
          _panCtrl.text != _originalData['panNumber'] ||
          _dlCtrl.text != _originalData['drivingLicense'] ||
          _vehicleCtrl.text != _originalData['vehicleNumber'] ||
          _tankerSize != (_originalData['tankerCapacity']?.toString() ?? '10000') ||
          _rcFile != null; // new RC uploaded
          
      String? rcUrl = _existingRcUrl;
      if (_rcFile != null) {
        rcUrl = await _uploadFile(_rcFile!, user.uid, 'rc_update');
      }

      final updateData = {
        'name': _nameCtrl.text.trim(),
        'aadhaarNumber': _aadhaarCtrl.text.trim(),
        'panNumber': _panCtrl.text.trim().toUpperCase(),
        'drivingLicense': _dlCtrl.text.trim().toUpperCase(),
        'vehicleNumber': _vehicleCtrl.text.trim().toUpperCase(),
        'tankerCapacity': int.tryParse(_tankerSize) ?? 10000,
        'documents.rcUrl': rcUrl,
      };

      if (criticalChanged) {
        updateData['kycStatus'] = 'PENDING';
        updateData['isOnline'] = false; // force offline
      }

      await ref.read(firestoreProvider).collection('sellers').doc(user.uid).update(updateData);
      
      if (mounted) {
        if (criticalChanged) {
          // Go to under review
          context.go(RouteNames.underReview);
        } else {
          // Just go back to profile
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
          );
        }
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

  Future<void> _pickImage(void Function(File) onPicked) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => onPicked(File(image.path)));
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        textCapitalization: cap,
        style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFF0F2E74)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0F2E74))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Business Details', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F2E74))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F2E74)),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F2E74)),
                  SizedBox(height: 16),
                  Text('Updating profile...'),
                ],
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Warning: Updating your Aadhaar, PAN, Driving License, or Vehicle details will require a new verification review and will temporarily pause your account.',
                              style: TextStyle(color: Color(0xFF991B1B), fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('PERSONAL DETAILS', style: TextStyle(color: Color(0xFF0F2E74), fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 12)),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_nameCtrl, 'Full Name', Icons.person),
                    _buildTextField(_aadhaarCtrl, 'Aadhaar Number', Icons.credit_card, type: TextInputType.number),
                    _buildTextField(_panCtrl, 'PAN Number', Icons.credit_card_outlined, cap: TextCapitalization.characters),
                    
                    const SizedBox(height: 24),
                    const Text('VEHICLE & LICENSE DETAILS', style: TextStyle(color: Color(0xFF0F2E74), fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 12)),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_dlCtrl, 'Driving License Number', Icons.badge_outlined, cap: TextCapitalization.characters),
                    _buildTextField(_vehicleCtrl, 'Vehicle Registration (RC)', Icons.local_shipping, cap: TextCapitalization.characters),
                    
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _tankerSize,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0F2E74)),
                          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 16),
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
                    
                    GestureDetector(
                      onTap: () => _pickImage((f) => _rcFile = f),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: _rcFile != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _rcFile != null ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0), 
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _rcFile != null ? Icons.check_circle : Icons.document_scanner, 
                              color: _rcFile != null ? const Color(0xFF22C55E) : const Color(0xFF0F2E74), 
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _rcFile != null ? 'New RC Selected' : 'Upload New RC Book Photo (Optional)',
                              style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    ElevatedButton(
                      onPressed: _submitUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2E74),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF0F2E74).withOpacity(0.5),
                      ),
                      child: const Text(
                        'SAVE CHANGES',
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
