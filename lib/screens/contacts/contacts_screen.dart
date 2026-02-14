
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/permission_model.dart';
import '../../models/contact_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import 'widgets/contact_card.dart';
import 'add_edit_contact_screen.dart';
import 'contact_detail_screen.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(filteredContactsProvider);
    final permissions = ref.watch(userPermissionsProvider);
    final canCreate = permissions.contains(Permission.createContacts);
    final canEdit = permissions.contains(Permission.editContacts);
    final canDelete = permissions.contains(Permission.deleteContacts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                ref.read(contactSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: contactsAsync.when(
        data: (contacts) => contacts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No contacts found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return ContactCard(
                    contact: contact,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ContactDetailScreen(contact: contact),
                        ),
                      );
                    },
                    onEdit: canEdit
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditContactScreen(contact: contact),
                              ),
                            );
                          }
                        : null,
                    onDelete: canDelete
                        ? () {
                            _showDeleteConfirmation(context, ref, contact);
                          }
                        : null,
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditContactScreen(),
                  ),
                );
              },
              label: const Text('Add Contact'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, ContactModel contact) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${contact.name} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
