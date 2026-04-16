import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';
import '../../../widgets/async_state_view.dart';
import '../models/completed_order.dart';
import '../providers/order_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedOrder = ref.watch(completedOrderProvider);

    return completedOrder.when(
      data: (state) => _OrdersScreenBody(state: state),
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
}

class _OrdersScreenBody extends ConsumerWidget {
  const _OrdersScreenBody({required this.state});

  final CompletedOrder state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(selectedRatingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFF00236F)),
                            const SizedBox(width: 10),
                            Text(
                              state.brandName,
                              style: const TextStyle(
                                color: Color(0xFF00236F),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFECEEF0),
                            border: Border.all(color: const Color(0xFF00236F).withOpacity(0.1), width: 2),
                          ),
                          child: Image.network(
                            state.userAvatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF1E3A8A), Color(0xFF00236F)],
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(28)),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 52,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              state.successTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF00236F),
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.successSubtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 700;
                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _DeliveryTimeCard(state: state)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _DropLocationCard(state: state)),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _DeliveryTimeCard(state: state),
                                const SizedBox(height: 16),
                                _DropLocationCard(state: state),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _ItemsSummaryCard(state: state),
                        const SizedBox(height: 20),
                        _RatingCard(
                          state: state,
                          rating: rating,
                          onRatingSelected: (value) {
                            ref.read(selectedRatingProvider.notifier).state = value;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                  top: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.7)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: state.navItems.map((item) {
                    final isActive = item.id == 'history';
                    return _BottomNavItem(
                      item: item,
                      isActive: isActive,
                      onTap: () {
                        switch (item.id) {
                          case 'home':
                            context.go(RouteNames.home);
                            break;
                          case 'history':
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
    );
  }
}

class _DeliveryTimeCard extends StatelessWidget {
  const _DeliveryTimeCard({required this.state});

  final CompletedOrder state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Time',
            style: TextStyle(
              color: Color(0xFF757682),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.deliveryTime,
            style: const TextStyle(
              color: Color(0xFF00236F),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF004941)),
              const SizedBox(width: 8),
              Text(
                state.deliveryStatus,
                style: const TextStyle(
                  color: Color(0xFF004941),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropLocationCard extends StatelessWidget {
  const _DropLocationCard({required this.state});

  final CompletedOrder state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dropped At',
            style: TextStyle(
              color: Color(0xFF757682),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.dropLocation,
            style: const TextStyle(
              color: Color(0xFF191C1E),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 84,
              width: double.infinity,
              child: Image.network(
                state.mapImageUrl,
                fit: BoxFit.cover,
                color: Colors.white.withOpacity(0.08),
                colorBlendMode: BlendMode.modulate,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFECEEF0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsSummaryCard extends StatelessWidget {
  const _ItemsSummaryCard({required this.state});

  final CompletedOrder state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(
                  color: Color(0xFF00236F),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                state.orderId,
                style: const TextStyle(
                  color: Color(0xFF757682),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...state.items.map(
            (item) => Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Color(0xFF00687A),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Color(0xFF191C1E),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.quantityLabel,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.amountLabel,
                  style: const TextStyle(
                    color: Color(0xFF00236F),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.state,
    required this.rating,
    required this.onRatingSelected,
  });

  final CompletedOrder state;
  final int rating;
  final ValueChanged<int> onRatingSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            state.ratingTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF00236F),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.ratingSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final selected = rating >= starIndex;
              return IconButton(
                onPressed: () => onRatingSelected(starIndex),
                iconSize: 38,
                color: selected ? const Color(0xFF57DFFE) : const Color(0xFFBFDBFE),
                icon: const Icon(Icons.star_rounded),
              );
            }),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        rating > 0
                            ? 'Feedback submitted with $rating star rating.'
                            : 'Select a rating before submitting feedback.',
                      ),
                    ),
                  );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00236F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                state.feedbackCta,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feedback skipped.')),
            ),
            child: const Text(
              'Skip for now',
              style: TextStyle(
                color: Color(0xFF757682),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

  final CompletedOrderNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                colors: [Color(0xFF1E3A8A), Color(0xFF00236F)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconFor(item.iconKey), color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: const TextStyle(
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
    case 'history':
      return Icons.history_rounded;
    case 'water_drop':
      return Icons.water_drop_rounded;
    case 'person':
      return Icons.person_rounded;
    case 'home':
    default:
      return Icons.home_rounded;
  }
}
