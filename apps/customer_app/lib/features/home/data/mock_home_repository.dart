import '../models/home_dashboard.dart';

class MockHomeRepository {
  Future<HomeDashboard> getDashboard() async {
    return const HomeDashboard(
      brandName: 'WaterBuddy',
      userName: 'Pranav',
      userAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuACKgAl6YdnTg4VPquztprqnHIJf4G1peHWGsqipTv13216iMcQVMFoBEvge9FsEqVzbe0qxOUq1Z_3u75mbNniQa_YUNKZcxmRZAB8TErAJMflrWwkfQvB8g3x4G1Zt3ij42KY5QfVGRujmZqcKIvvk0NXfAGSDdUItvvjHsk4qO15GiQMdDZOjYaemogkSuSd3LH6NFstWPf3Z1OFm-IwNJynFiY78mJ_AvGrKPPzCnzvPhiZR3MiBu74KofT7ITGocoXmJxXuiw',
      heroBadgeLabel: 'Set delivery point',
      mapImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCC0t58EFVl-jJwFWMSegJqXIkOykl4aieFbREjMvSfCHqOZXspE3Ir3tkeFd4tsAh6L-VrP4UmC3vHU8tZ-SWPQpdG_Fklv7V1nGJhdBhXSs8adVwv776yEPaHgSJb7rVUlVsJR8nEGuiPqWzYJ7I3gprtxxzxGjVH-RwPlYttcYg-DkvSktCr9THVB7pWv4kUFV8qPXMp0Y2BMKZZN2Qj6prGSdzXYYPEg_HXA_TRYsnh41F7rFhCXGwsJkAyDI4OF6jOKmcZb-w',
      mapImageAlt:
          'High-angle satellite view of a clean city layout with water bodies and infrastructure.',
      capacityTitle: 'Select Tank Capacity',
      capacitySubtitle: 'High-quality spring water delivered to your doorstep.',
      tankOptions: [
        TankOption(
          id: 'small',
          label: 'Small',
          capacityLabel: '10,000L',
          priceLabel: '\$120',
          iconKey: 'opacity',
        ),
        TankOption(
          id: 'medium',
          label: 'Medium',
          capacityLabel: '15,000L',
          priceLabel: '\$165',
          iconKey: 'water_drop',
          isRecommended: true,
        ),
        TankOption(
          id: 'large',
          label: 'Large',
          capacityLabel: '20,000L',
          priceLabel: '\$210',
          iconKey: 'waves',
        ),
      ],
      bottomNavItems: [
        BottomNavItemData(id: 'home', label: 'Home', iconKey: 'home'),
        BottomNavItemData(id: 'history', label: 'History', iconKey: 'history'),
        BottomNavItemData(id: 'book', label: 'Book Now', iconKey: 'water_drop'),
        BottomNavItemData(id: 'profile', label: 'Profile', iconKey: 'person'),
      ],
    );
  }
}
