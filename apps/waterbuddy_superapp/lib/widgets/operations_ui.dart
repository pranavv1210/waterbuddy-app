import 'package:flutter/material.dart';

class OpsColors {
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);
  static const surface = Color(0xFFF8FAFC);
  static const blue = Color(0xFF0EA5E9);
  static const green = Color(0xFF10B981);
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
                      title: title, subtitle: subtitle, actions: actions),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(
              subtitle,
              style: const TextStyle(
                color: OpsColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        selectedIndex: activeIndex,
        onDestinationSelected: onTabChanged,
        indicatorColor: accent.withValues(alpha: 0.12),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OpsColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
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
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: OpsColors.blue, size: 34),
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
    case 'ASSIGNED':
    case 'DRIVER_ASSIGNED':
      return const Color(0xFF6366F1);
    case 'ON_THE_WAY':
    case 'ARRIVED':
      return OpsColors.amber;
    case 'DELIVERED':
    case 'approved':
      return OpsColors.green;
    case 'CANCELLED':
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
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: OpsColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: OpsColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: OpsColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: OpsColors.line)),
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
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
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
                  selectedTileColor: accent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
