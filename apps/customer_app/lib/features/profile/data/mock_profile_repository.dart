import '../models/profile_dashboard.dart';

class MockProfileRepository {
  Future<ProfileDashboard> getProfileDashboard() async {
    return const ProfileDashboard(
      brandName: 'WaterBuddy',
      userAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCpRid9fFTGM87yUgIbK_l0z1dwMOanCqF81bCJju_1zSxwb1NMSazpcBnJ_V0kVlVPOKSxABpCcjEKr_HySCFmwXha-9qDl0LWHT9HtIQCstD56nv6XXmyKyrtyKKa3d2HrgbJ8QL4iGfa6hM3GWQt9FCju6XwkiRQ5CmZlyWsFlpQnq4lC9-swnQ_WalEZ7Nnr_gmjO9UpaM1On0QXstVRENl4JMeHNgLKVu0rCVMF9jbZNNuLgsaVhRyz0-wWUC4GkoIJQjxJBU',
      profileImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAqqcs8X7zTLJ-2V1yT740YNI5ERnbtA9fVs2XTNKrB0wAs5T4jh9aAjWQMSAu5MMU2ddCKM-jzhOqZkXqneZ4XoB-s7-3ywFL5SXBMYTd6-1hE8TzL12uq0Ob-dPIVXEwPKw29ac9BiCsaqHzEUee83yGLu1ABXOEJX0zPqjbNCcU-vDZdD_NEChkS_G6V3PLOrGLLI2Jf3OSk3demw4vhtTwLayMu2OTM1tKIgcDWUcc1brI5Mqqe93vSiiuDouUOR8msjc_gMfs',
      profileName: 'Alex Thompson',
      email: 'alex.thompson@gmail.com',
      membershipLabel: 'Premium Member',
      completedOrdersLabel: '12 Orders Completed',
      topNavItems: [
        ProfileNavItem(id: 'home', label: 'Home', iconKey: 'home'),
        ProfileNavItem(id: 'history', label: 'History', iconKey: 'history'),
        ProfileNavItem(id: 'book', label: 'Book Now', iconKey: 'water_drop'),
        ProfileNavItem(id: 'profile', label: 'Profile', iconKey: 'person'),
      ],
      recentOrders: [
        ProfileOrderItem(
          id: 'order_1',
          title: 'Premium Spring Water (20L)',
          subtitle: 'Oct 24, 2023 - Delivered',
          amountLabel: '\$18.50',
          iconKey: 'water_drop',
        ),
        ProfileOrderItem(
          id: 'order_2',
          title: 'Standard Refill (x2)',
          subtitle: 'Oct 18, 2023 - Delivered',
          amountLabel: '\$24.00',
          iconKey: 'opacity',
        ),
      ],
      paymentMethods: [
        PaymentMethodCard(
          id: 'primary_card',
          title: 'Primary Card',
          maskedNumber: '•••• •••• •••• 4291',
          expiryLabel: '12/26',
          brandImageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuA2gYEoysniFtkF3_sQpgBR8QU3jVIHcc2DeSMuNCaeV56qKj_mJTudemUhljFxH0-DhWzzgdn4t-nVFGI4fuf-P7wWW0JzuUsPdJ4okS3RdZyMLmp13rIw-xBbxfBAVs8YnH2W9cJ7kRDyHERodlkZfS5_f0d5srj7BIvB3No671WQag0d0tebVcCDGJqGYdv3YgnB-mS_v3wPmd2j3asnNkwb9Q2HeG_pGFL21SP5KgRmxX_fajEEA-Xhpq424kgwJXZDfQHKDB4',
          brandImageAlt: 'Visa logo',
          isPrimary: true,
        ),
        PaymentMethodCard(
          id: 'add_new_card',
          title: 'Add New Card',
          maskedNumber: '',
          expiryLabel: '',
          brandImageUrl: '',
          brandImageAlt: '',
          isAddNew: true,
        ),
      ],
      supportEmail: 'waterbuddyapp.wb@gmail.com',
      supportItems: [
        SupportActionItem(
          id: 'faq',
          title: 'FAQ & Tutorials',
          iconKey: 'help_outline',
        ),
        SupportActionItem(
          id: 'chat',
          title: 'Live Chat',
          iconKey: 'chat_bubble_outline',
        ),
        SupportActionItem(
          id: 'privacy',
          title: 'Privacy Policy',
          iconKey: 'policy',
        ),
      ],
      bottomNavItems: [
        ProfileNavItem(id: 'home', label: 'Home', iconKey: 'home'),
        ProfileNavItem(id: 'history', label: 'History', iconKey: 'history'),
        ProfileNavItem(id: 'book', label: 'Book Now', iconKey: 'water_drop'),
        ProfileNavItem(id: 'profile', label: 'Profile', iconKey: 'person'),
      ],
    );
  }
}
