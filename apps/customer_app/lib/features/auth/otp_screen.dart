import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routes/route_names.dart';

// ─────────────────────────────────────────────
//  Design tokens (matching login_screen)
// ─────────────────────────────────────────────
class _Colors {
  static const primary = Color(0xFF0F2B5B);
  static const accent = Color(0xFF0EA5E9);
  static const surface = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const inputBg = Color(0xFFF1F5F9);
  static const inputBorder = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textTertiary = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2E8F0);
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // ── Auth state listener (unchanged logic) ──
    ref.listen(authControllerProvider, (previous, next) {
      if (!mounted) return;

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        ref.read(authControllerProvider.notifier).clearMessages();
      }

      if (next.isVerified && next.isVerified != previous?.isVerified) {
        context.go(RouteNames.home);
      }
    });

    final phone = authState.phoneNumber ?? 'your number';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _Colors.surface,
        body: Stack(
          children: [
            // ── Decorative background ──
            Positioned(
              top: -100,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _Colors.accent.withOpacity(0.08),
                        _Colors.accent.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -100,
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _Colors.primary.withOpacity(0.05),
                        _Colors.primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ──
            SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    children: [
                      // ── Top bar ──
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: _Colors.textPrimary,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _Colors.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                    color: _Colors.divider, width: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Body ──
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 400),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ── Icon ──
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: _Colors.accent.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: _Colors.accent,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Verify your number',
                                    style: TextStyle(
                                      color: _Colors.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter the 6-digit code sent to\n$phone',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _Colors.textSecondary,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // ── Card ──
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: _Colors.card,
                                      borderRadius:
                                          BorderRadius.circular(24),
                                      border: Border.all(
                                        color:
                                            _Colors.divider.withOpacity(0.6),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0F172A)
                                              .withOpacity(0.04),
                                          blurRadius: 32,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // ── OTP field ──
                                        Container(
                                          decoration: BoxDecoration(
                                            color: _Colors.inputBg,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: _Colors.inputBorder,
                                            ),
                                          ),
                                          child: TextField(
                                            controller: _otpController,
                                            focusNode: _otpFocus,
                                            keyboardType:
                                                TextInputType.number,
                                            maxLength: 6,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: _Colors.textPrimary,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 12,
                                            ),
                                            decoration:
                                                const InputDecoration(
                                              hintText: '••••••',
                                              hintStyle: TextStyle(
                                                color: _Colors.textTertiary,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 12,
                                              ),
                                              counterText: '',
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // ── Verify button ──
                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: FilledButton(
                                            onPressed: authState.isLoading
                                                ? null
                                                : () {
                                                    ref
                                                        .read(
                                                            authControllerProvider
                                                                .notifier)
                                                        .verifyOtp(
                                                            _otpController
                                                                .text);
                                                  },
                                            style:
                                                FilledButton.styleFrom(
                                              backgroundColor:
                                                  _Colors.accent,
                                              disabledBackgroundColor:
                                                  _Colors.accent
                                                      .withOpacity(0.5),
                                              foregroundColor:
                                                  Colors.white,
                                              shape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        14),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: authState.isLoading
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                : const Text(
                                                    'Verify & Continue',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // ── Resend hint ──
                                  Text(
                                    "Didn't receive the code?",
                                    style: TextStyle(
                                      color: _Colors.textTertiary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      'Go back & resend',
                                      style: TextStyle(
                                        color: _Colors.accent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
