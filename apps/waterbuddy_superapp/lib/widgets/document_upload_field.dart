import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'waterbuddy_bottom_sheet.dart';
import 'waterbuddy_toast.dart';

class DocumentUploadField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final Color themeColor;
  final bool isPhoto;
  final String? Function(String?)? validator;

  const DocumentUploadField({
    super.key,
    required this.controller,
    required this.label,
    required this.themeColor,
    this.isPhoto = false,
    this.validator,
  });

  @override
  State<DocumentUploadField> createState() => _DocumentUploadFieldState();
}

class _DocumentUploadFieldState extends State<DocumentUploadField> {
  String? _fileName;
  String? _fileSize;
  bool _uploading = false;
  double _uploadProgress = 0.0;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isNotEmpty) {
      _success = true;
      _fileName =
          "${widget.label.toLowerCase().replaceAll(' ', '_')}_verified.pdf";
      _fileSize = "1.8 MB";
    }
  }

  void _reset() {
    setState(() {
      _fileName = null;
      _fileSize = null;
      _uploading = false;
      _uploadProgress = 0.0;
      _success = false;
      widget.controller.clear();
    });
  }

  Future<void> _uploadBytes({
    required String name,
    required int sizeBytes,
    required String contentType,
    Uint8List? bytes,
    String? localPath,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WaterBuddyToastService.error(
        context,
        'Sign in before uploading documents.',
      );
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
      _fileName = name;
      _fileSize = _formatSize(sizeBytes);
      _success = false;
    });

    try {
      final safeLabel = widget.label
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
      final ref = FirebaseStorage.instance.ref(
        'verification_documents/${user.uid}/$safeLabel/${DateTime.now().millisecondsSinceEpoch}_$safeName',
      );
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'label': widget.label,
          'uid': user.uid,
        },
      );

      final UploadTask task;
      if (!kIsWeb && localPath != null) {
        task = ref.putFile(File(localPath), metadata);
      } else if (bytes != null) {
        task = ref.putData(bytes, metadata);
      } else {
        throw StateError('No upload data available.');
      }

      final sub = task.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        if (!mounted || total <= 0) return;
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / total;
        });
      });

      final snapshot = await task;
      await sub.cancel();
      final url = await snapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadProgress = 1;
        _success = true;
        widget.controller.text = url;
      });
      WaterBuddyToastService.success(
        context,
        '${widget.label} uploaded successfully',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadProgress = 0;
        _success = false;
        widget.controller.clear();
      });
      WaterBuddyToastService.error(context, 'Upload failed: $e');
    }
  }

  void _openUploadBottomSheet() {
    showWaterBuddyBottomSheet(
      context: context,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload ${widget.label}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a source to scan or attach your document. Supported formats: PDF, PNG, JPG, JPEG, DOCX.',
              style: TextStyle(
                  color: Color(0xFF64748B), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            _buildBottomSheetOption(
              icon: Icons.camera_alt_rounded,
              title: 'Capture with Camera',
              subtitle: 'Scan physical document or take photo live',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.pop(context);
                _openCameraScanner();
              },
            ),
            const SizedBox(height: 12),
            _buildBottomSheetOption(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Pick high-quality scan from photo albums',
              color: const Color(0xFF38BDF8),
              onTap: () {
                Navigator.pop(context);
                _openGalleryPicker();
              },
            ),
            const SizedBox(height: 12),
            _buildBottomSheetOption(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Select PDF or Document',
              subtitle: 'Browse phone files for PDF or Word docs',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _openFileBrowser();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _openCameraScanner() {
    _pickImage(ImageSource.camera);
  }

  void _openGalleryPicker() {
    _pickImage(ImageSource.gallery);
  }

  Future<void> _openFileBrowser() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
    );
    final file = result?.files.single;
    if (file == null) return;
    await _uploadBytes(
      name: file.name,
      sizeBytes: file.size,
      contentType: _contentTypeFor(file.extension),
      bytes: file.bytes,
      localPath: file.path,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (file == null) return;
    final bytes = kIsWeb ? await file.readAsBytes() : null;
    final size = kIsWeb ? bytes!.length : await File(file.path).length();
    await _uploadBytes(
      name: file.name,
      sizeBytes: size,
      contentType: _contentTypeFor(file.name.split('.').last),
      bytes: bytes,
      localPath: file.path,
    );
  }

  String _contentTypeFor(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    const inkSlate = Color(0xFF0F172A);
    const textSlateMuted = Color(0xFF64748B);

    return FormField<String>(
      validator: (_) {
        if (widget.validator != null) {
          return widget.validator!(widget.controller.text);
        }
        return null;
      },
      builder: (formFieldState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _uploading ? null : _openUploadBottomSheet,
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: _success
                        ? widget.themeColor.withValues(alpha: 0.04)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _success
                          ? widget.themeColor
                          : formFieldState.hasError
                              ? Colors.redAccent.withValues(alpha: 0.6)
                              : const Color(0xFFE2E8F0),
                      width: _success ? 1.8 : 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Status Icon container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _success
                              ? widget.themeColor.withValues(alpha: 0.12)
                              : _uploading
                                  ? widget.themeColor.withValues(alpha: 0.06)
                                  : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: _uploading
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  value: _uploadProgress,
                                  color: widget.themeColor,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Icon(
                                _success
                                    ? Icons.verified_user_rounded
                                    : widget.isPhoto
                                        ? Icons.add_a_photo_rounded
                                        : Icons.cloud_upload_outlined,
                                color: _success
                                    ? widget.themeColor
                                    : textSlateMuted,
                                size: 22,
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Text Description (Ink slate instead of white!)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _success
                                  ? widget.label
                                  : _uploading
                                      ? "Uploading ${_fileName ?? ''}..."
                                      : "Upload ${widget.label}",
                              style: const TextStyle(
                                color: inkSlate,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _success
                                  ? "$_fileName • $_fileSize"
                                  : _uploading
                                      ? "${(_uploadProgress * 100).toInt()}% uploaded"
                                      : widget.isPhoto
                                          ? "Capture photo or choose image"
                                          : "Supports PDF, images & docs",
                              style: TextStyle(
                                color: _success
                                    ? widget.themeColor
                                    : textSlateMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      if (_success)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 22),
                          onPressed: _reset,
                        )
                      else if (!_uploading)
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF94A3B8), size: 14),
                    ],
                  ),
                ),
              ),
              if (formFieldState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    formFieldState.errorText!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
