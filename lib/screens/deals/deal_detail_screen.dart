import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/deal_model.dart';
import '../../providers/deal_provider.dart';
import '../../widgets/activity_timeline.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(deal.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Navigate to edit
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(deal),
          ActivityTimeline(relatedType: 'deal', relatedId: deal.id),
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
}
