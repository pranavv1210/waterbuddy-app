import '../models/seller_dashboard.dart';

class MockSellerDashboardRepository {
  const MockSellerDashboardRepository();

  Future<SellerDashboard> fetchDashboard() async {
    return const SellerDashboard(
      sellerName: 'John Doe',
      businessName: 'AquaFlow Pro',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDf9OoEU_9irjpxWYLVegVzrGeitruNm3yudhhgFS9tF2r3zCUCvEoAsTHFhJusEYRceIXo3WksvUYvLSgdjrQ5K9-9e7wHqo6DffZ-tIV2F7dtYUuRa5UGRLr9-ARKOtB5AqnODloSZ1GpX7D_szNpsOsueRLVdxq6HY_TfUKi78jBS67nlZdl00tSafO6BX9gJxPp4sss2qtg054C7spZUwQRdv5CXSVATUTRkThdgsyg0Gdm82M1bM3aJc-iXSGzSt80lh8fF04',
      isOnline: true,
      todaysEarnings: '\$142.50',
      earningsChangeLabel: '+12% vs yesterday',
      activeTime: '5h 24m',
      efficiencyLabel: '94%',
      completedOrders: 8,
      ratingToday: 4.9,
      statusTitle: 'Waiting for orders...',
      statusMessage:
          "You're in a high-demand zone. Stay close for faster dispatch.",
    );
  }
}
