import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contact_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import 'widgets/contact_card.dart';
import 'add_edit_contact_screen.dart';
import 'contact_detail_screen.dart';
import '../../core/services/permission_service.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/org_switcher.dart';

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(contactsProvider.notifier).loadMore();
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

  Widget _buildStatusIndicator(List<ContactModel> allContacts) {
    final statuses = [
      ContactStatus.lead,
      ContactStatus.customer,
      ContactStatus.churned,
    ];

    return Container(
      height: 60,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(statuses.length, (index) {
            final status = statuses[index];
            final count = allContacts.where((c) => c.status == status).length;
            final isSelected = _statusFilter == status;

            Color getBaseColor(ContactStatus s) {
              switch (s) {
                case ContactStatus.lead:
                  return Colors.orange;
                case ContactStatus.customer:
                  return Colors.green;
                case ContactStatus.churned:
                  return Colors.red;
              }
            }

            final baseColor = getBaseColor(status);

            return Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _statusFilter = isSelected ? null : status;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? baseColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? baseColor : Colors.grey.shade300,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: baseColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Text(
                        status.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
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
        leading: const OrgSwitcher(),
        leadingWidth: 180,
        // title: const Text(
        //   'Contacts',
        //   style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        // ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search contacts...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                          ),
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
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                        onChanged: (value) {
                          ref.read(contactSearchQueryProvider.notifier).state =
                              value;
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
                            value: _sortOption,
                            icon: Icon(Icons.sort, color: Colors.grey.shade600),
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            items: ['Recently Added', 'Name', 'Company'].map((
                              sort,
                            ) {
                              return DropdownMenuItem(
                                value: sort,
                                child: Text(sort),
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
            contacts = contacts
                .where((c) => c.status == _statusFilter)
                .toList();
          }

          if (_sortOption == 'Name') {
            contacts.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          } else if (_sortOption == 'Company') {
            contacts.sort(
              (a, b) =>
                  a.company.toLowerCase().compareTo(b.company.toLowerCase()),
            );
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
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.badge_outlined,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Contacts Yet',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "You don't have any contacts matching\n the current filters.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (canCreate)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddEditContactScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Contact'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
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
                                            AddEditContactScreen(
                                              contact: contact,
                                            ),
                                      ),
                                    );
                                  }
                                : null,
                            onDelete: canDelete
                                ? () => _showDeleteConfirmation(
                                    context,
                                    ref,
                                    contact,
                                  )
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
          itemBuilder: (context, index) => SkeletonCard(height: 100),
        ),
        error: (error, stack) {
          final isPaused = error.toString().toLowerCase().contains('paused') ||
              error.toString().toLowerCase().contains('unavailable');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPaused ? Icons.cloud_off_rounded : Icons.error_outline,
                  size: 48,
                  color: isPaused ? Colors.orange.shade400 : Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  isPaused
                      ? 'Database is Paused'
                      : 'Failed to load contacts',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isPaused) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Your Supabase project is paused due to inactivity. '
                      'Please resume it from the Supabase dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.read(contactsProvider.notifier).loadInitial(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        },
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
