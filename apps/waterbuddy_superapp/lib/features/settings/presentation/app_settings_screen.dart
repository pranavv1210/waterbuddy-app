import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/operations_ui.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _orderAlerts = true;
  bool _locationUpdates = true;
  bool _saving = true;
  LocationPermission? _permission;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      _orderAlerts = prefs.getBool('settings.orderAlerts') ?? true;
      _locationUpdates = prefs.getBool('settings.locationUpdates') ?? true;
      _permission = permission;
      _saving = false;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  Future<void> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    if (!mounted) return;
    setState(() => _permission = permission);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(systemSettingsProvider).valueOrNull;
    final supportEmail = settings?.supportEmail.isNotEmpty == true
        ? settings!.supportEmail
        : AppConstants.supportEmail;
    final supportSubtitle = settings?.supportNumber.isNotEmpty == true
        ? '${settings!.supportNumber} • $supportEmail'
        : supportEmail;
    const bg = Color(0xFFF8FAFC);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: OpsColors.ink,
              size: 20,
            ),
            onPressed: _goBack,
          ),
          title: const Text(
            'App settings',
            style: TextStyle(
              color: OpsColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            OpsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      color: OpsColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    value: _orderAlerts,
                    activeTrackColor: OpsColors.blue,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Order alerts',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Receive booking, driver, and delivery updates.',
                    ),
                    onChanged: _saving
                        ? null
                        : (value) async {
                            setState(() => _orderAlerts = value);
                            await _setBool('settings.orderAlerts', value);
                          },
                  ),
                  const Divider(height: 20),
                  SwitchListTile.adaptive(
                    value: _locationUpdates,
                    activeTrackColor: OpsColors.blue,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Location updates',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Use location for nearby tanker availability.',
                    ),
                    onChanged: _saving
                        ? null
                        : (value) async {
                            setState(() => _locationUpdates = value);
                            await _setBool('settings.locationUpdates', value);
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OpsCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.my_location_rounded,
                    title: 'Location permission',
                    subtitle: _locationLabel,
                    trailing: TextButton(
                      onPressed: _requestLocationPermission,
                      child: const Text('Manage'),
                    ),
                  ),
                  const Divider(height: 24),
                  _SettingsRow(
                    icon: Icons.support_agent_rounded,
                    title: 'Support',
                    subtitle: supportSubtitle,
                    trailing: TextButton(
                      onPressed: () {
                        launchUrl(Uri(
                          scheme: 'mailto',
                          path: supportEmail,
                          query: 'subject=WaterBuddy support',
                        ));
                      },
                      child: const Text('Contact'),
                    ),
                  ),
                  const Divider(height: 24),
                  const _SettingsRow(
                    icon: Icons.verified_user_rounded,
                    title: 'App version',
                    subtitle: 'WaterBuddy beta',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _locationLabel {
    switch (_permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return 'Enabled';
      case LocationPermission.deniedForever:
        return 'Blocked in system settings';
      case LocationPermission.denied:
        return 'Permission not granted';
      case LocationPermission.unableToDetermine:
      case null:
        return 'Checking permission';
    }
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: OpsColors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: OpsColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
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
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}
