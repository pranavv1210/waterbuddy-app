import 'package:flutter/material.dart';

class OpsColors {
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const surface = Color(0xFFFFFBF3);
  static const cardBg = Colors.white;
  static const blue = Color(0xFF0EA5E9);
  static const green = Color(0xFF14B8A6);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
}

class OpsScaffold extends StatelessWidget {
  const OpsScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.tabs,
    required this.activeIndex,
    required this.onTabChanged,
    required this.body,
    this.accent = OpsColors.blue,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final List<OpsTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabChanged;
  final Widget body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final headerBg = Colors.white.withOpacity(0.94);

    if (isWide) {
      return Scaffold(
        backgroundColor: OpsColors.surface,
        body: Row(
          children: [
            _OpsSidebar(
              title: title,
              subtitle: subtitle,
              tabs: tabs,
              activeIndex: activeIndex,
              onTabChanged: onTabChanged,
              accent: accent,
            ),
            Expanded(
              child: Column(
                children: [
                  _OpsTopBar(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    accent: accent,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: OpsColors.surface,
      appBar: AppBar(
        titleSpacing: 20,
        backgroundColor: headerBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: OpsColors.ink,
        title: Row(
          children: [
            _OpsLogo(accent: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WATERBUDDY',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: OpsColors.ink,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$title - $subtitle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OpsColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: const Border(top: BorderSide(color: OpsColors.line)),
        ),
        child: tabs.length <= 5
            ? NavigationBar(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                selectedIndex: activeIndex,
                onDestinationSelected: onTabChanged,
                indicatorColor: accent.withOpacity(0.15),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (final tab in tabs)
                    NavigationDestination(
                      icon: Icon(tab.icon, color: OpsColors.muted),
                      selectedIcon: Icon(tab.icon, color: accent),
                      label: tab.label,
                    ),
                ],
              )
            : SafeArea(
                top: false,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      for (var index = 0; index < tabs.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: activeIndex == index,
                            onSelected: (_) => onTabChanged(index),
                            avatar: Icon(
                              tabs[index].icon,
                              size: 18,
                              color: activeIndex == index
                                  ? accent
                                  : OpsColors.muted,
                            ),
                            label: Text(tabs[index].label),
                            selectedColor: accent.withOpacity(0.15),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: OpsColors.line),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class OpsTab {
  const OpsTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class OpsCard extends StatelessWidget {
  const OpsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: OpsColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OpsColors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}

class OpsStatusPill extends StatelessWidget {
  const OpsStatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class OpsEmptyState extends StatelessWidget {
  const OpsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: OpsColors.blue.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: OpsColors.blue.withOpacity(0.2)),
              ),
              child: const Icon(Icons.water_drop_outlined,
                  color: OpsColors.blue, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OpsColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OpsColors.muted,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 22),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

Color orderStatusColor(String status) {
  switch (status) {
    case 'SEARCHING':
      return OpsColors.blue;
    case 'OFFER_SENT':
      return const Color(0xFF6366F1);
    case 'ACCEPTED':
    case 'ASSIGNED':
    case 'DRIVER_ASSIGNED':
      return const Color(0xFF8B5CF6);
    case 'ON_THE_WAY':
    case 'ARRIVED':
    case 'DELIVERING':
      return OpsColors.amber;
    case 'DELIVERED':
    case 'approved':
      return OpsColors.green;
    case 'CANCELLED':
    case 'NO_PARTNER_FOUND':
    case 'FAILED':
    case 'rejected':
    case 'suspended':
      return OpsColors.red;
    default:
      return OpsColors.muted;
  }
}

String formatOrderStatus(String status) {
  return status.replaceAll('_', ' ').toUpperCase();
}

class _OpsTopBar extends StatelessWidget {
  const _OpsTopBar({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: const Border(bottom: BorderSide(color: OpsColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _OpsLogo(accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WATERBUDDY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OpsColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$title - $subtitle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: OpsColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _OpsSidebar extends StatelessWidget {
  const _OpsSidebar({
    required this.title,
    required this.subtitle,
    required this.tabs,
    required this.activeIndex,
    required this.onTabChanged,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final List<OpsTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(right: BorderSide(color: OpsColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withOpacity(0.2)),
                ),
                child: Icon(Icons.water_drop_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OpsColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OpsColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: tabs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final selected = activeIndex == index;
                return ListTile(
                  selected: selected,
                  selectedTileColor: accent.withOpacity(0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Icon(
                    tab.icon,
                    color: selected ? accent : OpsColors.muted,
                  ),
                  title: Text(
                    tab.label,
                    style: TextStyle(
                      color: selected ? OpsColors.ink : OpsColors.muted,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  onTap: () => onTabChanged(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsLogo extends StatelessWidget {
  const _OpsLogo({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          'assets/images/logo.png',
          errorBuilder: (_, __, ___) =>
              Icon(Icons.water_drop_rounded, color: accent, size: 20),
        ),
      ),
    );
  }
}
