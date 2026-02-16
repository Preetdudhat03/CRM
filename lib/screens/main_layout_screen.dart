
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/bottom_nav_bar.dart';
import 'contacts/contacts_screen.dart';
import 'deals/deals_screen.dart';
import 'home/home_screen.dart';
import 'leads/leads_screen.dart';
import 'settings/settings_screen.dart';
import 'tasks/tasks_screen.dart';

import '../widgets/animations/animated_indexed_stack.dart';

// State provider for the current bottom nav index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainLayoutScreen extends ConsumerWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          if (constraints.maxWidth < 600) {
            // Mobile Layout
            return AnimatedIndexedStack(
              index: currentIndex,
              children: screens,
            );
          } else {
            // Desktop/Tablet Layout
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
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Contacts'),
                    ),
                     NavigationRailDestination(
                      icon: Icon(Icons.leaderboard_outlined),
                      selectedIcon: Icon(Icons.leaderboard),
                      label: Text('Leads'),
                    ),
                     NavigationRailDestination(
                      icon: Icon(Icons.monetization_on_outlined),
                      selectedIcon: Icon(Icons.monetization_on),
                      label: Text('Deals'),
                    ),
                     NavigationRailDestination(
                      icon: Icon(Icons.task_outlined),
                      selectedIcon: Icon(Icons.task),
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
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? CustomBottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) {
                ref.read(bottomNavIndexProvider.notifier).state = index;
              },
            )
          : null,
    );
  }
}
