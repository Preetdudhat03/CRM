import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/permission_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_management_provider.dart';
import '../../../widgets/org_switcher.dart';
import '../../../widgets/animations/fade_in_slide.dart';
import '../../../utils/error_handler.dart';
import 'add_edit_user_screen.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userManagementProvider);
    final user = ref.watch(currentUserProvider);
    final canManage = PermissionService.canManageUsers(user);

    return Scaffold(
      appBar: AppBar(
        leading: const OrgSwitcher(),
        leadingWidth: 180,
        // title: const Text('User Management'),
      ),
      body: usersAsync.when(
        data: (users) => RefreshIndicator(
          onRefresh: () => ref.read(userManagementProvider.notifier).getUsers(),
          child: users.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(child: const Text('No users found')),
                  ),
                )
              : ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemBuilder: (context, index) {
                    final itemUser = users[index];
                    return FadeInSlide(
                      delay: index * 0.1,
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            backgroundImage:
                                (itemUser.avatarUrl != null &&
                                    itemUser.avatarUrl!.isNotEmpty)
                                ? NetworkImage(itemUser.avatarUrl!)
                                : null,
                            child:
                                (itemUser.avatarUrl == null ||
                                    itemUser.avatarUrl!.isEmpty)
                                ? Text(
                                    itemUser.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            itemUser.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 14,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    itemUser.email,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  itemUser.role.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: canManage
                              ? PopupMenuButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 12),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddEditUserScreen(user: itemUser),
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmation(
                                          context, ref, itemUser.id);
                                    }
                                  },
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => RefreshIndicator(
          onRefresh: () => ref.read(userManagementProvider.notifier).getUsers(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Text('Error: ${ErrorHandler.formatError(error ?? '')}'),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              heroTag: 'users_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddEditUserScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(userManagementProvider.notifier).deleteUser(userId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
