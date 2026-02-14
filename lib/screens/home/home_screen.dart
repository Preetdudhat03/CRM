
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/permission_model.dart';
import '../../models/role_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/dashboard_card.dart';
import 'widgets/recent_activity_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final permissions = ref.watch(userPermissionsProvider);
    final canViewAnalytics = permissions.contains(Permission.viewAnalytics);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=preet'),
              radius: 18,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user?.name ?? "Guest"}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  user?.role.displayName ?? "Viewer",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const DashboardCard(
                  title: 'Total Contacts',
                  value: '1,245',
                  icon: Icons.people_outline,
                  color: Colors.blue,
                ),
                const DashboardCard(
                  title: 'Total Leads',
                  value: '48',
                  icon: Icons.leaderboard_outlined,
                  color: Colors.orange,
                ),
                const DashboardCard(
                  title: 'Active Deals',
                  value: '12',
                  icon: Icons.handshake_outlined,
                  color: Colors.purple,
                ),
                // Revenue Card - Restricted Access
                if (canViewAnalytics)
                  const DashboardCard(
                    title: 'Revenue (Q1)',
                    value: '\$42,500',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Access Restricted'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const RecentActivityList(),
          ],
        ),
      ),
    );
  }
}
