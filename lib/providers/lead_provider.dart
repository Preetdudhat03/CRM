import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/user_model.dart';
import '../repositories/lead_repository.dart';
import '../services/lead_service.dart';
import '../services/activity_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

// Service Provider
final leadServiceProvider = Provider<LeadService>((ref) => LeadService());

final leadRepositoryProvider = Provider<LeadRepository>((ref) {
  return LeadRepository(ref.watch(leadServiceProvider));
});

// State Provider for Search Query
final leadSearchQueryProvider = StateProvider<String>((ref) => '');

class LeadNotifier extends StateNotifier<AsyncValue<List<LeadModel>>> {
  final LeadRepository _repository;
  final Ref _ref;
  RealtimeChannel? _realtimeChannel;
  final UserModel? _currentUser;

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  LeadNotifier(this._repository, this._ref)
    : _currentUser = _ref.read(currentUserProvider),
      super(const AsyncValue.loading()) {
    loadInitial();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    final supabase = Supabase.instance.client;

    _realtimeChannel = supabase
        .channel('public:leads')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leads',
          callback: (payload) {
            refresh();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInitial() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    try {
      state = const AsyncValue.loading();
      final leads = await _repository.getLeads(
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (leads.length < _pageSize) _hasMore = false;
      state = AsyncValue.data(leads);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state is AsyncLoading) return;

    _isLoadingMore = true;
    try {
      _currentPage++;
      final newLeads = await _repository.getLeads(
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (newLeads.length < _pageSize) _hasMore = false;
      state.whenData((currentLeads) {
        state = AsyncValue.data([...currentLeads, ...newLeads]);
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
      // Don't set state to loading – keep existing list during background refresh
      final leads = await _repository.getLeads(
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (leads.length < _pageSize) _hasMore = false;
      state = AsyncValue.data(leads);
    } catch (e, stack) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> addLead(LeadModel lead) async {
    try {
      final newLead = await _repository.addLead(lead);
      state.whenData((leads) {
        state = AsyncValue.data([...leads, newLead]);
      });

      ActivityService.log(
        title: 'Created lead: ${newLead.name}',
        activityactivityType: 'lead',
        relatedId: newLead.id,
      );

      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      _ref
          .read(notificationsProvider.notifier)
          .pushNotificationLocally(
            'New Lead Added',
            '$userName added a new lead: ${newLead.name}',
            activityactivityType: 'lead_created',
            relatedId: newLead.id,
            relatedEntityactivityactivityType: 'lead',
            showOnDevice: false,
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLead(LeadModel lead) async {
    try {
      await _repository.updateLead(lead);

      state.whenData((leads) {
        final existingLead = leads.firstWhere(
          (l) => l.id == lead.id,
          orElse: () => lead,
        );

        state = AsyncValue.data([
          for (final l in leads)
            if (l.id == lead.id) lead else l,
        ]);

        final currentUser = _ref.read(currentUserProvider);
        final userName = currentUser?.name ?? 'Someone';

        if (existingLead.assignedTo != lead.assignedTo &&
            lead.assignedTo.isNotEmpty) {
          _ref
              .read(notificationsProvider.notifier)
              .pushNotificationLocally(
                'Lead Assigned',
                '$userName assigned the lead ${lead.name} to ${lead.assignedTo}',
                activityactivityType: 'lead_assigned',
                relatedId: lead.id,
                relatedEntityactivityactivityType: 'lead',
              );
        } else if (existingLead.status != lead.status) {
          _ref
              .read(notificationsProvider.notifier)
              .pushNotificationLocally(
                'Lead Status Updated',
                '$userName changed lead ${lead.name} status to ${lead.status.label}',
                activityactivityType: 'lead_status_updated',
                relatedId: lead.id,
                relatedEntityactivityactivityType: 'lead',
              );
        } else {
          _ref
              .read(notificationsProvider.notifier)
              .pushNotificationLocally(
                'Lead Updated',
                '$userName updated lead: ${lead.name}',
                activityactivityType: 'lead_updated',
                relatedId: lead.id,
                relatedEntityactivityactivityType: 'lead',
              );
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLead(String id) async {
    try {
      await _repository.deleteLead(id);
      state.whenData((leads) {
        state = AsyncValue.data([
          for (final l in leads)
            if (l.id != id) l,
        ]);
      });
      ActivityService.log(
        title: 'Deleted a lead',
        activityactivityType: 'lead',
        relatedId: id,
      );

      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      _ref
          .read(notificationsProvider.notifier)
          .pushNotificationLocally(
            'Lead Deleted',
            '$userName deleted a lead',
            activityactivityType: 'lead_deleted',
            relatedEntityactivityactivityType: 'lead',
          );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> convertLead(String id) async {
    try {
      await _repository.convertLead(id);
      state.whenData((leads) {
        state = AsyncValue.data([
          for (final l in leads)
            if (l.id == id) l.copyWith(status: LeadStatus.converted) else l,
        ]);
      });
      ActivityService.log(
        title: 'Converted lead to contact',
        activityactivityType: 'lead',
        relatedId: id,
      );

      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      _ref
          .read(notificationsProvider.notifier)
          .pushNotificationLocally(
            'Lead Converted',
            '$userName converted a lead to contact',
            activityactivityType: 'lead_converted',
            relatedId: id,
            relatedEntityactivityactivityType: 'lead',
          );
    } catch (e) {
      rethrow;
    }
  }
}

// Leads List Provider
final leadsProvider =
    StateNotifierProvider<LeadNotifier, AsyncValue<List<LeadModel>>>((ref) {
      return LeadNotifier(ref.watch(leadRepositoryProvider), ref);
    });

// Filtered Leads Provider
final filteredLeadsProvider = Provider<AsyncValue<List<LeadModel>>>((ref) {
  final leadsAsync = ref.watch(leadsProvider);
  final query = ref.watch(leadSearchQueryProvider).toLowerCase();

  return leadsAsync.whenData((leads) {
    // Filter out converted leads from default view
    var activeLeads = leads
        .where((lead) => lead.status != LeadStatus.converted)
        .toList();

    if (query.isEmpty) return activeLeads;
    return activeLeads.where((lead) {
      return lead.name.toLowerCase().contains(query) ||
          lead.email.toLowerCase().contains(query) ||
          lead.source.toLowerCase().contains(query);
    }).toList();
  });
});

