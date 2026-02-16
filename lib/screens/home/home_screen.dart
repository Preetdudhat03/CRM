
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/permission_model.dart';
import '../../models/role_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/dashboard_card.dart';
import '../../providers/contact_provider.dart';
import '../../providers/deal_provider.dart';
import '../../providers/lead_provider.dart';
import 'widgets/recent_activity_widget.dart';
import '../../widgets/animations/fade_in_slide.dart';
import '../main_layout_screen.dart';

import '../../core/services/permission_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canViewAnalytics = PermissionService.canViewAnalytics(user);

    final contactStats = ref.watch(contactStatsProvider);
    final dealStats = ref.watch(dealStatsProvider);
    final leadStats = ref.watch(leadStatsProvider);

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
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(contactsProvider.notifier).getContacts(),
            ref.read(leadsProvider.notifier).getLeads(),
            ref.read(dealsProvider.notifier).getDeals(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInSlide(
                child: Text(
                  'Dashboard Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth > 600) crossAxisCount = 3;
                  if (constraints.maxWidth > 900) crossAxisCount = 4;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: constraints.maxWidth > 600 ? 1.5 : 1.2, // Adjust aspect ratio for wider cards
                    children: [
                   // Dynamic Stats Cards
                  FadeInSlide(
                    delay: 0.1,
                    child: _buildStatCard(
                      contactStats,
                      title: 'Total Contacts',
                      icon: Icons.people_outline,
                      color: Colors.blue,
                      valueKey: 'total',
                      onTap: () {
                        ref.read(bottomNavIndexProvider.notifier).state = 1; // Contacts Tab
                      },
                    ),
                  ),
                  FadeInSlide(
                    delay: 0.2,
                    child: _buildStatCard(
                      leadStats, // Using correct Leads Provider
                      title: 'Total Leads',
                      icon: Icons.leaderboard_outlined,
                      color: Colors.orange,
                      valueKey: 'total', // Using 'total' key for leads
                      onTap: () {
                        ref.read(bottomNavIndexProvider.notifier).state = 2; // Leads Tab
                      },
                    ),
                  ),
                  FadeInSlide(
                    delay: 0.3,
                    child: _buildStatCard(
                      dealStats,
                      title: 'Active Deals',
                      valueKey: 'activeCount',
                      icon: Icons.handshake_outlined,
                      color: Colors.purple,
                      onTap: () {
                        ref.read(bottomNavIndexProvider.notifier).state = 3; // Deals Tab
                      },
                    ),
                  ),
                  // Revenue Card - Restricted Access
                  if (canViewAnalytics)
                    FadeInSlide(
                      delay: 0.4,
                      child: _buildStatCard(
                        dealStats,
                        title: 'Revenue (Won)',
                        valueKey: 'revenueWon',
                        icon: Icons.attach_money,
                        color: Colors.green,
                        isCurrency: true,
                        onTap: () {
                          // Navigate to Analytics/Deals or show breakdown
                          ref.read(bottomNavIndexProvider.notifier).state = 3;
                        },
                      ),
                    )
                  else
                    FadeInSlide(
                      delay: 0.4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
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
                    ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              FadeInSlide(
                delay: 0.5,
                child: Row(
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
              ),
              const SizedBox(height: 8),
              FadeInSlide(delay: 0.6, child: const RecentActivityList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    AsyncValue<Map<String, dynamic>> statsAsync, {
    required String title,
    required IconData icon,
    required Color color,
    required String valueKey,
    bool isCurrency = false,
    VoidCallback? onTap,
  }) {
    return statsAsync.when(
      data: (stats) {
        final value = stats[valueKey];
        String displayValue = '0';
        if (value != null) {
            if (isCurrency && value is num) {
                // Simple currency formatting for now, ideally use NumberFormat
                displayValue = '\$${value.toStringAsFixed(0)}'; 
            } else {
                displayValue = value.toString();
            }
        }
        
        return DashboardCard(
        title: title,
        value: displayValue,
        icon: icon,
        color: color,
        onTap: onTap,
      );
      },
      loading: () => DashboardCard(
        title: title,
        value: '...',
        icon: icon,
        color: color,
        onTap: onTap,
      ),
      error: (_, __) => DashboardCard(
        title: title,
        value: '-',
        icon: icon,
        color: color.withOpacity(0.5),
        onTap: onTap,
      ),
    );
  }
}
