import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log_model.dart';
import '../services/audit_log_service.dart';

final auditLogServiceProvider = Provider((ref) => AuditLogService());

class AuditLogFilter {
  final String? userId; // Email or ID can be supplied depending on UI, typically user_id here.
  final String? action;
  final String? entityType;
  final DateTime? startDate;
  final DateTime? endDate;

  AuditLogFilter({
    this.userId,
    this.action,
    this.entityType,
    this.startDate,
    this.endDate,
  });

  AuditLogFilter copyWith({
    String? userId,
    String? action,
    bool clearAction = false,
    String? entityType,
    bool clearEntityType = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return AuditLogFilter(
      userId: userId ?? this.userId,
      action: clearAction ? null : (action ?? this.action),
      entityType: clearEntityType ? null : (entityType ?? this.entityType),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}

final auditLogFilterProvider = StateProvider<AuditLogFilter>((ref) => AuditLogFilter());

final auditLogsProvider = FutureProvider.autoDispose.family<List<AuditLogModel>, int>((ref, page) async {
  final filter = ref.watch(auditLogFilterProvider);
  final service = ref.watch(auditLogServiceProvider);

  return service.getAuditLogs(
    page: page,
    pageSize: 20, // Keep constant UI-side or move to param
    userId: filter.userId,
    action: filter.action,
    entityType: filter.entityType,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

// A convenient provider for the paginated state pattern. Often we need a combined list...
class PaginatedAuditLogsNotifier extends StateNotifier<AsyncValue<List<AuditLogModel>>> {
  final AuditLogService _service;
  final AuditLogFilter _filter;
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;

  PaginatedAuditLogsNotifier(this._service, this._filter) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  bool get hasMore => _hasMore;

  Future<void> _loadInitial() async {
    try {
      _currentPage = 0;
      final results = await _service.getAuditLogs(
        page: _currentPage,
        pageSize: _pageSize,
        userId: _filter.userId,
        action: _filter.action,
        entityType: _filter.entityType,
        startDate: _filter.startDate,
        endDate: _filter.endDate,
      );
      _hasMore = results.length == _pageSize;
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading || state.hasError) return;
    
    final currentList = state.value ?? [];
    
    try {
      _currentPage++;
      final results = await _service.getAuditLogs(
        page: _currentPage,
        pageSize: _pageSize,
        userId: _filter.userId,
        action: _filter.action,
        entityType: _filter.entityType,
        startDate: _filter.startDate,
        endDate: _filter.endDate,
      );
      
      _hasMore = results.length == _pageSize;
      state = AsyncValue.data([...currentList, ...results]);
    } catch (e, st) {
      // Keep old state but maybe signal error? For now just stay with old list.
      state = AsyncValue.error(e, st);
    }
  }
}

final paginatedAuditLogsProvider = StateNotifierProvider.autoDispose<PaginatedAuditLogsNotifier, AsyncValue<List<AuditLogModel>>>((ref) {
  final filter = ref.watch(auditLogFilterProvider);
  final service = ref.watch(auditLogServiceProvider);
  return PaginatedAuditLogsNotifier(service, filter);
});
