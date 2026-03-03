import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/lead_model.dart';
import '../../providers/lead_provider.dart';
import '../../widgets/activity_timeline.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isConverting = false;
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

  void _convertLead() async {
    setState(() {
      _isConverting = true;
    });
    try {
      await ref.read(leadsProvider.notifier).convertLead(widget.lead.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead converted to Contact successfully!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error converting lead: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lead.name),
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
          _buildOverviewTab(),
          ActivityTimeline(relatedType: 'lead', relatedId: widget.lead.id),
        ],
      ),
      floatingActionButton: widget.lead.status != LeadStatus.converted
          ? FloatingActionButton.extended(
              onPressed: _isConverting ? null : _convertLead,
              label: const Text('Convert'),
              icon: _isConverting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.transform),
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
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
                    Icons.info_outline,
                    'Status',
                    widget.lead.status.label,
                  ),
                  _buildDetailRow(
                    Icons.email_outlined,
                    'Email',
                    widget.lead.email,
                  ),
                  _buildDetailRow(
                    Icons.phone_outlined,
                    'Phone',
                    widget.lead.phone,
                  ),
                  _buildDetailRow(
                    Icons.source_outlined,
                    'Source',
                    widget.lead.source,
                  ),
                  _buildDetailRow(
                    Icons.person_outline,
                    'Assigned to',
                    widget.lead.assignedTo,
                  ),
                  if (widget.lead.estimatedValue != null)
                    _buildDetailRow(
                      Icons.attach_money,
                      'Value',
                      '₹${widget.lead.estimatedValue!.toStringAsFixed(0)}',
                    ),
                ],
              ),
            ),
          ),
          if (widget.lead.notes != null && widget.lead.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Notes',
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
              child: Text(widget.lead.notes!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
