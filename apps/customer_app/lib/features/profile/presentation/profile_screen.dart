import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/async_state_view.dart';
import '../models/profile_dashboard.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(profileDashboardProvider);

    return dashboard.when(
      data: (state) => _ProfileScreenBody(state: state),
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

class _ProfileScreenBody extends StatelessWidget {
  const _ProfileScreenBody({required this.state});

  final ProfileDashboard state;

  @override
  Widget build(BuildContext context) {
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
                            const Icon(Icons.location_on_rounded,
                                color: Color(0xFF00236F)),
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
                        Row(
                          children: [
                            if (MediaQuery.of(context).size.width >= 760)
                              ...state.topNavItems.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(right: 24),
                                  child: InkWell(
                                    onTap: () =>
                                        _handleNavTap(context, item.id),
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        color: item.id == 'profile'
                                            ? const Color(0xFF1D4ED8)
                                            : const Color(0xFF64748B),
                                        fontSize: 14,
                                        fontWeight: item.id == 'profile'
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Container(
                              width: 40,
                              height: 40,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00236F)
                                      .withValues(alpha: 0.1),
                                  width: 2,
                                ),
                              ),
                              child: Image.network(
                                state.userAvatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person_rounded, size: 18),
                              ),
                            ),
                          ],
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
                        _HeroProfileCard(state: state),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 900;
                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        _RecentOrdersCard(state: state),
                                        const SizedBox(height: 24),
                                        _PaymentMethodsCard(state: state),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(child: _SupportCard(state: state)),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _RecentOrdersCard(state: state),
                                const SizedBox(height: 24),
                                _PaymentMethodsCard(state: state),
                                const SizedBox(height: 24),
                                _SupportCard(state: state),
                              ],
                            );
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
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                  ),
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
                    return _BottomNavItem(
                      item: item,
                      isActive: item.id == 'profile',
                      onTap: () => _handleNavTap(context, item.id),
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

class _HeroProfileCard extends StatelessWidget {
  const _HeroProfileCard({required this.state});

  final ProfileDashboard state;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 768;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 35, 111, 0.04),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: wide
          ? Row(
              children: [
                _ProfileImage(imageUrl: state.profileImageUrl),
                const SizedBox(width: 24),
                Expanded(child: _ProfileSummary(state: state, centered: false)),
                const SizedBox(width: 20),
                _EditProfileButton(
                  onTap: () => _showMessage(
                      context, 'Profile editing will be connected next.'),
                ),
              ],
            )
          : Column(
              children: [
                _ProfileImage(imageUrl: state.profileImageUrl),
                const SizedBox(height: 20),
                _ProfileSummary(state: state, centered: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _EditProfileButton(
                    onTap: () => _showMessage(
                        context, 'Profile editing will be connected next.'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            imageUrl,
            width: 128,
            height: 128,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 128,
              height: 128,
              color: const Color(0xFFECEEF0),
              child: const Icon(Icons.person_rounded, size: 40),
            ),
          ),
        ),
        Positioned(
          right: -8,
          bottom: -8,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF71F8E4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 35, 111, 0.12),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF00312B),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.state,
    required this.centered,
  });

  final ProfileDashboard state;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          state.profileName,
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF00236F),
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment:
              centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_rounded, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                state.email,
                textAlign: centered ? TextAlign.center : TextAlign.left,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          spacing: 10,
          runSpacing: 10,
          children: [
            _TagChip(
              label: state.membershipLabel,
              backgroundColor: const Color(0xFFF2F4F6),
              textColor: const Color(0xFF00236F),
            ),
            _TagChip(
              label: state.completedOrdersLabel,
              backgroundColor: const Color(0xFF4FDBC8).withValues(alpha: 0.2),
              textColor: const Color(0xFF00312B),
            ),
          ],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF00236F),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: const Text(
        'Edit Profile',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard({required this.state});

  final ProfileDashboard state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 35, 111, 0.04),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(
                  color: Color(0xFF00236F),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(RouteNames.orders),
                child: const Text(
                  'View History',
                  style: TextStyle(
                    color: Color(0xFF00236F),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...state.recentOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: InkWell(
                onTap: () => context.go(RouteNames.orders),
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _iconFor(order.iconKey),
                          color: const Color(0xFF00236F),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.title,
                              style: const TextStyle(
                                color: Color(0xFF191C1E),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.subtitle,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            order.amountLabel,
                            style: const TextStyle(
                              color: Color(0xFF00236F),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF757682),
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

class _PaymentMethodsCard extends StatelessWidget {
  const _PaymentMethodsCard({required this.state});

  final ProfileDashboard state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 35, 111, 0.04),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Methods',
            style: TextStyle(
              color: Color(0xFF00236F),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 560
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: state.paymentMethods.map((method) {
                  return SizedBox(
                    width: cardWidth,
                    child: method.isAddNew
                        ? _AddPaymentMethodCard(
                            onTap: () => _showMessage(context,
                                'Add card flow will be connected next.'),
                          )
                        : _PaymentMethodCardView(method: method),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCardView extends StatelessWidget {
  const _PaymentMethodCardView({required this.method});

  final PaymentMethodCard method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -10,
            right: -10,
            child: Icon(
              Icons.credit_card_rounded,
              size: 72,
              color: Color.fromRGBO(255, 255, 255, 0.16),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                method.title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                method.maskedNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expires',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method.expiryLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Image.network(
                    method.brandImageUrl,
                    height: 24,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.credit_card_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddPaymentMethodCard extends StatelessWidget {
  const _AddPaymentMethodCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 176,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFC5C5D3),
              width: 2,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_rounded,
                size: 34,
                color: Color(0xFF757682),
              ),
              SizedBox(height: 8),
              Text(
                'Add New Card',
                style: TextStyle(
                  color: Color(0xFF757682),
                  fontSize: 15,
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

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.state});

  final ProfileDashboard state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 35, 111, 0.04),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Help & Support',
            style: TextStyle(
              color: Color(0xFF00236F),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => _showMessage(context, 'Email support will open next.'),
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.alternate_email_rounded,
                      color: Color(0xFF00236F),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EMAIL SUPPORT',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.supportEmail,
                          style: const TextStyle(
                            color: Color(0xFF00236F),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...state.supportItems.map(
            (item) => _SupportRow(
              title: item.title,
              icon: _iconFor(item.iconKey),
              onTap: () => _handleSupportTap(context, item.id, item.title),
            ),
          ),
          const SizedBox(height: 22),
          const Divider(color: Color(0xFFECEEF0)),
          const SizedBox(height: 14),
          InkWell(
            onTap: () =>
                _showMessage(context, 'Sign out flow will be connected next.'),
            borderRadius: BorderRadius.circular(18),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A)),
                  SizedBox(width: 12),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Color(0xFFBA1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF64748B)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF191C1E),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF757682)),
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

  final ProfileNavItem item;
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

void _handleNavTap(BuildContext context, String id) {
  switch (id) {
    case 'home':
      context.go(RouteNames.home);
      break;
    case 'history':
      context.go(RouteNames.orders);
      break;
    case 'book':
      context.go(RouteNames.searching);
      break;
    case 'profile':
      break;
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
    case 'opacity':
      return Icons.opacity_rounded;
    case 'help_outline':
      return Icons.help_outline_rounded;
    case 'chat_bubble_outline':
      return Icons.chat_bubble_outline_rounded;
    case 'policy':
      return Icons.policy_rounded;
    case 'home':
    default:
      return Icons.home_rounded;
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _handleSupportTap(
  BuildContext context,
  String id,
  String title,
) async {
  if (id == 'privacy') {
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      _showMessage(context, 'Unable to open Privacy Policy right now.');
    }
    return;
  }

  _showMessage(context, '$title will be connected next.');
}
