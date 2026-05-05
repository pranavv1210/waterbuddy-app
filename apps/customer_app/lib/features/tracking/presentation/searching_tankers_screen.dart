import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';
import '../models/searching_tankers_state.dart';
import '../providers/searching_providers.dart';

class SearchingTankersScreen extends ConsumerStatefulWidget {
  const SearchingTankersScreen({super.key});

  @override
  ConsumerState<SearchingTankersScreen> createState() =>
      _SearchingTankersScreenState();
}

class _SearchingTankersScreenState extends ConsumerState<SearchingTankersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Get orderId from query params and start watching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderId = GoRouterState.of(context).uri.queryParameters['orderId'];
      if (orderId != null) {
        ref.read(searchingControllerProvider.notifier).startWatchingOrder(orderId);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchingState = ref.watch(searchingControllerProvider);
    final uiState = ref.watch(searchingTankersProvider);

    if (searchingState.errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${searchingState.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF191C1E)),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.read(searchingControllerProvider.notifier).clearError();
                      context.go(RouteNames.home);
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show timeout UI with retry button
    if (searchingState.hasTimedOut) {
      return _TimeoutView(
        onRetry: () {
          context.go(RouteNames.home);
        },
      );
    }

    // Navigate to tracking screen when order is assigned
    if (searchingState.orderStatus == 'ASSIGNED' && searchingState.orderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('${RouteNames.tracking}?orderId=${searchingState.orderId}');
      });
    }

    return _SearchingBody(
      state: uiState,
      animation: _controller,
      orderId: GoRouterState.of(context).uri.queryParameters['orderId'],
    );
  }
}

class _SearchingBody extends StatelessWidget {
  const _SearchingBody({
    required this.state,
    required this.animation,
    this.orderId,
  });

  final SearchingTankersState state;
  final Animation<double> animation;
  final String? orderId;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F2B5B);
    const sonarColor = Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Searching Tankers',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        state.title,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sonar Animation Center
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sonar Waves
                      ...List.generate(3, (index) {
                        final delay = index * 0.33;
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            double progress = (animation.value + delay) % 1.0;
                            double opacity = (1.0 - progress) * 0.5;
                            double size = 120 + (progress * 250);
                            
                            return Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: sonarColor.withOpacity(opacity),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      
                      // Central Pulse
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  
                  // Status Info
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.radar_rounded, color: primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.scanTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: primaryColor,
                                    ),
                                  ),
                                  Text(
                                    state.scanSubtitle,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32, color: Color(0xFFF1F5F9)),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              state.connectionLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                state.connectionBadge,
                                style: const TextStyle(
                                  color: Color(0xFF0369A1),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.footerMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: () => context.go(RouteNames.home),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFFEE2E2)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.close_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              state.cancelLabel,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeoutView extends StatelessWidget {
  const _TimeoutView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_off_rounded, size: 40, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 24),
              const Text(
                'No tankers available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2B5B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We couldn\'t find any tankers nearby right now. You can try again or check back in a few minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2B5B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Retry Search', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text('Back to Home', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
