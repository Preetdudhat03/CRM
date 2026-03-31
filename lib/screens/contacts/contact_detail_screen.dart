import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contact_provider.dart';
import 'package:flutter/material.dart';
import 'add_edit_contact_screen.dart';
import '../../models/contact_model.dart';
import '../../core/services/permission_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/activity_timeline.dart';
import '../widgets/files_list_view.dart';

class ContactDetailScreen extends ConsumerStatefulWidget {
  final ContactModel contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  ConsumerState<ContactDetailScreen> createState() =>
      _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen>
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
    final user = ref.watch(currentUserProvider);
    final canEdit = PermissionService.canEditContacts(user);
    final canDelete = PermissionService.canDeleteContacts(user);

    final contactsAsync = ref.watch(contactsProvider);
    final contact =
        contactsAsync.value?.firstWhere(
          (c) => c.id == widget.contact.id,
          orElse: () => widget.contact,
        ) ??
        widget.contact;

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          IconButton(
            icon: Icon(
              contact.isFavorite ? Icons.star : Icons.star_border,
              color: contact.isFavorite ? Colors.amber : null,
            ),
            onPressed: () {
              ref
                  .read(contactsProvider.notifier)
                  .toggleFavorite(contact.id, contact.isFavorite);
            },
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEditContactScreen(contact: contact),
                  ),
                );
              },
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, ref, contact),
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
          _buildOverviewTab(context, contact),
          ActivityTimeline(relatedType: 'contact', relatedId: contact.id),
          FileListView(
            relatedType: 'contact',
            relatedId: contact.id,
            organizationId: contact.organizationId ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, ContactModel contact) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context, contact),
          const SizedBox(height: 20),
          _buildInfoSection(context, contact),
          const SizedBox(height: 20),
          if (contact.notes != null && contact.notes!.isNotEmpty)
            _buildNotesSection(context, contact),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ContactModel contact) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).cardColor,
      width: double.infinity,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty
                ? NetworkImage(contact.avatarUrl!)
                : null,
            child: (contact.avatarUrl == null || contact.avatarUrl!.isEmpty)
                ? Text(
                    contact.name.isNotEmpty
                        ? contact.name.substring(0, 1).toUpperCase()
                        : 'C',
                    style: const TextStyle(fontSize: 40),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            contact.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${contact.position} at ${contact.company}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Chip(
            label: Text(contact.status.label),
            backgroundColor: _getStatusColor(contact.status).withOpacity(0.1),
            labelStyle: TextStyle(
              color: _getStatusColor(contact.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, ContactModel contact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Info',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(contact.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(contact.phone),
                ),
                if (contact.address != null && contact.address!.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(contact.address!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, ContactModel contact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                contact.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    ContactModel contact,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(contactsProvider.notifier).deleteContact(contact.id);
              Navigator.pop(context);
              Navigator.pop(context); // Back to list
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${contact.name} deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
