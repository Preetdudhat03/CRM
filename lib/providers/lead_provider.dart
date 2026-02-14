
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead_model.dart';
import '../services/lead_service.dart';

// Service Provider
final leadServiceProvider = Provider<LeadService>((ref) => LeadService());

// State Provider for Search Query
final leadSearchQueryProvider = StateProvider<String>((ref) => '');

// State Notifier for Lead List management
class LeadNotifier extends StateNotifier<AsyncValue<List<LeadModel>>> {
  final LeadService _leadService;

  LeadNotifier(this._leadService) : super(const AsyncValue.loading()) {
    getLeads();
  }

  Future<void> getLeads() async {
    try {
      state = const AsyncValue.loading();
      final leads = await _leadService.getLeads();
      state = AsyncValue.data(leads);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addLead(LeadModel lead) async {
    try {
      final newLead = await _leadService.addLead(lead);
      state.whenData((leads) {
        state = AsyncValue.data([...leads, newLead]);
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLead(LeadModel lead) async {
    try {
      await _leadService.updateLead(lead);
      state.whenData((leads) {
        state = AsyncValue.data([
          for (final l in leads)
            if (l.id == lead.id) lead else l
        ]);
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteLead(String id) async {
    try {
      await _leadService.deleteLead(id);
      state.whenData((leads) {
        state = AsyncValue.data([
          for (final l in leads)
            if (l.id != id) l
        ]);
      });
    } catch (e) {
      // Handle error
    }
  }
}

// Leads List Provider
final leadsProvider =
    StateNotifierProvider<LeadNotifier, AsyncValue<List<LeadModel>>>((ref) {
  return LeadNotifier(ref.watch(leadServiceProvider));
});

// Filtered Leads Provider
final filteredLeadsProvider = Provider<AsyncValue<List<LeadModel>>>((ref) {
  final leadsAsync = ref.watch(leadsProvider);
  final query = ref.watch(leadSearchQueryProvider).toLowerCase();

  return leadsAsync.whenData((leads) {
    if (query.isEmpty) return leads;
    return leads.where((lead) {
      return lead.name.toLowerCase().contains(query) ||
          lead.email.toLowerCase().contains(query) ||
          lead.source.toLowerCase().contains(query);
    }).toList();
  });
});

// Dashboard Stats Provider
final leadStatsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final leadsAsync = ref.watch(leadsProvider);

  return leadsAsync.whenData((leads) {
    int total = leads.length;
    int newLeads = leads.where((l) => l.status == LeadStatus.newLead).length;
    int interested = leads.where((l) => l.status == LeadStatus.interested).length;
    int qualified = leads.where((l) => l.status == LeadStatus.qualified).length;
    
    return {
      'total': total,
      'new': newLeads,
      'interested': interested,
      'qualified': qualified,
    };
  });
});
