
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deal_model.dart';
import '../models/role_model.dart';
import '../repositories/deal_repository.dart';
import '../services/deal_service.dart';
import '../services/activity_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';
import 'dashboard_provider.dart';

// Service Provider
final dealServiceProvider = Provider<DealService>((ref) => DealService());

final dealRepositoryProvider = Provider<DealRepository>((ref) {
  return DealRepository(ref.watch(dealServiceProvider));
});


// State Provider for Search Query
final dealSearchQueryProvider = StateProvider<String>((ref) => '');

// State Notifier for Deal List management
class DealNotifier extends StateNotifier<AsyncValue<List<DealModel>>> {
  final DealRepository _repository;
  final Ref _ref;

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  DealNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInitial() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    try {
      state = const AsyncValue.loading();
      final deals = await _repository.getDeals(page: _currentPage, pageSize: _pageSize);
      if (deals.length < _pageSize) _hasMore = false;
      state = AsyncValue.data(deals);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state is AsyncLoading) return;

    _isLoadingMore = true;
    try {
      _currentPage++;
      final newDeals = await _repository.getDeals(page: _currentPage, pageSize: _pageSize);
      if (newDeals.length < _pageSize) _hasMore = false;
      state.whenData((currentDeals) {
        state = AsyncValue.data([...currentDeals, ...newDeals]);
      });
    } catch (e) {
      _currentPage--;
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    try {
      final deals = await _repository.getDeals(page: _currentPage, pageSize: _pageSize);
      if (deals.length < _pageSize) _hasMore = false;
      state = AsyncValue.data(deals);
    } catch (e, stack) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> addDeal(DealModel deal) async {
    try {
      final newDeal = await _repository.addDeal(deal);
      state.whenData((deals) {
        state = AsyncValue.data([...deals, newDeal]);
      });
      
      ActivityService.log(title: 'Created deal: ${newDeal.title}', type: 'deal', relatedEntityId: newDeal.id);
      
      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      _ref.read(notificationsProvider.notifier).pushNotificationLocally(
        'New Deal Created',
        '$userName added a new deal: ${newDeal.title}',
        relatedEntityId: newDeal.id,
        relatedEntityType: 'deal',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDeal(DealModel deal) async {
    try {
      final updatedDeal = await _repository.updateDeal(deal);
      state.whenData((deals) {
        final existingDeal = deals.firstWhere((d) => d.id == deal.id, orElse: () => deal);
        
        state = AsyncValue.data([
          for (final d in deals)
            if (d.id == deal.id) updatedDeal else d
        ]);

        final currentUser = _ref.read(currentUserProvider);
        final userName = currentUser?.name ?? 'Someone';

        if (existingDeal.stage != deal.stage) {
          _ref.read(notificationsProvider.notifier).pushNotificationLocally(
            'Deal Stage Updated',
            '$userName moved deal ${deal.title} to ${deal.stage.label}',
            relatedEntityId: deal.id,
            relatedEntityType: 'deal',
          );
        } else {
          _ref.read(notificationsProvider.notifier).pushNotificationLocally(
            'Deal Updated',
            '$userName updated deal: ${deal.title}',
            relatedEntityId: deal.id,
            relatedEntityType: 'deal',
          );
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteDeal(String id) async {
    try {
      await _repository.deleteDeal(id);
      state.whenData((deals) {
        state = AsyncValue.data([
          for (final d in deals)
            if (d.id != id) d
        ]);
      });
      ActivityService.log(title: 'Deleted a deal', type: 'deal', relatedEntityId: id);

      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      _ref.read(notificationsProvider.notifier).pushNotificationLocally(
        'Deal Deleted',
        '$userName deleted a deal',
        relatedEntityType: 'deal',
      );
    } catch (e) {
      // Handle error
    }
  }
}

// Deals List Provider
final dealsProvider =
    StateNotifierProvider<DealNotifier, AsyncValue<List<DealModel>>>((ref) {
  return DealNotifier(ref.watch(dealRepositoryProvider), ref);
});

// Filtered Deals Provider
final filteredDealsProvider = Provider<AsyncValue<List<DealModel>>>((ref) {
  final dealsAsync = ref.watch(dealsProvider);
  final query = ref.watch(dealSearchQueryProvider).toLowerCase();

  return dealsAsync.whenData((deals) {
    if (query.isEmpty) return deals;
    return deals.where((deal) {
      return deal.title.toLowerCase().contains(query) ||
          deal.contactName.toLowerCase().contains(query) ||
          deal.companyName.toLowerCase().contains(query);
    }).toList();
  });
});

