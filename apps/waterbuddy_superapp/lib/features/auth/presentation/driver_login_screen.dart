import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_role.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/loading_feedback_button.dart';
import '../../../widgets/premium_ui.dart';
import '../../../widgets/waterbuddy_toast.dart';

class DriverLoginScreen extends ConsumerStatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  ConsumerState<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends ConsumerState<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobile = TextEditingController(text: '9988776655');
  LoadingButtonState _btnState = LoadingButtonState.idle;

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                      color: const Color(0xFF08111F),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),

                  const SizedBox(height: 36),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.route_rounded,
                            color: Color(0xFFF59E0B), size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver Login',
                            style: TextStyle(
                              color: Color(0xFF08111F),
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter your mobile to continue',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08),

                  const SizedBox(height: 36),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WbPremiumTextField(
                          controller: _mobile,
                          label: 'Mobile Number',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          accentColor: const Color(0xFFF59E0B),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter mobile number';
                            }
                            if (v.trim().length < 10) {
                              return 'Enter valid 10-digit number';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: authState.isLoading
                                ? null
                                : () => context.push(
                                    '${RouteNames.passwordReset}?role=driver'),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                        ),
                        const SizedBox(height: 8),
                        LoadingFeedbackButton(
                          onPressed: authState.isLoading ||
                                  _btnState == LoadingButtonState.loading
                              ? null
                              : () async {
                                  if (_mobile.text.trim().isEmpty) return;
                                  setState(() =>
                                      _btnState = LoadingButtonState.loading);
                                  final ok = await ref
                                      .read(authControllerProvider.notifier)
                                      .sendOtp(_mobile.text.trim(),
                                          role: AppRole.driver);
                                  if (!context.mounted) return;
                                  if (!ok) {
                                    setState(() =>
                                        _btnState = LoadingButtonState.idle);
                                    WaterBuddyToastService.error(
                                        context, 'Failed to send OTP');
                                    return;
                                  }
                                  setState(() =>
                                      _btnState = LoadingButtonState.success);
                                  await Future.delayed(
                                      const Duration(milliseconds: 400));
                                  if (!context.mounted) return;
                                  context
                                      .push(RouteNames.authDriverOtp, extra: {
                                    'phoneNumber': _mobile.text.trim(),
                                    'isSignUp': false,
                                  });
                                },
                          label: 'Send OTP',
                          loadingLabel: 'Sending OTP...',
                          successLabel: 'OTP Sent!',
                          buttonState: _btnState,
                          backgroundColor: const Color(0xFFF59E0B),
                          borderRadius: 18,
                        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.08),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
