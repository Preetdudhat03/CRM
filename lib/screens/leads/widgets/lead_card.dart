import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/lead_model.dart';
import '../../../../models/permission_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/services/permission_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/lead_provider.dart';

class LeadCard extends ConsumerStatefulWidget {
  final LeadModel lead;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LeadCard({
    super.key,
    required this.lead,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  ConsumerState<LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends ConsumerState<LeadCard> {
  bool _isConverting = false;

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue;
      case LeadStatus.contacted:
        return Colors.purple;
      case LeadStatus.interested:
        return Colors.orange;
      case LeadStatus.qualified:
        return Colors.teal;
      case LeadStatus.converted:
        return Colors.green;
      case LeadStatus.lost:
        return Colors.red;
    }
  }

  Color _getSourceColor(String source) {
    final lower = source.toLowerCase();
    switch (lower) {
      case 'website':
        return Colors.indigo;
      case 'instagram':
        return Colors.pink;
      case 'referral':
        return Colors.cyan;
      case 'cold_call':
        return Colors.brown;
      default:
        return Colors.grey.shade600;
    }
  }

  void _convertLead() async {
    if (_isConverting) return;
    setState(() => _isConverting = true);
    try {
      await ref.read(leadsProvider.notifier).convertLead(widget.lead.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead converted to Contact successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error converting lead: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConverting = false);
      }
    }
  }

  void _markLost() async {
    try {
      final updatedLead = widget.lead.copyWith(status: LeadStatus.lost);
      await ref.read(leadsProvider.notifier).updateLead(updatedLead);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead marked as Lost')),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating lead: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canEdit = PermissionService.canEditLeads(user);
    final isConverted = widget.lead.status == LeadStatus.converted;
    final isLost = widget.lead.status == LeadStatus.lost;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lead.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(widget.lead.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _getStatusColor(widget.lead.status).withOpacity(0.5)),
                              ),
                              child: Text(
                                widget.lead.status.label,
                                style: TextStyle(
                                  color: _getStatusColor(widget.lead.status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Source Badge
                            if (widget.lead.source.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.source, size: 10, color: _getSourceColor(widget.lead.source)),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.lead.source,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions Container
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Convert Button
                      if (canEdit && !isConverted && !isLost)
                        SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: _isConverting ? null : _convertLead,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(color: Theme.of(context).primaryColor),
                            ),
                            child: _isConverting
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text('Convert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                          ),
                        )
                      else if (isConverted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CONVERTED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                          ),
                        ),
                        
                      const SizedBox(width: 4),
                      // Three-dot menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        onSelected: (value) {
                          if (value == 'view') {
                            widget.onTap();
                          } else if (value == 'edit' && widget.onEdit != null) {
                            widget.onEdit!();
                          } else if (value == 'delete' && widget.onDelete != null) {
                            widget.onDelete!();
                          } else if (value == 'lost') {
                            _markLost();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                          if (widget.onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (canEdit && !isLost && !isConverted)
                            const PopupMenuItem(
                              value: 'lost',
                              child: Row(
                                children: [
                                  Icon(Icons.thumb_down_outlined, size: 18, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Mark Lost'),
                                ],
                              ),
                            ),
                          if (widget.onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.lead.assignedTo.isNotEmpty ? widget.lead.assignedTo : 'Unassigned',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(widget.lead.createdAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
