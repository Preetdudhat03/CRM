
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/bottom_nav_bar.dart';
import 'contacts/contacts_screen.dart';
import 'deals/deals_screen.dart';
import 'home/home_screen.dart';
import 'leads/leads_screen.dart';
import 'settings/settings_screen.dart';
import 'tasks/tasks_screen.dart';

import '../services/push_notification_service.dart';
import '../widgets/animations/animated_indexed_stack.dart';

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

    final List<Widget> screens = [
      const HomeScreen(),
      const ContactsScreen(),
      const LeadsScreen(),
      const DealsScreen(),
      const TasksScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Desktop/Tablet Landscape: Show NavigationRail
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) {
                     ref.read(bottomNavIndexProvider.notifier).state = index;
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outlined),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Contacts'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.leaderboard_outlined),
                      selectedIcon: Icon(Icons.leaderboard),
                      label: Text('Leads'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.handshake_outlined),
                      selectedIcon: Icon(Icons.handshake),
                      label: Text('Deals'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.task_alt_outlined),
                      selectedIcon: Icon(Icons.task_alt),
                      label: Text('Tasks'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: AnimatedIndexedStack(
                    index: currentIndex,
                    children: screens,
                  ),
                ),
              ],
            );
          } else {
            // Mobile/Tablet Portrait: Show BottomNavigationBar
            return AnimatedIndexedStack(
              index: currentIndex,
              children: screens,
            );
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width > 800
          ? null
          : CustomBottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) {
                ref.read(bottomNavIndexProvider.notifier).state = index;
              },
            ),
    );
  }
}
