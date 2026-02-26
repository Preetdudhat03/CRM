import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/permission_model.dart';
import '../../models/lead_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lead_provider.dart';
import 'widgets/lead_card.dart';
import 'add_edit_lead_screen.dart';
import 'lead_detail_screen.dart';
import '../../core/services/permission_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/skeleton_loading.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  final ScrollController _scrollController = ScrollController();
  LeadStatus? _selectedStatusFilter;
  String? _selectedSourceFilter;
  
  // Hardcoded for UI demo
  final List<String> _sourceOptions = ['All', 'Website', 'Instagram', 'Referral', 'Cold Call', 'Other'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(leadsProvider.notifier).loadMore();
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, LeadModel lead) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lead'),
        content: Text('Are you sure you want to delete ${lead.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(leadsProvider.notifier).deleteLead(lead.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${lead.name} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineIndicator(List<LeadModel> allLeads) {
    final statuses = [
      LeadStatus.newLead,
      LeadStatus.contacted,
      LeadStatus.qualified,
      LeadStatus.lost,
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final count = allLeads.where((l) => l.status == status).length;
          final isSelected = _selectedStatusFilter == status;

          Color getBaseColor(LeadStatus s) {
             switch (s) {
              case LeadStatus.newLead: return Colors.blue;
              case LeadStatus.contacted: return Colors.purple;
              case LeadStatus.qualified: return Colors.teal;
              case LeadStatus.lost: return Colors.red;
              default: return Colors.grey;
             }
          }
          final baseColor = getBaseColor(status);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedStatusFilter = isSelected ? null : status;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? baseColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? baseColor : Colors.grey.shade300),
                  boxShadow: isSelected ? [
                    BoxShadow(color: baseColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Text(
                      status.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(filteredLeadsProvider); // Contains search filtered, unconverted leads
    final user = ref.watch(currentUserProvider);
    final canCreate = PermissionService.canCreateLeads(user);
    final canEdit = PermissionService.canEditLeads(user);
    final canDelete = PermissionService.canDeleteLeads(user);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Leads Pipeline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search leads...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (value) {
                          ref.read(leadSearchQueryProvider.notifier).state = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedSourceFilter ?? 'All',
                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.w500),
                            items: _sourceOptions.map((source) {
                              return DropdownMenuItem(
                                value: source,
                                child: Text(source),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedSourceFilter = val == 'All' ? null : val;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leadsAsync.maybeWhen(
                data: (allLeads) => _buildPipelineIndicator(allLeads),
                orElse: () => const SizedBox(height: 60),
              ),
            ],
          ),
        ),
      ),
      body: leadsAsync.when(
        data: (unfilteredLeads) {
          // Apply local UI filters
          var leads = unfilteredLeads;
          if (_selectedStatusFilter != null) {
            leads = leads.where((l) => l.status == _selectedStatusFilter).toList();
          }
          if (_selectedSourceFilter != null) {
            leads = leads.where((l) => l.source.toLowerCase() == _selectedSourceFilter!.toLowerCase().replaceAll(' ', '_')).toList();
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(leadsProvider.notifier).refresh(),
            child: leads.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 250, 
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.group_add_outlined, size: 64, color: Colors.blue.shade300),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Leads Yet',
                              style: TextStyle(color: Colors.grey.shade800, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "You haven't added any leads \nmatching the current filters.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            if (canCreate)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddEditLeadScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Lead'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: leads.length + 1,
                    itemBuilder: (context, index) {
                      if (index == leads.length) {
                        final notifier = ref.read(leadsProvider.notifier);
                        if (notifier.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final lead = leads[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: LeadCard(
                            lead: lead,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LeadDetailScreen(lead: lead),
                                ),
                              );
                            },
                            onEdit: canEdit
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditLeadScreen(lead: lead),
                                      ),
                                    );
                                  }
                                : null,
                            onDelete: canDelete
                                ? () => _showDeleteConfirmation(context, ref, lead)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 5,
          padding: const EdgeInsets.only(top: 8),
          itemBuilder: (context, index) => const SkeletonCard(height: 140),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Failed to load leads', style: TextStyle(color: Colors.grey.shade800, fontSize: 16)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(leadsProvider.notifier).refresh(),
                child: const Text('Retry'),
              )
            ],
          )
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditLeadScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
