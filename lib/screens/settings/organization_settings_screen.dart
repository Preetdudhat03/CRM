import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/organization_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/organization_model.dart';
import '../../models/organization_member_model.dart';
import '../../widgets/animations/fade_in_slide.dart';
import '../../utils/error_handler.dart';

class OrganizationSettingsScreen extends ConsumerStatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  ConsumerState<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState
    extends ConsumerState<OrganizationSettingsScreen> {
  final _orgNameController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _orgNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(currentOrganizationProvider);
    final membersAsync = ref.watch(organizationMembersProvider);
    final invitesAsync = ref.watch(invitationsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(currentOrganizationProvider.notifier).refresh();
              ref.read(organizationMembersProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(currentOrganizationProvider.notifier).refresh();
          await ref.read(organizationMembersProvider.notifier).refresh();
        },
        child: orgAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Error: ${ErrorHandler.formatError(e)}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(currentOrganizationProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (org) {
            if (org == null) {
              return _buildNoOrganization(context);
            }
            return _buildOrganizationDetails(context, org, membersAsync, invitesAsync, currentUser);
          },
        ),
      ),
    );
  }

  Widget _buildNoOrganization(BuildContext context) {
    final nameController = TextEditingController();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Organization',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create an organization to enable multi-tenant features.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Organization Name',
                hintText: 'e.g. Acme Corp',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }
                try {
                  await ref
                      .read(currentOrganizationProvider.notifier)
                      .createOrganization(name);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Organization created!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${ErrorHandler.formatError(e)}')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Organization'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationDetails(
    BuildContext context,
    OrganizationModel org,
    AsyncValue<List<OrganizationMemberModel>> membersAsync,
    AsyncValue<List<Map<String, dynamic>>> invitesAsync,
    dynamic currentUser,
  ) {
    final theme = Theme.of(context);
    final isOwner = currentUser?.id == org.ownerId;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Organization Info Card
        FadeInSlide(
          delay: 0,
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.business,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isEditing)
                              TextField(
                                controller: _orgNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Organization Name',
                                  isDense: true,
                                ),
                                autofocus: true,
                              )
                            else
                              Text(
                                org.name,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _planColor(org.plan).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${org.plan.toUpperCase()} Plan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _planColor(org.plan),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isOwner)
                        IconButton(
                          icon: Icon(
                            _isEditing ? Icons.check : Icons.edit,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () async {
                            if (_isEditing) {
                              final newName = _orgNameController.text.trim();
                              if (newName.isNotEmpty && newName != org.name) {
                                try {
                                  await ref
                                      .read(currentOrganizationProvider
                                          .notifier)
                                      .updateOrganization(
                                          org.copyWith(name: newName));
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error: ${ErrorHandler.formatError(e)}')),
                                    );
                                  }
                                }
                              }
                              setState(() => _isEditing = false);
                            } else {
                              _orgNameController.text = org.name;
                              setState(() => _isEditing = true);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Created ${_formatDate(org.createdAt)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Members Section
        FadeInSlide(
          delay: 0.1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Members',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (isOwner)
                TextButton.icon(
                  onPressed: () => _showInviteDialog(context, org.id),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Invite'),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Members List
        membersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(
            child: Text('Error loading members: ${ErrorHandler.formatError(e)}'),
          ),
          data: (members) {
            if (members.isEmpty) {
              return FadeInSlide(
                delay: 0.2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No members yet',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: members.asMap().entries.map((entry) {
                final idx = entry.key;
                final member = entry.value;
                return FadeInSlide(
                  delay: 0.2 + (idx * 0.05),
                  child: _buildMemberTile(context, member, isOwner, org.ownerId),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 32),

        // Invites Section
        FadeInSlide(
          delay: 0.3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Invitations',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        invitesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Center(
            child: Text('Error loading invites: ${ErrorHandler.formatError(e)}'),
          ),
          data: (invites) {
            final pendingInvites = invites.where((i) => i['status'] == 'pending').toList();
            if (pendingInvites.isEmpty) {
              return FadeInSlide(
                delay: 0.4,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No pending invitations',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: pendingInvites.map((invite) {
                return _buildInviteTile(context, invite, isOwner);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInviteTile(BuildContext context, Map<String, dynamic> invite, bool isOwner) {
    final theme = Theme.of(context);
    final email = invite['email'] as String;
    final role = invite['role'] as String;
    final id = invite['id'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(email, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Role: ${role.toUpperCase()}'),
        trailing: isOwner
            ? IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                onPressed: () => _showCancelInviteConfirmation(context, id, email),
              )
            : null,
      ),
    );
  }

  void _showCancelInviteConfirmation(BuildContext context, String inviteId, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Invitation'),
        content: Text('Are you sure you want to cancel the invitation for $email?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(invitationsProvider.notifier).deleteInvitation(inviteId);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${ErrorHandler.formatError(e)}')),
                  );
                }
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    OrganizationMemberModel member,
    bool isOwner,
    String? orgOwnerId,
  ) {
    final theme = Theme.of(context);
    final isSelf = ref.read(currentUserProvider)?.id == member.userId;
    final isMemberOwner = member.userId == orgOwnerId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Text(
            (member.userName ?? member.userEmail ?? '?')
                .substring(0, 1)
                .toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member.userName ?? member.userEmail ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          member.userEmail ?? '',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor(member.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.roleLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _roleColor(member.role),
                ),
              ),
            ),
            if (isOwner && !isSelf && !isMemberOwner)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) => _handleMemberAction(
                    context, value, member),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Text('Change Role'),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      'Remove Member',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _handleMemberAction(
    BuildContext context,
    String action,
    OrganizationMemberModel member,
  ) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(context, member);
        break;
      case 'remove':
        _showRemoveConfirmation(context, member);
        break;
    }
  }

  void _showInviteDialog(BuildContext context, String orgId) {
    final emailController = TextEditingController();
    String selectedRole = 'member';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Invite Team Member'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'colleague@company.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.security),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'member', child: Text('Member')),
                  DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                ],
                onChanged: (v) =>
                    setDialogState(() => selectedRole = v ?? 'member'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid email')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(invitationsProvider.notifier)
                      .createInvitation(email, role: selectedRole);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invited $email successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Error: ${ErrorHandler.formatError(e)}')),
                    );
                  }
                }
              },
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(
      BuildContext context, OrganizationMemberModel member) {
    String newRole = member.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Change Role: ${member.userName ?? 'Member'}'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: DropdownButtonFormField<String>(
            value: newRole,
            decoration: const InputDecoration(
              labelText: 'New Role',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'member', child: Text('Member')),
              DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
            ],
            onChanged: (v) =>
                setDialogState(() => newRole = v ?? member.role),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(organizationMembersProvider.notifier)
                      .updateMemberRole(member.id, newRole);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Role updated')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Error: ${ErrorHandler.formatError(e)}')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmation(
      BuildContext context, OrganizationMemberModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Are you sure you want to remove ${member.userName ?? member.userEmail ?? 'this member'} from the organization?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(organizationMembersProvider.notifier)
                    .removeMember(member.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member removed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Error: ${ErrorHandler.formatError(e)}')),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _planColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'pro':
        return Colors.blue;
      case 'enterprise':
        return Colors.purple;
      case 'free':
      default:
        return Colors.green;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.amber.shade700;
      case 'admin':
        return Colors.blue;
      case 'member':
        return Colors.green;
      case 'viewer':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
