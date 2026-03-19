import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/organization_provider.dart';
import '../models/organization_model.dart';

class OrgSwitcher extends ConsumerWidget {
  const OrgSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrgAsync = ref.watch(currentOrganizationProvider);
    final allOrgsAsync = ref.watch(userOrganizationsProvider);

    return currentOrgAsync.when(
      data: (currentOrg) {
        if (currentOrg == null) return const SizedBox.shrink();

        return allOrgsAsync.when(
          data: (allOrgs) {
            // If only one org, just show the name
            if (allOrgs.length <= 1) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        currentOrg.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentOrg.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Multiple orgs: Show dropdown
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: PopupMenuButton<OrganizationModel>(
                offset: const Offset(0, 40),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          currentOrg.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentOrg.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.unfold_more, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
                onSelected: (org) async {
                  if (org.id == currentOrg.id) return;
                  
                  try {
                    await ref.read(currentOrganizationProvider.notifier).switchOrganization(org.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Switched to ${org.name}')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    enabled: false,
                    child: Text(
                      'Switch Organization',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const PopupMenuDivider(),
                  ...allOrgs.map((org) => PopupMenuItem(
                    value: org,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: org.id == currentOrg.id 
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
                            fontWeight: org.id == currentOrg.id 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          ),
                        ),
                        if (org.id == currentOrg.id) ...[
                          const Spacer(),
                          Icon(Icons.check, size: 16, color: Theme.of(context).primaryColor),
                        ],
                      ],
                    ),
                  )),
                ],
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
