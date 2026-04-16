import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';
import '../../../widgets/async_state_view.dart';
import '../models/home_dashboard.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);

    return dashboard.when(
      data: (state) {
        final selectedTankId =
            ref.watch(selectedTankIdProvider) ?? _defaultTankId(state);

        return _HomeScreenBody(
          state: state,
          selectedTankId: selectedTankId,
          onTankSelected: (tankId) {
            ref.read(selectedTankIdProvider.notifier).state = tankId;
          },
        );
      },
      error: (_, __) => const AsyncStateView(
        isLoading: false,
        hasError: true,
        child: SizedBox.shrink(),
      ),
      loading: () => const AsyncStateView(
        isLoading: true,
        hasError: false,
        child: SizedBox.shrink(),
      ),
    );
  }

  String _defaultTankId(HomeDashboard state) {
    return state.tankOptions
            .firstWhere(
              (option) => option.isRecommended,
              orElse: () => state.tankOptions.first,
            )
            .id;
  }
}

class _HomeScreenBody extends StatelessWidget {
  const _HomeScreenBody({
    required this.state,
    required this.selectedTankId,
    required this.onTankSelected,
  });

  final HomeDashboard state;
  final String selectedTankId;
  final ValueChanged<String> onTankSelected;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00236F);
    const primaryContainer = Color(0xFF1E3A8A);
    const secondary = Color(0xFF00687A);
    const accent = Color(0xFF27C0AE);
    const surface = Color(0xFFF7F9FB);
    const surfaceContainer = Color(0xFFECEEF0);
    const surfaceContainerLow = Color(0xFFF2F4F6);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF444651);
    const outlineVariant = Color(0xFFC5C5D3);

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.15),
                BlendMode.modulate,
              ),
              child: Image.network(
                state.mapImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: surfaceContainer),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.62),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 35, 111, 0.18),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            state.brandName,
                            style: const TextStyle(
                              color: primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _TopIconButton(
                            icon: Icons.notifications_none_rounded,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notifications panel will be connected next.'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 42,
                            height: 42,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Image.network(
                              state.userAvatarUrl,
                              fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                color: surfaceContainer,
                                alignment: Alignment.center,
                                child: Text(
                                  state.userName.isNotEmpty
                                      ? state.userName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 92,
                  right: 20,
                  child: _FloatingRoundButton(
                    icon: Icons.my_location_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Live location recenter will be connected next.'),
                        ),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withOpacity(0.14),
                            ),
                          ),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 35, 111, 0.18),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(15, 23, 42, 0.08),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          state.heroBadgeLabel,
                          style: const TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 720),
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.6)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 35, 111, 0.15),
                            blurRadius: 50,
                            offset: Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 46,
                              height: 6,
                              decoration: BoxDecoration(
                                color: outlineVariant,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            state.capacityTitle,
                            style: const TextStyle(
                              color: primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.capacitySubtitle,
                            style: const TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: state.tankOptions
                                .map(
                                  (option) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: option == state.tankOptions.last ? 0 : 10,
                                      ),
                                      child: _TankOptionCard(
                                        option: option,
                                        selected: option.id == selectedTankId,
                                        onTap: () => onTankSelected(option.id),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: FilledButton(
                              onPressed: () => context.go(RouteNames.searching),
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Book Now',
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
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 26),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border(
                        top: BorderSide(color: outlineVariant.withOpacity(0.28)),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 35, 111, 0.06),
                          blurRadius: 24,
                          offset: Offset(0, -8),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: state.bottomNavItems.map((item) {
                          final isActive = item.id == 'home';
                          return _BottomNavItem(
                            item: item,
                            isActive: isActive,
                            onTap: () {
                              switch (item.id) {
                                case 'home':
                                  break;
                                case 'history':
                                  context.go(RouteNames.orders);
                                  break;
                                case 'book':
                                  context.go(RouteNames.searching);
                                  break;
                                case 'profile':
                                  context.go(RouteNames.profile);
                                  break;
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF64748B)),
      ),
    );
  }
}

class _FloatingRoundButton extends StatelessWidget {
  const _FloatingRoundButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 10,
      shadowColor: const Color.fromRGBO(0, 35, 111, 0.16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: const Color(0xFF00236F)),
        ),
      ),
    );
  }
}

class _TankOptionCard extends StatelessWidget {
  const _TankOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final TankOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primaryContainer = Color(0xFF1E3A8A);
    const surfaceLow = Color(0xFFF2F4F6);
    const onSurfaceVariant = Color(0xFF64748B);

    return Material(
      color: selected ? primaryContainer : surfaceLow,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.18) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconFor(option.iconKey),
                  size: 22,
                  color: selected ? Colors.white : primaryContainer,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                option.label,
                style: TextStyle(
                  color: selected ? Colors.white : primaryContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                option.capacityLabel,
                style: TextStyle(
                  color: selected ? Colors.white70 : onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                option.priceLabel,
                style: TextStyle(
                  color: selected ? Colors.white : primaryContainer,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final BottomNavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00236F);

    if (isActive) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF00236F),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 35, 111, 0.18),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconFor(item.iconKey), color: Colors.white),
                const SizedBox(height: 4),
                const Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(item.iconKey), color: const Color(0xFF94A3B8)),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(String iconKey) {
  switch (iconKey) {
    case 'location_on':
      return Icons.location_on_rounded;
    case 'notifications':
      return Icons.notifications_none_rounded;
    case 'my_location':
      return Icons.my_location_rounded;
    case 'opacity':
      return Icons.opacity_rounded;
    case 'water_drop':
      return Icons.water_drop_rounded;
    case 'waves':
      return Icons.waves_rounded;
    case 'history':
      return Icons.history_rounded;
    case 'person':
      return Icons.person_rounded;
    case 'home':
    default:
      return Icons.home_rounded;
  }
}
