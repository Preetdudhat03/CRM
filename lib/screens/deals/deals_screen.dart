
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/permission_model.dart';
import '../../models/deal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deal_provider.dart';
import 'widgets/deal_card.dart';
import 'add_edit_deal_screen.dart';
import 'deal_detail_screen.dart';

import '../../core/services/permission_service.dart';
import '../../utils/error_handler.dart';

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  final ScrollController _scrollController = ScrollController();

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
      ref.read(dealsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(filteredDealsProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = PermissionService.canCreateDeals(user);
    final canEdit = PermissionService.canEditDeals(user);
    final canDelete = PermissionService.canDeleteDeals(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search deals...',
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
                ref.read(dealSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: dealsAsync.when(
        data: (deals) => RefreshIndicator(
          onRefresh: () => ref.read(dealsProvider.notifier).refresh(),
          child: deals.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.monetization_on_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No deals found',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: deals.length + 1,
                  itemBuilder: (context, index) {
                    if (index == deals.length) {
                      final notifier = ref.read(dealsProvider.notifier);
                      if (notifier.isLoadingMore) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (!notifier.hasMore && deals.isNotEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No more deals'),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final deal = deals[index];
                    return DealCard(
                      deal: deal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DealDetailScreen(deal: deal),
                          ),
                        );
                      },
                      onEdit: canEdit
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditDealScreen(deal: deal),
                                ),
                              );
                            }
                          : null,
                      onDelete: canDelete
                          ? () {
                              _showDeleteConfirmation(context, ref, deal);
                            }
                          : null,
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => RefreshIndicator(
          onRefresh: () => ref.read(dealsProvider.notifier).refresh(),
          child: SingleChildScrollView(
             physics: const AlwaysScrollableScrollPhysics(),
             child: SizedBox(
               height: MediaQuery.of(context).size.height,
               child: Center(child: Text('Error: ${ErrorHandler.formatError(error ?? '')}')),
             ),
          ),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              heroTag: 'deals_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditDealScreen(),
                  ),
                );
              },
              label: const Text('Add Deal'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, DealModel deal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deal'),
        content: Text('Are you sure you want to delete ${deal.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(dealsProvider.notifier).deleteDeal(deal.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${deal.title} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
