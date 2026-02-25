
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/permission_model.dart';
import '../../models/role_model.dart';
import '../../models/user_model.dart';
import '../../models/deal_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/dashboard_card.dart';
import '../../providers/contact_provider.dart';
import '../../providers/deal_provider.dart';
import '../../providers/lead_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/recent_activity_widget.dart';
import 'widgets/pipeline_widget.dart';
import 'widgets/tasks_due_today_widget.dart';
import 'widgets/revenue_trend_chart_widget.dart';
import '../../widgets/animations/fade_in_slide.dart';
import '../main_layout_screen.dart';
import '../notifications/notifications_screen.dart';
import '../contacts/add_edit_contact_screen.dart';
import '../leads/add_edit_lead_screen.dart';
import '../deals/add_edit_deal_screen.dart';
import '../tasks/add_edit_task_screen.dart';
import '../../providers/notification_provider.dart';

import '../../core/services/permission_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canViewAnalytics = PermissionService.canViewAnalytics(user);

    final dashboardMetrics = ref.watch(dashboardMetricsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final currentPeriod = ref.watch(dashboardPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor,
              child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                  ? Text(
                      (user?.name ?? 'G').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    )
                  : null,
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickAddMenu(context);
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardMetricsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInSlide(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dashboard Overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    DropdownButton<DashboardPeriod>(
                      value: currentPeriod,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      items: DashboardPeriod.values.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(period.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(dashboardPeriodProvider.notifier).state = value;
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 800) {
                    crossAxisCount = 3;
                  }

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.3, // Adjust aspect ratio for better look on wide screens
                    children: [
                      // Dynamic Stats Cards
                      FadeInSlide(
                        delay: 0.1,
                        child: _buildStatCard(
                          dashboardMetrics,
                          title: 'Total Contacts',
                          icon: Icons.people_outline,
                          color: Colors.blue,
                          valueKey: 'totalContacts',
                          onTap: () {
                            ref.read(bottomNavIndexProvider.notifier).state = 1; // Contacts Tab
                          },
                        ),
                      ),
                      FadeInSlide(
                        delay: 0.2,
                        child: _buildStatCard(
                          dashboardMetrics,
                          title: 'Total Leads',
                          icon: Icons.leaderboard_outlined,
                          color: Colors.orange,
                          valueKey: 'totalLeads',
                          onTap: () {
                            ref.read(bottomNavIndexProvider.notifier).state = 2; // Leads Tab
                          },
                        ),
                      ),
                      FadeInSlide(
                        delay: 0.3,
                        child: _buildStatCard(
                          dashboardMetrics,
                          title: 'Active Deals',
                          valueKey: 'totalDeals',
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
                            dashboardMetrics,
                            title: 'Revenue (Won)',
                            valueKey: 'revenueWon',
                            icon: Icons.attach_money,
                            color: Colors.green,
                            isCurrency: true,
                            onTap: () {
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
              
              // Tasks Due Today Snapshot
              const FadeInSlide(
                delay: 0.4,
                child: TasksDueTodayWidget(),
              ),
              const SizedBox(height: 32),
              
              // Deal Pipeline Horizontal Snapshot
              FadeInSlide(
                delay: 0.45,
                child: dashboardMetrics.when(
                  data: (stats) {
                    final rawPipeline = stats['rawPipeline'] as Map<String, int>? ?? {};
                    if (rawPipeline.isEmpty) return const SizedBox();
                    
                    final Map<DealStage, int> pipeline = {};
                    for (var stage in DealStage.values) {
                      // Check both camelCase (e.g. closedWon) and snake_case (closed_won)
                      final snakeName = stage.name.replaceAllMapped(
                        RegExp(r'[A-Z]'),
                        (m) => '_${m.group(0)!.toLowerCase()}',
                      );
                      pipeline[stage] = (rawPipeline[stage.name] ?? 0) + (rawPipeline[snakeName] ?? 0);
                    }

                    if (pipeline.values.every((val) => val == 0)) return const SizedBox();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PipelineWidget(pipelineData: pipeline),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, __) => Text('Error loading pipeline: $error'),
                ),
              ),
              const SizedBox(height: 32),

              // Revenue Trend Chart (only if user has analytics permission)
              if (canViewAnalytics)
                const FadeInSlide(
                  delay: 0.48,
                  child: RevenueTrendChart(),
                ),
              if (canViewAnalytics) const SizedBox(height: 32),

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
    String? trendKey,
    String? isUpTrendKey,
    bool isCurrency = false,
    VoidCallback? onTap,
  }) {
    return statsAsync.when(
      data: (stats) {
        final value = stats[valueKey];
        final double? trend = trendKey != null ? stats[trendKey] : null;
        final bool? isUp = isUpTrendKey != null ? stats[isUpTrendKey] : null;
        
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
        trendPercentage: trend,
        isUpTrend: isUp,
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

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _quickActionBtn(
                    context, 
                    icon: Icons.person_add_alt_1, 
                    label: 'Contact', 
                    color: Colors.blue, 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditContactScreen()));
                    },
                  ),
                  _quickActionBtn(
                    context, 
                    icon: Icons.leaderboard, 
                    label: 'Lead', 
                    color: Colors.orange, 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditLeadScreen()));
                    },
                  ),
                  _quickActionBtn(
                    context, 
                    icon: Icons.handshake, 
                    label: 'Deal', 
                    color: Colors.purple, 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditDealScreen()));
                    },
                  ),
                  _quickActionBtn(
                    context, 
                    icon: Icons.check_circle_outline, 
                    label: 'Task', 
                    color: Colors.green, 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditTaskScreen()));
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickActionBtn(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}
