import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/location/google_maps_service.dart';
import '../../../widgets/waterbuddy_bottom_sheet.dart';
import '../../../widgets/waterbuddy_toast.dart';
import '../../orders/providers/order_providers.dart';

class _AddressSuggestion {
  const _AddressSuggestion({
    required this.placeId,
    required this.placeName,
    required this.secondaryAddress,
    required this.description,
  });

  final String placeId;
  final String placeName;
  final String secondaryAddress;
  final String description;

  String get fullAddress => description;
}

class LocationSelectionScreen extends ConsumerStatefulWidget {
  const LocationSelectionScreen({super.key, this.pickupAddress});

  final String? pickupAddress;

  @override
  ConsumerState<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState
    extends ConsumerState<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GoogleMapsService _googleMapsService = GoogleMapsService();
  bool _submitting = false;
  bool _loadingSuggestions = false;
  Timer? _debounce;
  List<_AddressSuggestion> _suggestions = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = const [];
        _loadingSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _loadingSuggestions = true);
    try {
      final googleSuggestions = await _googleMapsService.getSuggestions(query);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _suggestions = googleSuggestions
            .map((s) => _AddressSuggestion(
                  placeId: s.placeId,
                  placeName: s.mainText,
                  secondaryAddress: s.secondaryText,
                  description: s.description,
                ))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _suggestions = const []);
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _submitAddress(String value) async {
    final address = value.trim();
    if (address.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    final result = <String, dynamic>{
      'address': address,
      'location': {
        'latitude': 12.9716,
        'longitude': 77.5946,
        'address': address,
      },
    };

    try {
      final matches = await locationFromAddress(address)
          .timeout(const Duration(seconds: 4));
      if (matches.isNotEmpty) {
        result['location'] = {
          'latitude': matches.first.latitude,
          'longitude': matches.first.longitude,
          'address': address,
        };
      }
    } catch (_) {
      // Keep the typed address and fall back to Bengaluru coordinates.
    }

    if (mounted) context.pop(result);
  }

  Future<void> _selectSuggestion(_AddressSuggestion suggestion) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final coords =
          await _googleMapsService.getPlaceDetails(suggestion.placeId);
      if (coords != null && mounted) {
        context.pop({
          'address': suggestion.fullAddress,
          'location': {
            'latitude': coords.latitude,
            'longitude': coords.longitude,
            'address': suggestion.fullAddress,
          },
        });
      } else {
        if (mounted) {
          WaterBuddyToastService.error(
            context,
            'Failed to resolve coordinates for this location.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        WaterBuddyToastService.error(
          context,
          'Error resolving location details.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _submitting = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        WaterBuddyToastService.warning(
          context,
          'Location permission is required.',
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));
      var address = 'Current water delivery location';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 4));
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          address = [
            p.name,
            p.street,
            p.subLocality,
            p.locality,
          ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
        }
      } catch (_) {}
      if (!mounted) return;
      context.pop({
        'address': address,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': address,
        },
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openSavedAddresses(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) {
      WaterBuddyToastService.info(context, 'No saved delivery addresses yet');
      return;
    }

    showWaterBuddyBottomSheet<void>(
      context: context,
      child: SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: locations.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Saved delivery addresses',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }
            final loc = locations[index - 1];
            return ListTile(
              leading: const Icon(Icons.water_drop_rounded,
                  color: Color(0xFF0EA5E9)),
              title: Text(
                loc['address'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Use this water delivery address'),
              onTap: () {
                Navigator.pop(context);
                context.pop({
                  'location': loc['location'],
                  'address': loc['address'],
                });
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0F172A);
    const waterBlue = Color(0xFF0EA5E9);
    final history = ref.watch(orderHistoryProvider);
    final savedLocations = history.maybeWhen(
      data: (orders) {
        final uniqueLocations = <String, Map<String, dynamic>>{};
        for (final order in orders) {
          if (order.deliveryAddress != null) {
            uniqueLocations[order.deliveryAddress!] = {
              'address': order.deliveryAddress,
              'location': order.location,
            };
          }
        }
        return uniqueLocations.values.toList();
      },
      orElse: () => <Map<String, dynamic>>[],
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Water Delivery Address',
          style: TextStyle(color: primary, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: waterBlue.withValues(alpha: 0.28)),
                  boxShadow: [
                    BoxShadow(
                      color: waterBlue.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: waterBlue.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: waterBlue,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: false,
                        textInputAction: TextInputAction.search,
                        onChanged: _onQueryChanged,
                        onSubmitted: _submitAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your water delivery address',
                          border: InputBorder.none,
                          hintStyle: const TextStyle(color: Colors.grey),
                          suffixIcon: _submitting
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search_rounded),
                                  onPressed: () => _submitAddress(
                                    _searchController.text,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickOption(
                      icon: Icons.map_rounded,
                      label: 'Choose on map',
                      onTap: () => context.pop({'selectOnMap': true}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickOption(
                      icon: Icons.home_work_rounded,
                      label: 'Saved addresses',
                      onTap: () => _openSavedAddresses(savedLocations),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1, height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _searchController.text.trim().length >= 2
                    ? _SuggestionList(
                        suggestions: _suggestions,
                        loading: _loadingSuggestions,
                        onSelect: _selectSuggestion,
                      )
                    : _RecentAddressList(
                        history: history,
                        onUseCurrentLocation: _useCurrentLocation,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.suggestions,
    required this.loading,
    required this.onSelect,
  });

  final List<_AddressSuggestion> suggestions;
  final bool loading;
  final ValueChanged<_AddressSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    if (loading && suggestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (suggestions.isEmpty) {
      return const Center(
        child: Text(
          'Keep typing to search delivery addresses',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
        ),
      );
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: suggestions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onSelect(suggestion),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: Color(0xFF0EA5E9)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.placeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        suggestion.secondaryAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecentAddressList extends StatelessWidget {
  const _RecentAddressList({
    required this.history,
    required this.onUseCurrentLocation,
  });

  final AsyncValue<dynamic> history;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return history.when(
      data: (orders) {
        final uniqueLocations = <String, Map<String, dynamic>>{};
        for (final order in orders) {
          if (order.deliveryAddress != null) {
            uniqueLocations[order.deliveryAddress!] = {
              'address': order.deliveryAddress,
              'location': order.location,
            };
          }
        }
        final locations = uniqueLocations.values.toList();
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ListTile(
              leading: const Icon(Icons.my_location_rounded,
                  color: Color(0xFF0EA5E9)),
              title: const Text('Use current location',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Detect this phone location for delivery'),
              onTap: onUseCurrentLocation,
            ),
            const Divider(height: 1),
            if (locations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: Text(
                    'No recent delivery addresses',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              ...locations.map(
                (loc) => ListTile(
                  leading: const Icon(Icons.water_drop_rounded,
                      color: Color(0xFF0EA5E9)),
                  title: Text(
                    loc['address'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: const Text('Previous water delivery address',
                      style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey),
                  onTap: () => context.pop({
                    'location': loc['location'],
                    'address': loc['address'],
                  }),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _QuickOption extends StatelessWidget {
  const _QuickOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: const Color(0xFF0F172A)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
