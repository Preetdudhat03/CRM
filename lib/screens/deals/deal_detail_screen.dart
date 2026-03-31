import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/deal_model.dart';
import '../../providers/deal_provider.dart';
import '../../widgets/activity_timeline.dart';
import '../widgets/files_list_view.dart';
import '../../core/services/permission_service.dart';
import '../../providers/auth_provider.dart';
import 'add_edit_deal_screen.dart';

class DealDetailScreen extends ConsumerStatefulWidget {
  final DealModel deal;

  const DealDetailScreen({super.key, required this.deal});

  @override
  ConsumerState<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends ConsumerState<DealDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(dealsProvider);
    final deal =
        dealsAsync.value?.firstWhere(
          (d) => d.id == widget.deal.id,
          orElse: () => widget.deal,
        ) ??
        widget.deal;

    final user = ref.watch(currentUserProvider);
    final canEdit = PermissionService.canEditDeals(user);
    final canDelete = PermissionService.canDeleteDeals(user);

    return Scaffold(
      appBar: AppBar(
        title: Text(deal.title),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditDealScreen(deal: deal),
                  ),
                );
              },
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, ref, deal),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Activity'),
            Tab(text: 'Files'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(deal),
          ActivityTimeline(relatedType: 'deal', relatedId: deal.id),
          FileListView(
            relatedType: 'deal',
            relatedId: deal.id,
            organizationId: deal.organizationId ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(DealModel deal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.layers_outlined,
                    'Stage',
                    deal.stage.label,
                    color: deal.stage.color,
                  ),
                  _buildDetailRow(
                    Icons.attach_money,
                    'Value',
                    '₹${deal.value.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                  _buildDetailRow(
                    Icons.business_outlined,
                    'Company',
                    deal.companyName,
                  ),
                  _buildDetailRow(
                    Icons.person_outline,
                    'Primary Contact',
                    deal.contactName,
                  ),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    'Expected Close',
                    deal.expectedCloseDate.toIso8601String().split('T')[0],
                  ),
                  _buildDetailRow(
                    Icons.account_circle_outlined,
                    'Owner',
                    deal.assignedTo,
                  ),
                ],
              ),
            ),
          ),
          if (deal.notes != null && deal.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Deal Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(deal.notes!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    DealModel deal,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deal'),
        content: Text('Are you sure you want to delete ${deal.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(dealsProvider.notifier).deleteDeal(deal.id);
              Navigator.pop(context);
              Navigator.pop(context); // Back to list
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${deal.title} deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
