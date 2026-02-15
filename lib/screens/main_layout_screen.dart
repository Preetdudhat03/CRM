
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
      body: AnimatedIndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
