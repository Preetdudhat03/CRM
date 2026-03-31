import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/permission_service.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/contacts/contacts_screen.dart';
import '../../screens/companies/companies_screen.dart';
import '../../screens/leads/leads_screen.dart';
import '../../screens/deals/deals_screen.dart';
import '../../screens/tasks/tasks_screen.dart';
import '../../screens/settings/settings_screen.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  final bool Function(UserModel?) checkPermission;

  const NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
    required this.checkPermission,
  });
}

final List<NavItem> navigationItems = [
  NavItem(
    label: 'Home',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    screen: const HomeScreen(),
    checkPermission: (_) => true, // Everyone can see home
  ),
  NavItem(
    label: 'Contacts',
    icon: Icons.people_outlined,
    selectedIcon: Icons.people,
    screen: const ContactsScreen(),
    checkPermission: (user) => PermissionService.canViewContacts(user),
  ),
  NavItem(
    label: 'Companies',
    icon: Icons.business_outlined,
    selectedIcon: Icons.business,
    screen: const CompaniesScreen(),
    checkPermission: (user) => PermissionService.canViewContacts(user), // Using Contacts perm for Companies
  ),
  NavItem(
    label: 'Leads',
    icon: Icons.leaderboard_outlined,
    selectedIcon: Icons.leaderboard,
    screen: const LeadsScreen(),
    checkPermission: (user) => PermissionService.canViewLeads(user),
  ),
  NavItem(
    label: 'Deals',
    icon: Icons.handshake_outlined,
    selectedIcon: Icons.handshake,
    screen: const DealsScreen(),
    checkPermission: (user) => PermissionService.canViewDeals(user),
  ),
  NavItem(
    label: 'Tasks',
    icon: Icons.task_alt_outlined,
    selectedIcon: Icons.task_alt,
    screen: const TasksScreen(),
    checkPermission: (user) => PermissionService.canViewTasks(user),
  ),
  NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    screen: const SettingsScreen(),
    checkPermission: (_) => true, // Everyone can see settings
  ),
];
