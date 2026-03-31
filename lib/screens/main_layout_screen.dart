import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/bottom_nav_bar.dart';
import 'contacts/contacts_screen.dart';
import 'companies/companies_screen.dart';
import 'deals/deals_screen.dart';
import 'home/home_screen.dart';
import 'leads/leads_screen.dart';
import 'settings/settings_screen.dart';
import 'tasks/tasks_screen.dart';

import '../services/push_notification_service.dart';
import '../widgets/animations/animated_indexed_stack.dart';
import '../widgets/org_switcher.dart';

// State provider for the current bottom nav index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  @override
  void initState() {
    super.initState();
    // Request permissions after layout is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.registerAfterLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final user = ref.watch(currentUserProvider);

    // Filter navigation items based on current user permissions
    final filteredItems = navigationItems
        .where((item) => item.checkPermission(user))
        .toList();

    // Safety check for index out of bounds after permission change
    final safeIndex = currentIndex >= filteredItems.length ? 0 : currentIndex;

    final List<Widget> screens =
        filteredItems.map((item) => item.screen).toList();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Desktop/Tablet Landscape: Show NavigationRail
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (index) {
                    ref.read(bottomNavIndexProvider.notifier).state = index;
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: const OrgSwitcher(isCompact: true),
                  destinations: filteredItems.map((item) {
                    return NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: AnimatedIndexedStack(
                    index: safeIndex,
                    children: screens,
                  ),
                ),
              ],
            );
          } else {
            // Mobile/Tablet Portrait: Show BottomNavigationBar
            return AnimatedIndexedStack(index: safeIndex, children: screens);
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width > 800
          ? null
          : CustomBottomNavBar(
              currentIndex: safeIndex,
              onTap: (index) {
                ref.read(bottomNavIndexProvider.notifier).state = index;
              },
              items: filteredItems,
            ),
    );
  }
}
