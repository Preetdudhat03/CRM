
import 'package:flutter/material.dart';
import '../../../../models/contact_model.dart';

class ContactCard extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.lead:
        return Colors.orange;
      case ContactStatus.customer:
        return Colors.green;
      case ContactStatus.churned:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: contact.avatarUrl != null
              ? NetworkImage(contact.avatarUrl!)
              : null,
          child: contact.avatarUrl == null
              ? Text(
                  contact.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(contact.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                contact.status.label,
                style: TextStyle(
                  color: _getStatusColor(contact.status),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${contact.position} at ${contact.company}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    contact.email,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit' && onEdit != null) {
              onEdit!();
            } else if (value == 'delete' && onDelete != null) {
              onDelete!();
            }
          },
          itemBuilder: (context) => [
            if (onEdit != null)
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
            if (onDelete != null)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
