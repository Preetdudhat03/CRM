
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deal_model.dart';
import '../services/deal_service.dart';

// Service Provider
final dealServiceProvider = Provider<DealService>((ref) => DealService());

// State Provider for Search Query
final dealSearchQueryProvider = StateProvider<String>((ref) => '');

// State Notifier for Deal List management
class DealNotifier extends StateNotifier<AsyncValue<List<DealModel>>> {
  final DealService _dealService;

  DealNotifier(this._dealService) : super(const AsyncValue.loading()) {
    getDeals();
  }

  Future<void> getDeals() async {
    try {
      state = const AsyncValue.loading();
      final deals = await _dealService.getDeals();
      state = AsyncValue.data(deals);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addDeal(DealModel deal) async {
    try {
      final newDeal = await _dealService.addDeal(deal);
      state.whenData((deals) {
        state = AsyncValue.data([...deals, newDeal]);
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDeal(DealModel deal) async {
    try {
      final updatedDeal = await _dealService.updateDeal(deal);
      state.whenData((deals) {
        state = AsyncValue.data([
          for (final d in deals)
            if (d.id == deal.id) updatedDeal else d
        ]);
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteDeal(String id) async {
    try {
      await _dealService.deleteDeal(id);
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
  return DealNotifier(ref.watch(dealServiceProvider));
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
    
    return {
      'totalCount': totalDeals,
      'totalValue': totalRevenue,
      'revenueWon': revenueWon,
      'activeCount': activeDeals,
      'pipeline': pipeline,
    };
  });
});
