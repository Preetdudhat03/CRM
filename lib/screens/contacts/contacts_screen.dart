import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/permission_model.dart';
import '../../models/contact_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import 'widgets/contact_card.dart';
import 'add_edit_contact_screen.dart';
import 'contact_detail_screen.dart';
import '../../core/services/permission_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/skeleton_loading.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // Local Filter & Sort State
  ContactStatus? _statusFilter;
  String _sortOption = 'Recently Added'; // 'Name', 'Recently Added', 'Company'

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
      ref.read(contactsProvider.notifier).loadMore();
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, ContactModel contact) {
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Sort',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Recently Added', 'Name', 'Company'].map((sort) {
                      final isSelected = _sortOption == sort;
                      return ChoiceChip(
                        label: Text(sort),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => _sortOption = sort);
                            setState(() => _sortOption = sort);
                          }
                        },
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [null, ContactStatus.customer, ContactStatus.lead, ContactStatus.churned].map((status) {
                      final isSelected = _statusFilter == status;
                      final label = status == null ? 'All' : status.label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => _statusFilter = status);
                            setState(() => _statusFilter = status);
                          }
                        },
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(filteredContactsProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = PermissionService.canCreateContacts(user);
    final canEdit = PermissionService.canEditContacts(user);
    final canDelete = PermissionService.canDeleteContacts(user);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Contacts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
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
                      ref.read(contactSearchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showFilterBottomSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_statusFilter != null || _sortOption != 'Recently Added') 
                          ? Theme.of(context).primaryColor.withOpacity(0.1) 
                          : Colors.grey.shade50,
                      border: Border.all(
                        color: (_statusFilter != null || _sortOption != 'Recently Added') 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey.shade200
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune, 
                      color: (_statusFilter != null || _sortOption != 'Recently Added') 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey.shade700
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: contactsAsync.when(
        data: (unfilteredContacts) {
          // Apply local UI filters & sorting
          var contacts = unfilteredContacts;
          if (_statusFilter != null) {
            contacts = contacts.where((c) => c.status == _statusFilter).toList();
          }

          if (_sortOption == 'Name') {
            contacts.sort((a, b) => a.name.compareTo(b.name));
          } else if (_sortOption == 'Company') {
            contacts.sort((a, b) => a.company.compareTo(b.company));
          } else {
            // Recently Added
            contacts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(contactsProvider.notifier).refresh(),
            child: contacts.isEmpty
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
                                color: Theme.of(context).primaryColor.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.badge_outlined, size: 64, color: Theme.of(context).primaryColor.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Contacts Yet',
                              style: TextStyle(color: Colors.grey.shade800, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "You don't have any contacts matching\n the current filters.",
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
                                      builder: (context) => const AddEditContactScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Contact'),
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
                    itemCount: contacts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == contacts.length) {
                        final notifier = ref.read(contactsProvider.notifier);
                        if (notifier.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final contact = contacts[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: ContactCard(
                            contact: contact,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ContactDetailScreen(contact: contact),
                                ),
                              );
                            },
                            onEdit: canEdit
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditContactScreen(contact: contact),
                                      ),
                                    );
                                  }
                                : null,
                            onDelete: canDelete
                                ? () => _showDeleteConfirmation(context, ref, contact)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 6,
          padding: const EdgeInsets.only(top: 8),
          itemBuilder: (context, index) => const SkeletonCard(height: 100),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Failed to load contacts', style: TextStyle(color: Colors.grey.shade800, fontSize: 16)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(contactsProvider.notifier).refresh(),
                child: const Text('Retry'),
              )
            ],
          )
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              heroTag: 'contacts_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditContactScreen(),
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
