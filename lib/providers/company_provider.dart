import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company_model.dart';
import '../repositories/company_repository.dart';
import '../services/company_service.dart';
import '../services/activity_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

// Service Provider
final companyServiceProvider = Provider<CompanyService>(
  (ref) => CompanyService(),
);

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(ref.watch(companyServiceProvider));
});

// State Provider for Search Query
final companySearchQueryProvider = StateProvider<String>((ref) => '');

class CompanyNotifier extends StateNotifier<AsyncValue<List<CompanyModel>>> {
  final CompanyRepository _repository;
  final Ref _ref;
  RealtimeChannel? _realtimeChannel;

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  CompanyNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    loadInitial();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    final supabase = Supabase.instance.client;

    _realtimeChannel = supabase
        .channel('public:companies')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'companies',
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
      final companies = await _repository.getCompanies(
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (companies.length < _pageSize) {
        _hasMore = false;
      }
      state = AsyncValue.data(companies);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state is AsyncLoading) return;

    _isLoadingMore = true;
    try {
      _currentPage++;
      final newCompanies = await _repository.getCompanies(
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (newCompanies.length < _pageSize) {
        _hasMore = false;
      }
      state.whenData((currentCompanies) {
        state = AsyncValue.data([...currentCompanies, ...newCompanies]);
      });
    } catch (e) {
      _currentPage--; // Revert
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    try {
      final companies = await _repository.getCompanies(
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (companies.length < _pageSize) _hasMore = false;
      state = AsyncValue.data(companies);
    } catch (e, stack) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> addCompany(CompanyModel company) async {
    try {
      final newCompany = await _repository.addCompany(company);
      state.whenData((companies) {
        state = AsyncValue.data([...companies, newCompany]);
      });

      ActivityService.log(
        title: 'Created company: ${newCompany.name}',
        activityType: 'company',
        relatedId: newCompany.id,
      );

      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      _ref
          .read(notificationsProvider.notifier)
          .pushNotificationLocally(
            'New Company Created',
            '$userName added a new company: ${newCompany.name}',
            activityType: 'company_created',
            relatedId: newCompany.id,
            relatedEntityType: 'company',
            showOnDevice: false,
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCompany(CompanyModel company) async {
    try {
      await _repository.updateCompany(company);
      state.whenData((companies) {
        state = AsyncValue.data([
          for (final c in companies)
            if (c.id == company.id) company else c,
        ]);
      });
      ActivityService.log(
        title: 'Updated company: ${company.name}',
        activityType: 'company',
        relatedId: company.id,
      );

      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      _ref
          .read(notificationsProvider.notifier)
          .pushNotificationLocally(
            'Company Updated',
            '$userName updated company: ${company.name}',
            activityType: 'company_updated',
            relatedId: company.id,
            relatedEntityType: 'company',
            showOnDevice: false,
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      await _repository.deleteCompany(id);
      state.whenData((companies) {
        state = AsyncValue.data([
          for (final c in companies)
            if (c.id != id) c,
        ]);
      });
      ActivityService.log(
        title: 'Deleted a company',
        activityType: 'company',
        relatedId: id,
      );

      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      _ref
          .read(notificationsProvider.notifier)
          .pushNotificationLocally(
            'Company Deleted',
            '$userName deleted a company',
            activityType: 'company_deleted',
            relatedEntityType: 'company',
          );
    } catch (e) {
      // Handle error
    }
  }
}

// Companies List Provider
final companiesProvider =
    StateNotifierProvider<CompanyNotifier, AsyncValue<List<CompanyModel>>>((
      ref,
    ) {
      return CompanyNotifier(ref.watch(companyRepositoryProvider), ref);
    });

// Filtered Companies Provider
final filteredCompaniesProvider = Provider<AsyncValue<List<CompanyModel>>>((
  ref,
) {
  final companiesAsync = ref.watch(companiesProvider);
  final query = ref.watch(companySearchQueryProvider).toLowerCase();

  return companiesAsync.whenData((companies) {
    if (query.isEmpty) return companies;
    return companies.where((company) {
      return company.name.toLowerCase().contains(query) ||
          (company.industry?.toLowerCase().contains(query) ?? false);
    }).toList();
  });
});




