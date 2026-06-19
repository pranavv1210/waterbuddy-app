import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/location/google_maps_service.dart';
import '../../../models/order.dart' as app_order;
import '../../../models/system_settings.dart';
import '../../../models/tank_category.dart';
import '../../../providers/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/loading_feedback_button.dart';
import '../../../widgets/premium_ui.dart';
import '../../../widgets/waterbuddy_bottom_sheet.dart';
import '../../../widgets/waterbuddy_toast.dart';
import '../../tracking/providers/searching_providers.dart';
import '../providers/home_providers.dart';
import '../providers/order_creation_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(activeTankCategoriesProvider);
    final categoriesLoading = ref.watch(tankCategoriesProvider).isLoading;
    final settings = ref.watch(systemSettingsProvider).valueOrNull ??
        SystemSettings.defaults();
    final selectedTankId = ref.watch(selectedTankIdProvider) ??
        (categories.isNotEmpty ? categories.first.id : '');
    final activeOrder = ref.watch(activeOrderProvider).value;

    ref.listen(activeOrderProvider, (previous, next) {
      final order = next.value;
      if (order == null) return;
      if (order.status == 'ACCEPTED' ||
          order.status == 'ASSIGNED' ||
          order.status == 'DRIVER_ASSIGNED' ||
          order.status == 'ON_THE_WAY') {
        context.go('${RouteNames.tracking}?orderId=${order.id}');
      }
    });

    return _HomeMapExperience(
      tankCategories: categories,
      categoriesLoading: categoriesLoading,
      selectedTankId: selectedTankId,
      systemSettings: settings,
      activeOrder: activeOrder,
      onTankSelected: (id) =>
          ref.read(selectedTankIdProvider.notifier).state = id,
    );
  }
}

class _HomeMapExperience extends ConsumerStatefulWidget {
  const _HomeMapExperience({
    required this.tankCategories,
    required this.categoriesLoading,
    required this.selectedTankId,
    required this.systemSettings,
    required this.activeOrder,
    required this.onTankSelected,
  });

  final List<TankCategory> tankCategories;
  final bool categoriesLoading;
  final String selectedTankId;
  final SystemSettings systemSettings;
  final app_order.Order? activeOrder;
  final ValueChanged<String> onTankSelected;

  @override
  ConsumerState<_HomeMapExperience> createState() => _HomeMapExperienceState();
}

class _HomeMapExperienceState extends ConsumerState<_HomeMapExperience>
    with SingleTickerProviderStateMixin {
  static const _defaultLocation = LatLng(12.9716, 77.5946);

  GoogleMapController? _mapController;
  LatLng _source = _defaultLocation;
  LatLng _destination = _defaultLocation;
  String _address = 'Select delivery location';
  String? _routeSummary;
  bool _loadingLocation = false;
  LoadingButtonState _bookingState = LoadingButtonState.idle;
  BitmapDescriptor? _tankerIcon;
  List<LatLng> _routePoints = const [];
  late final AnimationController _pulseController;
  final GoogleMapsService _googleMapsService = GoogleMapsService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _loadTankerIcon();
    unawaited(_determinePosition(showToast: false));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _loadTankerIcon() {
    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(36, 36)),
      'assets/ui/tanker.png',
    ).then((icon) {
      if (mounted) setState(() => _tankerIcon = icon);
    }).catchError((_) {});
  }

  Future<void> _determinePosition({bool showToast = true}) async {
    setState(() => _loadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          WaterBuddyToastService.warning(
            context,
            'Turn on location services to use live delivery.',
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          WaterBuddyToastService.error(
            context,
            'Location permission is required for booking.',
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _source = latLng;
        _destination = latLng;
        _routePoints = const [];
        _routeSummary = null;
      });
      _animateTo(latLng, zoom: 15.8);
      await _resolveAddress(latLng);
      if (showToast && mounted) {
        WaterBuddyToastService.success(context, 'Location updated');
      }
    } catch (error) {
      if (mounted) {
        WaterBuddyToastService.error(context, 'Unable to get location: $error');
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _resolveAddress(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted || placemarks.isEmpty) return;
      final place = placemarks.first;
      final parts = [
        place.name,
        place.subLocality,
        place.locality,
        place.postalCode,
      ].where((part) => part != null && part.trim().isNotEmpty).toList();
      setState(() {
        _address =
            parts.isEmpty ? 'Pinned delivery location' : parts.join(', ');
      });
    } catch (_) {
      if (mounted) setState(() => _address = 'Pinned delivery location');
    }
  }

  void _animateTo(LatLng latLng, {double zoom = 15.2}) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, zoom));
  }

  Set<Marker> _markers(List<Map<String, dynamic>> sellers) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('source'),
        position: _source,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Current location'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: _destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Delivery point'),
      ),
    };

    for (final seller in sellers) {
      final lat = seller['lat'] as double?;
      final lng = seller['lng'] as double?;
      if (lat == null || lng == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId('seller_${seller['id']}'),
          position: LatLng(lat, lng),
          icon: _tankerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: const InfoWindow(title: 'Nearby tanker'),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> get _polylines {
    if (_source == _destination) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        points: _routePoints.isEmpty ? [_source, _destination] : _routePoints,
        color: WbColors.blue,
        width: 5,
      ),
    };
  }

  Future<void> _refreshRoute() async {
    if (_source == _destination) return;
    final route = await _googleMapsService.getDirections(
      originLatitude: _source.latitude,
      originLongitude: _source.longitude,
      destinationLatitude: _destination.latitude,
      destinationLongitude: _destination.longitude,
    );
    if (!mounted || route == null || route.polylinePoints.isEmpty) return;
    setState(() {
      _routePoints = route.polylinePoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
      _routeSummary = [
        route.durationInTrafficText ?? route.durationText,
        route.distanceText,
      ].where((value) => value.isNotEmpty).join(' • ');
    });
  }

  Future<void> _openLocationPicker() async {
    final result =
        await context.push(RouteNames.locationSelection, extra: _address);
    if (!mounted || result is! Map<String, dynamic>) return;
    final location = result['location'] as Map<String, dynamic>?;
    final lat = location?['latitude'] as double?;
    final lng = location?['longitude'] as double?;
    if (lat == null || lng == null) return;
    final latLng = LatLng(lat, lng);
    setState(() {
      _destination = latLng;
      _address = (result['address'] as String?) ?? 'Pinned delivery location';
      _routePoints = const [];
      _routeSummary = null;
    });
    _animateTo(latLng);
    unawaited(_refreshRoute());
    HapticFeedback.selectionClick();
  }

  void _openBookingSheet() {
    if (!widget.systemSettings.serviceAvailable) {
      WaterBuddyToastService.warning(
        context,
        'Bookings are temporarily disabled by operations.',
      );
      return;
    }
    if (widget.tankCategories.isEmpty) {
      WaterBuddyToastService.warning(
        context,
        widget.categoriesLoading
            ? 'Loading tanker options.'
            : 'No active tanker categories are available.',
      );
      return;
    }

    showWaterBuddyBottomSheet<void>(
      context: context,
      child: _TankerSelectionSheet(
        tankCategories: widget.tankCategories,
        selectedTankId: widget.selectedTankId,
        bookingState: _bookingState,
        address: _address,
        onTankSelected: widget.onTankSelected,
        onBook: _submitOrder,
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_bookingState != LoadingButtonState.idle) return;
    setState(() => _bookingState = LoadingButtonState.loading);
    try {
      final category = widget.tankCategories.firstWhere(
        (tank) => tank.id == widget.selectedTankId,
        orElse: () => widget.tankCategories.first,
      );
      final orderId = await ref
          .read(orderCreationControllerProvider.notifier)
          .createOrder(
            tankCategory: category,
            location: {
              'latitude': _destination.latitude,
              'longitude': _destination.longitude,
              'address': _address,
              'sourceLatitude': _source.latitude,
              'sourceLongitude': _source.longitude,
            },
            paymentType: widget.systemSettings.codEnabled ? 'COD' : 'ONLINE',
          );
      if (!mounted) return;
      if (orderId == null) {
        setState(() => _bookingState = LoadingButtonState.idle);
        WaterBuddyToastService.error(context, 'Unable to create booking.');
        return;
      }
      ref
          .read(searchingControllerProvider.notifier)
          .startWatchingOrder(orderId);
      setState(() => _bookingState = LoadingButtonState.success);
      WaterBuddyToastService.success(context, 'Booking created');
      await Future.delayed(const Duration(milliseconds: 520));
      if (mounted) context.go('${RouteNames.searching}?orderId=$orderId');
    } catch (error) {
      if (mounted) {
        setState(() => _bookingState = LoadingButtonState.idle);
        WaterBuddyToastService.error(context, 'Booking failed: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final sellers = ref.watch(onlineSellersProvider).valueOrNull ?? const [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: WbColors.surface,
        drawer: _OlaStyleDrawer(user: user, support: _supportLabel()),
        body: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _defaultLocation,
                  zoom: 14.7,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _animateTo(_destination);
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                markers: _markers(sellers),
                polylines: _polylines,
                onCameraMove: (position) => _destination = position.target,
                onCameraIdle: () {
                  _resolveAddress(_destination);
                  setState(() {
                    _routePoints = const [];
                    _routeSummary = null;
                  });
                  unawaited(_refreshRoute());
                },
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Builder(
                    builder: (context) => MapPillButton(
                      icon: Icons.menu_rounded,
                      onTap: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassPanel(
                      radius: 999,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            color: WbColors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WbColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  MapPillButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => WaterBuddyToastService.info(
                      context,
                      'No new notifications',
                    ),
                  ),
                  const SizedBox(width: 10),
                  MapPillButton(
                    icon: Icons.person_rounded,
                    onTap: () => context.go(RouteNames.profile),
                  ),
                ],
              ).animate().fadeIn(duration: 280.ms).slideY(begin: -0.15),
            ),
            Center(
              child: IgnorePointer(
                child: AnimatedPulse(
                  animation: _pulseController,
                  color: WbColors.red,
                  icon: Icons.location_on_rounded,
                  size: 122,
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 248 + MediaQuery.paddingOf(context).bottom,
              child: MapPillButton(
                icon: _loadingLocation
                    ? Icons.more_horiz_rounded
                    : Icons.my_location_rounded,
                onTap: () => _determinePosition(),
                color: WbColors.blue,
              ),
            ),
            PremiumBottomPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassPanel(
                    radius: 22,
                    opacity: 1,
                    shadow: false,
                    padding: const EdgeInsets.all(14),
                    onTap: _openLocationPicker,
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: WbColors.blue.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: WbColors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Where should we deliver water?',
                            style: TextStyle(
                              color: WbColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            color: WbColors.muted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _QuickAddressRow(onSelected: (label) {
                    WaterBuddyToastService.info(
                      context,
                      '$label selected. Confirm the map pin before booking.',
                    );
                  }),
                  const SizedBox(height: 14),
                  if (sellers.isEmpty)
                    const _OperationalNotice(
                      message:
                          'No live tanker owners are visible nearby right now. You can still request a booking and WaterBuddy will dispatch it to eligible owners.',
                    )
                  else
                    _OperationalNotice(
                      message: _routeSummary == null
                          ? '${sellers.length} live tanker owner${sellers.length == 1 ? '' : 's'} visible in your service area.'
                          : '${sellers.length} live tanker owner${sellers.length == 1 ? '' : 's'} visible • $_routeSummary',
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _openBookingSheet,
                      icon: const Icon(Icons.water_drop_rounded),
                      label: const Text('Choose Tanker'),
                      style: FilledButton.styleFrom(
                        backgroundColor: WbColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.18, end: 0),
          ],
        ),
      ),
    );
  }

  String _supportLabel() {
    final settings = widget.systemSettings;
    if (settings.supportNumber.isNotEmpty) return settings.supportNumber;
    if (settings.supportEmail.isNotEmpty) return settings.supportEmail;
    return 'waterbuddyapp.wb@gmail.com';
  }
}

class _QuickAddressRow extends StatelessWidget {
  const _QuickAddressRow({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.business_center_rounded, 'Work'),
      (Icons.history_rounded, 'Recent'),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = items[index];
          return ActionChip(
            avatar: Icon(item.$1, color: WbColors.blue, size: 18),
            label: Text(item.$2),
            onPressed: () => onSelected(item.$2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: const BorderSide(color: WbColors.line),
            ),
            backgroundColor: Colors.white,
            labelStyle: const TextStyle(
              color: WbColors.ink,
              fontWeight: FontWeight.w800,
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _OperationalNotice extends StatelessWidget {
  const _OperationalNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WbColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.radar_rounded, color: WbColors.blue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: WbColors.muted,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TankerSelectionSheet extends StatelessWidget {
  const _TankerSelectionSheet({
    required this.tankCategories,
    required this.selectedTankId,
    required this.bookingState,
    required this.address,
    required this.onTankSelected,
    required this.onBook,
  });

  final List<TankCategory> tankCategories;
  final String selectedTankId;
  final LoadingButtonState bookingState;
  final String address;
  final ValueChanged<String> onTankSelected;
  final Future<void> Function() onBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your tanker',
            style: TextStyle(
              color: WbColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WbColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final tank = tankCategories[index];
                return _TankerOptionCard(
                  tank: tank,
                  selected: selectedTankId == tank.id,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTankSelected(tank.id);
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: tankCategories.length,
            ),
          ),
          const SizedBox(height: 18),
          LoadingFeedbackButton(
            onPressed: bookingState == LoadingButtonState.idle ? onBook : null,
            label: 'Book Water Now',
            loadingLabel: 'Matching nearby owners...',
            successLabel: 'Booking created',
            buttonState: bookingState,
            backgroundColor: WbColors.ink,
          ),
        ],
      ),
    );
  }
}

class _TankerOptionCard extends StatelessWidget {
  const _TankerOptionCard({
    required this.tank,
    required this.selected,
    required this.onTap,
  });

  final TankCategory tank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 170),
        scale: selected ? 1.03 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 184,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE0F2FE) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? WbColors.blue : WbColors.line,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: WbColors.blue.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Rs ${tank.effectivePrice}',
                    style: const TextStyle(
                      color: WbColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${tank.litres} litres',
                style: const TextStyle(
                  color: WbColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tank.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WbColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OlaStyleDrawer extends StatelessWidget {
  const _OlaStyleDrawer({required this.user, required this.support});

  final User? user;
  final String support;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.84,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.white.withValues(alpha: 0.94),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFE0F2FE),
                        backgroundImage: user?.photoURL == null
                            ? null
                            : NetworkImage(user!.photoURL!),
                        child: user?.photoURL == null
                            ? const Icon(Icons.person_rounded,
                                color: WbColors.blue, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'WaterBuddy User',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WbColors.ink,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.phoneNumber ??
                                  user?.email ??
                                  'Consumer account',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WbColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _WalletTile(),
                  const SizedBox(height: 20),
                  _DrawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Orders',
                    onTap: () => context.go(RouteNames.orders),
                  ),
                  _DrawerItem(
                    icon: Icons.home_work_rounded,
                    title: 'Addresses',
                    onTap: () => context.push(RouteNames.locationSelection),
                  ),
                  _DrawerItem(
                    icon: Icons.payment_rounded,
                    title: 'Payments',
                    onTap: () => context.push(RouteNames.payments),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () => context.push(RouteNames.appSettings),
                  ),
                  _DrawerItem(
                    icon: Icons.support_agent_rounded,
                    title: 'Support',
                    subtitle: support,
                    onTap: () => WaterBuddyToastService.info(
                      context,
                      'Support: $support',
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.info_rounded,
                    title: 'About WaterBuddy',
                    subtitle: 'Premium instant water logistics',
                    onTap: () => WaterBuddyToastService.info(
                      context,
                      'WaterBuddy V4',
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded, color: WbColors.red),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WbColors.red,
                      side: BorderSide(
                          color: WbColors.red.withValues(alpha: 0.25)),
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

class _WalletTile extends StatelessWidget {
  const _WalletTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WbColors.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Wallet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            'Rs 0',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: WbColors.ink, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: WbColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WbColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
      trailing: const Icon(Icons.chevron_right_rounded, color: WbColors.muted),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
