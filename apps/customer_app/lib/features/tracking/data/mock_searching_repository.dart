import '../models/searching_tankers_state.dart';

class MockSearchingRepository {
  Future<SearchingTankersState> getSearchingState() async {
    return const SearchingTankersState(
      title: 'Finding nearby tankers...',
      userAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAXWUaWZFNV98FIY16-sdNiUnUEhXz1-cluIthuk7cllfLy3FWue5hFUcn0eVWzu40Z-8mfa2SQDWMtmTm_UpwrRXh7bIykblaserGx25nvMHWQoybNlyc5jTwoBrKcxKwHORSOSt25KsIfZFgZG6ezST5I_GvK60QZRRwRYIgWTE3qOT8pGYb1IktY0g4pnMaY0DQQHz1UfZMGZoXcbLQLxZkYadOVr5VvUtP8y1dIBNt9cQ8hXSpL7Lud4lfnHEat_gwFD4nT9A0',
      mapImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAE1_PMH3SRT0O6ll8cWGfmgYpy0eYo57aFcoLss3RFUD57xz1d_xpop0iiPMHqrjLK94QJDoueNzrV2PKCByqgKc59f50x-3qArfyzXpM0KXTZ8VFjETJI785GZiNSjbL_s26MujVsNmYB6AFenfbAWuTUZN88q91TBqUgzgmBVkipUUX-2guNJMDxrisjMGh8H8uYB51WFrf3vKLOsHGXmLvStkDoNVam5IxS7cUaffbXJ4ARbTthhVT-IkagXq5iYZiGuMeuSTs',
      mapLocationLabel: 'San Francisco',
      vehicleDistances: ['4.2km', '1.8km'],
      scanTitle: 'Scanning Grid B-12',
      scanSubtitle: 'Identifying 4 active vehicles nearby',
      connectionLabel: 'Connecting to server...',
      connectionBadge: 'ENCRYPTED',
      footerMessage:
          'Please wait while we secure the best pricing for your delivery location.',
      cancelLabel: 'Cancel Search',
    );
  }
}
