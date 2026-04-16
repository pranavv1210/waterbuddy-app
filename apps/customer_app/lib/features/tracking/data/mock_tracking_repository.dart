import '../models/assigned_order_tracking.dart';

class MockTrackingRepository {
  Future<AssignedOrderTracking> getAssignedOrder() async {
    return const AssignedOrderTracking(
      brandName: 'WaterBuddy',
      screenTitle: 'Live Tracking',
      userAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBKYBzLPIYcnuoN4whWG4dSjvWL18ixbx0iOyLgh5qdyZRz1hRQolWYHoWBEgorarl6E8z0oDXUFoWKhPv_znAPHEUuHaMYwblKNyQ0ulRvsjQIBdPYVop2kH70Po1B9ApjQ4MpeaRjBR4Ob2HLvNwYBuuyux-yGIyzANToOjmyN9_fQBGG1R9arlRIfxbWWhT8aC3O8bDuT4VIp2fk8H-lAA-8alZ4GWG3N7ru35KjAQByYfcprGY9FY-cp9a1BxZjlCQetwuJgGQ',
      mapImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDlA-fP8yt38-y1g8bf1wdt36Cdfh9ekITYsaLLEtDYWuoZFrWSawEvirD8eaO_sCoecplOT83DUTYdEijuI4wpPwqcFFDZUN8rDSV3FD79vXl970p8aSQei4kNA9MS01pQa8fRFZ39koTembIM7LoEYleDt9sRwprZp-5Mj82uUFrnN1akWMK65gMOIUN7CB-dlsK-eRelZgGIOC-OZHrY1JkZvXakh9F3ujW8BUdrD-HvqMWYsG23wuEmpjvZMiXYeVwB2zTtb9g',
      cityLabel: 'San Francisco',
      liveTrackingLabel: 'Live Tracking',
      orderId: 'Order #WB-8892',
      truckBadgeLabel: 'WATER TRUCK 402',
      estimatedArrivalClock: '12:45',
      estimatedArrivalLabel: 'In 12 minutes',
      estimatedArrival: '12 mins',
      distanceLabel: '2.4 km',
      statusTitle: 'On the way',
      statusSubtitle: 'Your water tanker is 2.4 km away',
      driver: DriverAssignment(
        name: 'Marcus Thompson',
        roleLabel: '4.9 - 1.2k Deliveries',
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCtknegMMQXU4UBnPm_Kn_SMxDGyPpf1dM6E3TfS_Bkmol8fNsqPw_1SZdCaYQWO8gJhBRUuCIa208kvlyHsXB94Ps5iExRZomszhuEWyugT0KMt-jSzZhHqjlYjv-KJh3m-X7AEx0lbNjrHATirGtjx88xM_M8rOlvevL-QVoJawgCSKPDUwTKW84ObdTnWRiEnBofuj0sC7hNrWbFNjnBBjxLpXwYliA-DfKn-RxBUjtxKAGxik6QKhnjf34F00TT2apTQrZXidw',
        ratingLabel: '4.9',
        idLabel: 'Verified Driver',
        deliveriesLabel: '1.2k Deliveries',
      ),
      vehicle: VehicleAssignment(
        typeLabel: 'Truck 402',
        plateLabel: 'WB-8892',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBe9W4edaTcX-6JWgHjTlwhvxyETH7HkfOaG8NW9AGMcX2jf_OFuUKN0OLJ1B2dpeWtIDGE7yOwiOo4zADcS8qsJRsO8Qvj4iBjhgMEDbvTI1q3icvgyRDrs7J84Pg5TFYKkkMiBppcwjNmR1f1xmUI10hheOKJOWeinNoKvs_kI8q8-H2yqDG8n5iUvjmMEwaRH_PMx30C7E08MSPw3BIwrz7zNBv7TpBE6H0VslmlzV9Cs-OV8jmtmKDG9S8nhi-V5oxixkiuwKQ',
        capacityLabel: '5000L',
      ),
      orderSummary: OrderSummary(
        amountLabel: 'Order Details',
        description: 'See order details and next actions',
        ctaLabel: 'Order Details',
      ),
      navItems: [
        TrackingNavItem(id: 'home', label: 'Home', iconKey: 'home'),
        TrackingNavItem(id: 'history', label: 'History', iconKey: 'history'),
        TrackingNavItem(id: 'book', label: 'Book Now', iconKey: 'water_drop'),
        TrackingNavItem(id: 'profile', label: 'Profile', iconKey: 'person'),
      ],
    );
  }
}
