import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'premium_ui.dart';
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
      _fileName = "${widget.label.toLowerCase().replaceAll(' ', '_')}_verified.pdf";
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

  // Simulates uploading a file with a sleek progress bar
  void _simulateUpload(String name, String size, String mockUrl) {
    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
      _fileName = name;
      _fileSize = size;
      _success = false;
    });

    const steps = 15;
    double currentStep = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      currentStep++;
      if (mounted) {
        setState(() {
          _uploadProgress = currentStep / steps;
        });
      }

      if (currentStep >= steps) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _uploading = false;
            _success = true;
            widget.controller.text = mockUrl;
          });
          WaterBuddyToastService.success(
            context,
            '${widget.label} uploaded successfully',
          );
        }
      }
    });
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
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a source to scan or attach your document. Supported formats: PDF, PNG, JPG, JPEG, DOCX.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
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
                color: color.withOpacity(0.12),
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
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
    showWaterBuddyBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.document_scanner_rounded,
                    color: widget.themeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scan ${widget.label}',
                    style: const TextStyle(
                      color: WbColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: WbColors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 310,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: WbColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const Positioned.fill(child: AbstractWaterBackground()),
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.74,
                      height: 210,
                      decoration: BoxDecoration(
                        border: Border.all(color: widget.themeColor, width: 2),
                        borderRadius: BorderRadius.circular(22),
                        color: Colors.white.withOpacity(0.42),
                      ),
                      child: Center(
                        child: Text(
                          'Align ${widget.label} inside frame',
                          style: const TextStyle(
                            color: WbColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 42,
                    right: 42,
                    top: 154,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: widget.themeColor.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: widget.themeColor.withOpacity(0.30),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hold steady while WaterBuddy captures a clear verification document.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WbColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final randomNum = Random().nextInt(9000) + 1000;
                final name =
                    "${widget.label.toLowerCase().replaceAll(' ', '_')}_scan_$randomNum.jpg";
                final size = "1.${Random().nextInt(9) + 1} MB";
                final mockUrl = widget.isPhoto
                    ? "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500"
                    : "https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?w=500";
                _simulateUpload(name, size, mockUrl);
              },
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Capture Document'),
              style: FilledButton.styleFrom(
                backgroundColor: WbColors.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _openGalleryPicker() {
    showWaterBuddyBottomSheet(
      context: context,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select ${widget.label} from Gallery',
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildTemplateCard(
                    label: 'Recent Scan 1',
                    ext: 'PNG',
                    size: '1.2 MB',
                    icon: Icons.image_rounded,
                    color: Colors.amber,
                  ),
                  _buildTemplateCard(
                    label: 'Scan_Copy.jpg',
                    ext: 'JPG',
                    size: '890 KB',
                    icon: Icons.filter_hdr_rounded,
                    color: Colors.lightBlue,
                  ),
                  _buildTemplateCard(
                    label: 'Official_Doc.pdf',
                    ext: 'PDF',
                    size: '2.8 MB',
                    icon: Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final randomNum = Random().nextInt(9000) + 1000;
                _simulateUpload(
                  "${widget.label.toLowerCase().replaceAll(' ', '_')}_gallery_$randomNum.png",
                  "2.1 MB",
                  "https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=500",
                );
              },
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Browse Other Device Files...', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openFileBrowser() {
    showWaterBuddyBottomSheet(
      context: context,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Document File',
                  style: TextStyle(color: Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFileListOption('Aadhaar_Card_Digital.pdf', '1.4 MB', Colors.redAccent),
            const SizedBox(height: 8),
            _buildFileListOption('Driving_License_Copy.pdf', '980 KB', Colors.redAccent),
            const SizedBox(height: 8),
            _buildFileListOption('Vehicle_RC_Official.docx', '3.1 MB', Colors.blue),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _simulateUpload(
                  "${widget.label.toLowerCase().replaceAll(' ', '_')}_browse.pdf",
                  "1.6 MB",
                  "https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?w=500",
                );
              },
              icon: const Icon(Icons.file_copy_rounded),
              label: const Text('Select Custom File...', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListOption(String name, String size, Color extColor) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _simulateUpload(name, size, "https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?w=500");
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.description_rounded, color: extColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(size, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_downward_rounded, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required String label,
    required String ext,
    required String size,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _simulateUpload(label, size, "https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?w=500");
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(ext, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(size, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
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
                        ? widget.themeColor.withOpacity(0.04)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _success
                          ? widget.themeColor
                          : formFieldState.hasError
                              ? Colors.redAccent.withOpacity(0.6)
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
                              ? widget.themeColor.withOpacity(0.12)
                              : _uploading
                                  ? widget.themeColor.withOpacity(0.06)
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
                                color: _success ? widget.themeColor : textSlateMuted,
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
                                color: _success ? widget.themeColor : textSlateMuted,
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
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                          onPressed: _reset,
                        )
                      else if (!_uploading)
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
                    ],
                  ),
                ),
              ),
              if (formFieldState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    formFieldState.errorText!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

