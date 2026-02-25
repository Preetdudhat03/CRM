import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';

enum DashboardPeriod {
  today,
  quarter,
  thisYear,
  allTime,
}

extension DashboardPeriodExtension on DashboardPeriod {
  String get label {
    switch (this) {
      case DashboardPeriod.today:
        return 'Today';
      case DashboardPeriod.quarter:
        return 'Quarter';
      case DashboardPeriod.thisYear:
        return 'This Year';
      case DashboardPeriod.allTime:
        return 'All Time';
    }
  }

  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case DashboardPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case DashboardPeriod.quarter:
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, quarterMonth, 1);
      case DashboardPeriod.thisYear:
        return DateTime(now.year, 1, 1);
      case DashboardPeriod.allTime:
        return DateTime(2000, 1, 1);
    }
  }

  DateTime get previousPeriodStartDate {
    final start = startDate;
    switch (this) {
      case DashboardPeriod.today:
        return start.subtract(const Duration(days: 1));
      case DashboardPeriod.quarter:
        return DateTime(start.year, start.month - 3, 1);
      case DashboardPeriod.thisYear:
        return DateTime(start.year - 1, 1, 1);
      case DashboardPeriod.allTime:
        return DateTime(2000, 1, 1);
    }
  }

  DateTime get previousPeriodEndDate {
    final start = startDate;
    switch (this) {
      case DashboardPeriod.today:
        return start.subtract(const Duration(microseconds: 1));
      case DashboardPeriod.quarter:
        return start.subtract(const Duration(microseconds: 1));
      case DashboardPeriod.thisYear:
        return DateTime(start.year, 1, 1).subtract(const Duration(microseconds: 1));
      case DashboardPeriod.allTime:
        return DateTime.now();
    }
  }
}

final dashboardPeriodProvider = StateProvider<DashboardPeriod>((ref) => DashboardPeriod.allTime);

// Helper function to calculate trend
Map<String, dynamic> calculateTrend(int current, int previous) {
  if (previous == 0) {
    if (current == 0) return {'trend': 0.0, 'isUp': true};
    return {'trend': 100.0, 'isUp': true};
  }
  
  final double change = ((current - previous) / previous) * 100;
  return {
    'trend': change.abs(),
    'isUp': change >= 0,
  };
}

// Dashboard Provider
final dashboardServiceProvider = Provider<DashboardService>((ref) => DashboardService());

final dashboardMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return await service.fetchDashboardMetrics();
});
