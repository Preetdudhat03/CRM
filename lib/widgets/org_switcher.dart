import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/organization_provider.dart';
import '../providers/auth_provider.dart';
import '../models/organization_model.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/organization_settings_screen.dart';

class OrgSwitcher extends ConsumerWidget {
  final bool isCompact;
  const OrgSwitcher({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrgAsync = ref.watch(currentOrganizationProvider);
    final allOrgsAsync = ref.watch(userOrganizationsProvider);
    final user = ref.watch(currentUserProvider);

    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: PopupMenuButton<dynamic>(
        offset: const Offset(0, 48),
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Avatar
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                    ? Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              if (!isCompact) ...[
                const SizedBox(width: 8),
                // Org Info
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentOrgAsync.valueOrNull?.name ?? 'No Organization',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).hintColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
              ],
            ],
          ),
        ),
        onSelected: (value) async {
          if (value is OrganizationModel) {
            if (value.id == currentOrgAsync.valueOrNull?.id) return;
            try {
              await ref.read(currentOrganizationProvider.notifier).switchOrganization(value.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Switched to ${value.name}')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            }
          } else if (value == 'profile') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          } else if (value == 'org_settings') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizationSettingsScreen()));
          } else if (value == 'logout') {
            ref.read(currentUserProvider.notifier).logout();
          }
        },
        itemBuilder: (context) {
          final allOrgs = allOrgsAsync.valueOrNull ?? [];
          final currentOrg = currentOrgAsync.valueOrNull;

          return [
            // User Header
            PopupMenuItem(
              enabled: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                        ? Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // Account Actions
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 18),
                  SizedBox(width: 12),
                  Text('My Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'org_settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 18),
                  SizedBox(width: 12),
                  Text('Org Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // Organization Switcher Section
            if (allOrgs.isNotEmpty) ...[
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'SWITCH ORGANIZATION',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
              ...allOrgs.map((org) => PopupMenuItem(
                value: org,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: org.id == currentOrg?.id 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey.shade300,
                      child: Text(
                        org.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 8, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      org.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: org.id == currentOrg?.id ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (org.id == currentOrg?.id) ...[
                      const Spacer(),
                      Icon(Icons.check, size: 14, color: Theme.of(context).primaryColor),
                    ],
                  ],
                ),
              )),
              const PopupMenuDivider(),
            ],
            // Logout
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }
}
