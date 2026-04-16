import '../models/completed_order.dart';

class MockCompletedOrderRepository {
  Future<CompletedOrder> getCompletedOrder() async {
    return const CompletedOrder(
      brandName: 'WaterBuddy',
      userAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBiI25DQcd6LHowxgADsWW9X2rPAKZKCGBQT6ruW0htGxTAAdSPqCV9WunQpYLBFlCoUUWyharCbl9i7hj4idwtxROAqT8UjGZ3n2LTIU1MfEuo6ah0cwIODK62OCzXwziFk67Qjt7RSo694Wqj5xy-n3cCGri66xWNBCGg_K59s0OvkO9boV0y0PwCvlwpWYc4TnmlhADMQ6ugvMHYbBPZouDUtTA5mlU1VT8J9kFbirHrL8jOSQa_Wxt_NlMcmZ3tst5MGVhoPVM',
      successTitle: 'Order Complete!',
      successSubtitle: 'Your premium hydration has been delivered. Stay refreshed!',
      deliveryTime: '12:45 PM',
      deliveryStatus: 'On-time Delivery',
      dropLocation: '42nd Avenue, Glass Tower, Lobby A',
      mapImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBbpdgtrIadQ53V0JqXgPQ_AbGQCbxkSCmoYUuVnrQD_17dAhN647Cv2CcaReodQzOk9VA1DRE0V9WkIWrzXLLPnDQ2vRs0SWQIRaen78QjuTp8Ie-exZqmIRgNtZuaCXLT13WHi_yjfLZzJkwxBLdR0BhNcNXjsr_Ph7_NtF1jEXzcfc3LPVq7UPyJ7wYyw5DX8TurEfXMKAK-emRW2_LDeny0PWPgBNRpa0sDjbFkE0x3aSrm7ZANNnXI7qscxYYQa93vvi_Vh9U',
      orderId: '#WB-88291',
      items: [
        CompletedOrderItem(
          name: 'Alkaline 5G',
          quantityLabel: '2 Units',
          amountLabel: '\$24.00',
        ),
      ],
      ratingTitle: 'Rate your experience',
      ratingSubtitle: 'How was your WaterBuddy delivery today?',
      feedbackCta: 'Submit Feedback',
      navItems: [
        CompletedOrderNavItem(id: 'home', label: 'Home', iconKey: 'home'),
        CompletedOrderNavItem(id: 'history', label: 'History', iconKey: 'history'),
        CompletedOrderNavItem(id: 'book', label: 'Book Now', iconKey: 'water_drop'),
        CompletedOrderNavItem(id: 'profile', label: 'Profile', iconKey: 'person'),
      ],
    );
  }
}
