
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deal_model.dart';
import '../repositories/deal_repository.dart';
import '../services/deal_service.dart';
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

  DealNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    getDeals();
  }

  Future<void> getDeals() async {
    try {
      state = const AsyncValue.loading();
      final deals = await _repository.getDeals();
      state = AsyncValue.data(deals);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addDeal(DealModel deal) async {
    try {
      final newDeal = await _repository.addDeal(deal);
      state.whenData((deals) {
        state = AsyncValue.data([...deals, newDeal]);
      });
      
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

        if (existingDeal.stage != deal.stage) {
          final currentUser = _ref.read(currentUserProvider);
          final userName = currentUser?.name ?? 'Someone';
          _ref.read(notificationsProvider.notifier).pushNotificationLocally(
            'Deal Stage Updated',
            '$userName moved the deal ${deal.title} to ${deal.stage.label}',
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

// Dashboard Stats Provider (Revenue, Counts)
final dealStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final dealsAsync = ref.watch(dealsProvider);
  final period = ref.watch(dashboardPeriodProvider);

  return dealsAsync.whenData((deals) {
    int totalDeals = deals.length;
    double totalRevenue = deals.fold(0, (sum, deal) => sum + deal.value);
    
    // Revenue from closed won
    double revenueWon = deals
        .where((d) => d.stage == DealStage.closedWon)
        .fold(0, (sum, deal) => sum + deal.value);

    int activeDeals = deals.where((d) => 
        d.stage != DealStage.closedWon && d.stage != DealStage.closedLost).length;

    // Pipeline counts
    Map<DealStage, int> pipeline = {};
    for (var stage in DealStage.values) {
      pipeline[stage] = deals.where((d) => d.stage == stage).length;
    }

    final currentPeriodActiveDeals = deals.where((d) => 
      d.createdAt.isAfter(period.startDate) &&
      d.stage != DealStage.closedWon && d.stage != DealStage.closedLost
    ).length;

    final previousPeriodActiveDeals = deals.where((d) => 
      d.createdAt.isAfter(period.previousPeriodStartDate) &&
      d.createdAt.isBefore(period.previousPeriodEndDate) &&
      d.stage != DealStage.closedWon && d.stage != DealStage.closedLost
    ).length;
    final activeDealsTrend = calculateTrend(currentPeriodActiveDeals, previousPeriodActiveDeals);

    final currentPeriodRevenueWon = deals.where((d) => 
      d.createdAt.isAfter(period.startDate) && d.stage == DealStage.closedWon
    ).fold(0.0, (sum, d) => sum + d.value);

    final previousPeriodRevenueWon = deals.where((d) => 
      d.createdAt.isAfter(period.previousPeriodStartDate) &&
      d.createdAt.isBefore(period.previousPeriodEndDate) &&
      d.stage == DealStage.closedWon
    ).fold(0.0, (sum, d) => sum + d.value);
    
    // Calculate double trend using the same function since it works for doubles implicitly converted assuming int wouldn't affect the string but calculateTrend takes int
    double rvChange = 0.0;
    bool rvIsUp = true;
    if (previousPeriodRevenueWon == 0) {
      if (currentPeriodRevenueWon > 0) {
        rvChange = 100.0;
      }
    } else {
      rvChange = ((currentPeriodRevenueWon - previousPeriodRevenueWon) / previousPeriodRevenueWon) * 100;
    }

    return {
      'totalCount': totalDeals,
      'totalValue': totalRevenue,
      'revenueWon': revenueWon,
      'revenueWonTrendPercentage': rvChange.abs(),
      'revenueWonIsUpTrend': rvChange >= 0,
      'activeCount': activeDeals,
      'activeCountTrendPercentage': activeDealsTrend['trend'],
      'activeCountIsUpTrend': activeDealsTrend['isUp'],
      'pipeline': pipeline,
    };
  });
});
