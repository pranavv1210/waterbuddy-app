import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/app_providers.dart';
import '../../routes/route_names.dart';
import 'auth_controller.dart';

// ─────────────────────────────────────────────
//  Design tokens – shared across the screen
// ─────────────────────────────────────────────
class _Colors {
  static const primary = Color(0xFF0F172A); // Dark Slate
  static const accent = Color(0xFF10B981); // Emerald
  static const surface = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const inputBg = Color(0xFFF1F5F9);
  static const inputBorder = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2E8F0);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // ── Auth state listener ──
    ref.listen(authControllerProvider, (previous, next) {
      if (!mounted) return;

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        ref.read(authControllerProvider.notifier).clearMessages();
      }

      if (next.isCodeSent &&
          next.verificationId != previous?.verificationId) {
        context.push(RouteNames.otp);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _Colors.surface,
        body: Stack(
          children: [
            // ── Decorative background ──
            _buildBackground(),

            // ── Foreground ──
            SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLogo(),
                            const SizedBox(height: 40),
                            _buildCard(authState),
                            const SizedBox(height: 32),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Background ─────────────────────────
  Widget _buildBackground() {
    return Stack(
      children: [
        // Top-right accent blob
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
                    _Colors.accent.withOpacity(0.10),
                    _Colors.accent.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Bottom-left primary blob
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
                    _Colors.primary.withOpacity(0.06),
                    _Colors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Logo ─────────────────────────
  Widget _buildLogo() {
    return Column(
      children: [
        // Icon container
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF064E3B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _Colors.accent.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset('assets/images/logo.png'),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'WaterBuddy Partner',
          style: TextStyle(
            color: _Colors.primary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Join the delivery network.',
          style: TextStyle(
            color: _Colors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Card ─────────────────────────
  Widget _buildCard(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Colors.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _Colors.divider.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Partner Login',
            style: TextStyle(
              color: _Colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter your registered phone number.',
            style: TextStyle(
              color: _Colors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // ── Phone input ──
          _buildPhoneField(),
          const SizedBox(height: 20),

          // ── Send OTP ──
          _buildSendOtpButton(authState),

          // ── Google Sign-in ──
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildGoogleSignInButton(authState),

          // ── Success message ──
          if (authState.successMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      authState.successMessage!,
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Phone input field ──
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            color: _Colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _Colors.inputBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _Colors.inputBorder),
          ),
          child: Row(
            children: [
              // Country code
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: _Colors.inputBorder),
                  ),
                ),
                child: const Text(
                  '+91',
                  style: TextStyle(
                    color: _Colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Input
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    color: _Colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  decoration: const InputDecoration(
                    hintText: '98765 43210',
                    hintStyle: TextStyle(
                      color: _Colors.textTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Send OTP button ──
  Widget _buildSendOtpButton(AuthState authState) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: authState.isLoading
            ? null
            : () {
                ref
                    .read(authControllerProvider.notifier)
                    .sendOtp(_phoneController.text);
              },
        style: FilledButton.styleFrom(
          backgroundColor: _Colors.accent,
          disabledBackgroundColor: _Colors.accent.withOpacity(0.5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: authState.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Send OTP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
      ),
    );
  }

  // ── Divider ──
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: _Colors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: _Colors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _Colors.divider)),
      ],
    );
  }

  // ── Google Sign In button ──
  Widget _buildGoogleSignInButton(AuthState authState) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: authState.isLoading
            ? null
            : () {
                ref.read(authControllerProvider.notifier).signInWithGoogle();
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: _Colors.textPrimary,
          side: const BorderSide(color: _Colors.inputBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/google_logo.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign in with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Footer ─────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            text: 'By continuing, you agree to our ',
            style: const TextStyle(
              color: _Colors.textTertiary,
              fontSize: 12,
            ),
            children: [
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Terms',
                    style: TextStyle(
                      color: _Colors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const TextSpan(text: ' and '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: _Colors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          '© 2026 WaterBuddy Global',
          style: TextStyle(
            color: _Colors.textTertiary.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
