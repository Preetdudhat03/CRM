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
  Widget _buildStatusIndicator(List<ContactModel> allContacts) {
    final statuses = [
      null, // All
      ContactStatus.customer,
      ContactStatus.lead,
      ContactStatus.churned,
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final count = status == null 
              ? allContacts.length 
              : allContacts.where((c) => c.status == status).length;
          final isSelected = _statusFilter == status;

          Color getBaseColor(ContactStatus? s) {
            if (s == null) return Colors.blueGrey;
            switch (s) {
              case ContactStatus.customer: return Colors.green;
              case ContactStatus.lead: return Colors.orange;
              case ContactStatus.churned: return Colors.red;
            }
          }
          final baseColor = getBaseColor(status);
          final label = status == null ? 'All' : status.label;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _statusFilter = status;
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
                      label,
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
          preferredSize: const Size.fromHeight(130),
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
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _sortOption,
                            icon: Icon(Icons.sort, color: Colors.grey.shade600),
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                            items: ['Recently Added', 'Name', 'Company'].map((sort) {
                              return DropdownMenuItem(
                                value: sort,
                                child: Text(sort, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _sortOption = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              contactsAsync.maybeWhen(
                data: (allContacts) => _buildStatusIndicator(allContacts),
                orElse: () => const SizedBox(height: 60),
              ),
            ],
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
