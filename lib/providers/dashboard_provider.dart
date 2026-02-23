import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardPeriod {
  thisWeek,
  thisMonth,
}

extension DashboardPeriodExtension on DashboardPeriod {
  String get label {
    switch (this) {
      case DashboardPeriod.thisWeek:
        return 'This Week';
      case DashboardPeriod.thisMonth:
        return 'This Month';
    }
  }

  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case DashboardPeriod.thisWeek:
        // Assuming week starts on Monday
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      case DashboardPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime get previousPeriodStartDate {
    final start = startDate;
    switch (this) {
      case DashboardPeriod.thisWeek:
        return start.subtract(const Duration(days: 7));
      case DashboardPeriod.thisMonth:
        return DateTime(start.year, start.month - 1, 1);
    }
  }

  DateTime get previousPeriodEndDate {
    final start = startDate;
    switch (this) {
      case DashboardPeriod.thisWeek:
        return start.subtract(const Duration(microseconds: 1)); // Just before this week starts
      case DashboardPeriod.thisMonth:
        return DateTime(start.year, start.month, 1).subtract(const Duration(microseconds: 1)); // Just before this month starts
    }
  }
}

final dashboardPeriodProvider = StateProvider<DashboardPeriod>((ref) => DashboardPeriod.thisMonth);

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
