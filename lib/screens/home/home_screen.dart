import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/role_model.dart';
import '../../models/deal_model.dart';
import '../../providers/auth_provider.dart';
import 'widgets/dashboard_card.dart';
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
import '../activities/all_activities_screen.dart';
import '../../widgets/org_switcher.dart';
import '../../providers/organization_provider.dart';

import '../../core/services/permission_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildRecentActivityHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AllActivitiesScreen(),
              ),
            );
          },
          child: const Text('View All'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canViewAnalytics = PermissionService.canViewAnalytics(user);
    final canViewContacts = PermissionService.canViewContacts(user);
    final canViewLeads = PermissionService.canViewLeads(user);
    final canViewDeals = PermissionService.canViewDeals(user);
    final canViewTasks = PermissionService.canViewTasks(user);
    final canViewActivities = PermissionService.canViewActivities(user);

    final canCreateContacts = PermissionService.canCreateContacts(user);
    final canCreateLeads = PermissionService.canCreateLeads(user);
    final canCreateDeals = PermissionService.canCreateDeals(user);
    final canCreateTasks = PermissionService.canCreateTasks(user);

    final canCreateAnything = canCreateContacts || canCreateLeads || canCreateDeals || canCreateTasks;

    final dashboardMetrics = ref.watch(dashboardMetricsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final currentPeriod = ref.watch(dashboardPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const OrgSwitcher(),
        leadingWidth: 180,
        //title: const Text('Dashboard'),
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
      floatingActionButton: canCreateAnything
          ? FloatingActionButton(
              heroTag: 'home_fab',
              onPressed: () {
                _showQuickAddMenu(
                  context,
                  canCreateContacts: canCreateContacts,
                  canCreateLeads: canCreateLeads,
                  canCreateDeals: canCreateDeals,
                  canCreateTasks: canCreateTasks,
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardMetricsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1024;

              final mainContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInvitationBanner(context, ref),
                  FadeInSlide(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${user?.role.displayName ?? 'Dashboard'} Overview',
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
                              ref.read(dashboardPeriodProvider.notifier).state =
                                  value;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats Grid
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      int crossAxisCount = isWide ? 4 : (gridConstraints.maxWidth > 800 ? 3 : 2);
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: isWide ? 1.4 : 1.2,
                        children: [
                          if (canViewContacts)
                            _buildStatCard(
                              dashboardMetrics,
                              title: 'Total Contacts',
                              icon: Icons.people_outline,
                              color: Colors.blue,
                              valueKey: 'totalContacts',
                              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
                            ),
                          if (canViewLeads)
                            _buildStatCard(
                              dashboardMetrics,
                              title: 'Total Leads',
                              icon: Icons.leaderboard_outlined,
                              color: Colors.orange,
                              valueKey: 'totalLeads',
                              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 2,
                            ),
                          if (canViewDeals)
                            _buildStatCard(
                              dashboardMetrics,
                              title: 'Active Deals',
                              valueKey: 'totalDeals',
                              icon: Icons.handshake_outlined,
                              color: Colors.purple,
                              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 3,
                            ),
                          if (canViewAnalytics)
                            _buildStatCard(
                              dashboardMetrics,
                              title: 'Revenue (Won)',
                              valueKey: 'revenueWon',
                              icon: Icons.attach_money,
                              color: Colors.green,
                              isCurrency: true,
                              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 3,
                            ),
                          if (!canViewAnalytics)
                            FadeInSlide(
                              delay: 0.4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
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
                  // Pipeline
                  if (canViewDeals)
                    FadeInSlide(
                      delay: 0.2,
                    child: dashboardMetrics.when(
                      data: (stats) {
                        final rawPipeline = stats['rawPipeline'] as Map<String, int>? ?? {};
                        if (rawPipeline.isEmpty) return const SizedBox();
                        final Map<DealStage, int> pipeline = {};
                        for (var stage in DealStage.values) {
                          final snakeName = stage.name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
                          pipeline[stage] = (rawPipeline[stage.name] ?? 0) + (rawPipeline[snakeName] ?? 0);
                        }
                        if (pipeline.values.every((val) => val == 0))
                          return const SizedBox();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PipelineWidget(pipelineData: pipeline),
                            const SizedBox(height: 32),
                          ],
                        );
                      },
                      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                  // Revenue Trend Chart
                  if (canViewAnalytics) ...[
                    const FadeInSlide(delay: 0.3, child: RevenueTrendChart()),
                    const SizedBox(height: 32),
                  ],
                  if (!isWide) ...[
                    if (canViewTasks) ...[
                      const FadeInSlide(delay: 0.4, child: TasksDueTodayWidget()),
                      const SizedBox(height: 32),
                    ],
                    if (canViewActivities) ...[
                      _buildRecentActivityHeader(context, ref),
                      const SizedBox(height: 8),
                      const FadeInSlide(delay: 0.5, child: RecentActivityList()),
                    ],
                  ],
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: mainContent),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (canViewTasks) ...[
                            const FadeInSlide(delay: 0.1, child: TasksDueTodayWidget()),
                            const SizedBox(height: 32),
                          ],
                          if (canViewActivities) ...[
                            _buildRecentActivityHeader(context, ref),
                            const SizedBox(height: 12),
                            const FadeInSlide(delay: 0.2, child: RecentActivityList()),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }
              return mainContent;
            },
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

  void _showQuickAddMenu(
    BuildContext context, {
    required bool canCreateContacts,
    required bool canCreateLeads,
    required bool canCreateDeals,
    required bool canCreateTasks,
  }) {
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
                  if (canCreateContacts)
                    _quickActionBtn(
                      context,
                      icon: Icons.person_add_alt_1,
                      label: 'Contact',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEditContactScreen(),
                          ),
                        );
                      },
                    ),
                  if (canCreateLeads)
                    _quickActionBtn(
                      context,
                      icon: Icons.leaderboard,
                      label: 'Lead',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEditLeadScreen(),
                          ),
                        );
                      },
                    ),
                  if (canCreateDeals)
                    _quickActionBtn(
                      context,
                      icon: Icons.handshake,
                      label: 'Deal',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEditDealScreen(),
                          ),
                        );
                      },
                    ),
                  if (canCreateTasks)
                    _quickActionBtn(
                      context,
                      icon: Icons.check_circle_outline,
                      label: 'Task',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEditTaskScreen(),
                          ),
                        );
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

  Widget _quickActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationBanner(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(userInvitationsProvider);

    return invitesAsync.when(
      data: (invites) {
        if (invites.isEmpty) return const SizedBox.shrink();

        final invite = invites.first;
        final orgName = (invite['organizations'] as Map?)?['name'] ?? 'an organization';
        final inviteId = invite['id'] as String;

        return FadeInSlide(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.group_add, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Invitation!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'You have been invited to join $orgName',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Joining organization...')),
                      );
                      await ref.read(userInvitationsProvider.notifier).acceptInvitation(inviteId);
                      await ref.read(currentOrganizationProvider.notifier).refresh();
                      ref.invalidate(userOrganizationsProvider);
                      ref.invalidate(userInvitationsProvider);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Successfully joined!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
