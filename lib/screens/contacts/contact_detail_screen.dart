
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contact_provider.dart';
import 'package:flutter/material.dart';
import 'add_edit_contact_screen.dart';
import '../../models/contact_model.dart';

class ContactDetailScreen extends StatelessWidget {
  final ContactModel contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          // We need a Consumer here to access the provider ref
          Consumer(
            builder: (context, ref, child) {
              // Watch the specific contact to update UI when provider updates
              // BUT we are in a stateless widget inside a list, watching the whole list is inefficient.
              // However, since we are inside detail screen, we can just use the passed contact or
              // rebuild the widget when the list updates.
              // Simple hack: We just toggle. The parent screen (ContactsScreen) needs to pass updated object if we go back.
              // For detail screen to reflect change LIVE, we should query provider by ID.
              final contactsAsync = ref.watch(contactsProvider);
              final updatedContact = contactsAsync.value?.firstWhere((c) => c.id == contact.id, orElse: () => contact) ?? contact;

              return IconButton(
                icon: Icon(
                  updatedContact.isFavorite ? Icons.star : Icons.star_border,
                  color: updatedContact.isFavorite ? Colors.amber : null,
                ),
                onPressed: () {
                  ref.read(contactsProvider.notifier).toggleFavorite(contact.id, updatedContact.isFavorite);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(updatedContact.isFavorite ? 'Removed from favorites' : 'Added to favorites'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditContactScreen(contact: contact),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
             _buildHeader(context),
             const SizedBox(height: 20),
             _buildInfoSection(context),
             const SizedBox(height: 20),
             if (contact.notes != null && contact.notes!.isNotEmpty)
              _buildNotesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).cardColor,
      width: double.infinity,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: contact.avatarUrl != null
                ? NetworkImage(contact.avatarUrl!)
                : null,
            child: contact.avatarUrl == null
                ? Text(
                    contact.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 40),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            contact.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${contact.position} at ${contact.company}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
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

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Info',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(contact.email),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(contact.phone),
                  trailing: const Icon(Icons.message_outlined, size: 20),
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

  Widget _buildNotesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
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
}
