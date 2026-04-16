import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (rawPhone.length != 10) {
      _showMessage('Enter a valid 10-digit phone number.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authServiceProvider).signInWithPhone(
            phoneNumber: '+91$rawPhone',
            codeSent: (_, __) {
              _showMessage(
                  'Verification code sent. OTP screen is the next step.');
            },
            verificationCompleted: (_) {
              _showMessage('Phone verification completed automatically.');
            },
            verificationFailed: (exception) {
              _showMessage(
                  exception.message ?? 'Unable to send verification code.');
            },
            codeAutoRetrievalTimeout: (_) {},
          );
    } catch (_) {
      _showMessage('Unable to start verification right now.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      _showMessage('Unable to open Privacy Policy right now.');
    }
  }

  Future<void> _openTermsOfUse() async {
    final uri = Uri.parse(AppConstants.termsOfUseUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      _showMessage('Unable to open Terms of Service right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00236F);
    const primaryContainer = Color(0xFF1E3A8A);
    const brandTeal = Color(0xFF14B8A6);
    const surface = Color(0xFFF7F9FB);
    const surfaceLowest = Color(0xFFFFFFFF);
    const surfaceLow = Color(0xFFF2F4F6);
    const outlineVariant = Color(0xFFC5C5D3);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF444651);
    const outline = Color(0xFF757682);

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -140,
            child: _GlowOrb(
              size: 360,
              color: brandTeal.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: _GlowOrb(
              size: 320,
              color: primaryContainer.withOpacity(0.06),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          _BrandBadge(
                            primaryContainer: primaryContainer,
                            brandTeal: brandTeal,
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'WaterBuddy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primary,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pure hydration, delivered.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: surfaceLowest,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 35, 111, 0.08),
                              blurRadius: 48,
                              offset: Offset(0, 24),
                              spreadRadius: -12,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your phone number to receive a verification code.',
                              style: TextStyle(
                                color: onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                'Phone Number',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: surfaceLow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          '+91',
                                          style: TextStyle(
                                            color: onSurfaceVariant,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(
                                          Icons.expand_more_rounded,
                                          color: outline,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 28,
                                    color: outlineVariant.withOpacity(0.3),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(
                                        color: onSurface,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: '99887 76655',
                                        hintStyle: TextStyle(
                                          color: Color.fromRGBO(
                                              117, 118, 130, 0.4),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: FilledButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _sendVerificationCode,
                                style: FilledButton.styleFrom(
                                  backgroundColor: brandTeal,
                                  disabledBackgroundColor:
                                      brandTeal.withOpacity(0.55),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Send Verification Code',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: outlineVariant.withOpacity(0.7),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    'OR CONNECT WITH',
                                    style: TextStyle(
                                      color: outline,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: outlineVariant.withOpacity(0.7),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: OutlinedButton(
                                onPressed: () {
                                  _showMessage(
                                      'Google sign-in will be connected next.');
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: surfaceLow,
                                  foregroundColor: onSurfaceVariant,
                                  side: BorderSide(
                                    color: Colors.transparent,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CustomPaint(
                                        painter: _GoogleIconPainter(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'New to WaterBuddy?',
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _showMessage(
                                  'Account creation flow will be connected next.');
                            },
                            child: const Text(
                              'Create account',
                              style: TextStyle(
                                color: brandTeal,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 18,
                        runSpacing: 6,
                        children: [
                          TextButton(
                            onPressed: _openPrivacyPolicy,
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: outline,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _openTermsOfUse,
                            child: const Text(
                              'Terms of Service',
                              style: TextStyle(
                                color: outline,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
        ],
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({
    required this.primaryContainer,
    required this.brandTeal,
  });

  final Color primaryContainer;
  final Color brandTeal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Transform.rotate(
              angle: 0.2,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      brandTeal,
                      primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brandTeal.withOpacity(0.2),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.08),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF14B8A6),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.35,
      1.4,
      true,
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.05,
      1.2,
      true,
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.2,
      1.15,
      true,
      paint,
    );

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.15,
      1.25,
      true,
      paint,
    );

    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.46, paint);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.42, size.width * 0.3,
          size.height * 0.16),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
