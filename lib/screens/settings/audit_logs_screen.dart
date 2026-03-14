import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/audit_log_provider.dart';
import '../../models/audit_log_model.dart';
import '../../widgets/animations/fade_in_slide.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(paginatedAuditLogsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auditLogsState = ref.watch(paginatedAuditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      body: auditLogsState.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No audit logs found.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh is just clearing filters and reloading or just reloading
              ref.read(paginatedAuditLogsProvider.notifier).loadMore();
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: logs.length + (ref.read(paginatedAuditLogsProvider.notifier).hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == logs.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final log = logs[index];
                return FadeInSlide(
                  delay: (index % 10) * 0.05,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                        log.actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('By: \${log.userEmail ?? 'System'}'),
                          Text('Entity: \${log.entityType} (\${log.entityId ?? 'N/A'})'),
                          Text('Time: \${DateFormat('MMM d, y, h:mm a').format(log.createdAt)}'),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      isThreeLine: true,
                      onTap: () => _showDiffDialog(context, log),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, __) => Center(child: Text('Error loading logs: \$error')),
      ),
    );
  }

  void _showDiffDialog(BuildContext context, AuditLogModel log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            const JsonEncoder encoder = JsonEncoder.withIndent('  ');
            final oldStr = log.oldValues != null ? encoder.convert(log.oldValues) : 'None';
            final newStr = log.newValues != null ? encoder.convert(log.newValues) : 'None';

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit Log Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Action: \${log.actionLabel}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('User: \${log.userEmail ?? 'System'}'),
                  Text('Time: \${log.createdAt}'),
                  const Divider(height: 32),
                  const Text('Old Values:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Text(oldStr, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('New Values:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(newStr, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    // A simplified filter layout
    final filter = ref.read(auditLogFilterProvider);
    String? selectedAction = filter.action;
    String? selectedEntity = filter.entityType;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Logs'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                decoration: const InputDecoration(labelText: 'Action Type'),
                value: selectedAction,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'deal_created', child: Text('Deal Created')),
                  DropdownMenuItem(value: 'deal_stage_changed', child: Text('Deal Stage Changed')),
                  DropdownMenuItem(value: 'contact_created', child: Text('Contact Created')),
                  DropdownMenuItem(value: 'user_role_updated', child: Text('Role Updated')),
                  DropdownMenuItem(value: 'lead_converted', child: Text('Lead Converted')),
                ],
                onChanged: (val) => selectedAction = val,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                decoration: const InputDecoration(labelText: 'Entity Type'),
                value: selectedEntity,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'deal', child: Text('Deal')),
                  DropdownMenuItem(value: 'contact', child: Text('Contact')),
                  DropdownMenuItem(value: 'lead', child: Text('Lead')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                ],
                onChanged: (val) => selectedEntity = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(auditLogFilterProvider.notifier).state = AuditLogFilter();
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(auditLogFilterProvider.notifier).state = filter.copyWith(
                  action: selectedAction,
                  entityType: selectedEntity,
                  clearAction: selectedAction == null,
                  clearEntityType: selectedEntity == null,
                );
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
