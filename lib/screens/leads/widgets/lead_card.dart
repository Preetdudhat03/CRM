
import 'package:flutter/material.dart';
import '../../../../models/lead_model.dart';

class LeadCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lead.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(lead.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lead.status.label.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(lead.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                   Icon(Icons.email, size: 14, color: Colors.grey[600]),
                   const SizedBox(width: 4),
                   Expanded(
                     child: Text(
                       lead.email,
                       style: TextStyle(color: Colors.grey[600]),
                       overflow: TextOverflow.ellipsis,
                     ),
                   )
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: ${lead.assignedTo}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              if (lead.estimatedValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '₹${lead.estimatedValue!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 36),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[400],
                      padding: EdgeInsets.zero,
                       minimumSize: const Size(60, 36),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
