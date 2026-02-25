import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchDashboardMetrics() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Run ALL queries in parallel for speed, each with its own error handling
    final results = await Future.wait([
      // 0: contacts count
      _safeQuery(() => _supabase.from('contacts').count(CountOption.exact), 0),
      // 1: leads count
      _safeQuery(() => _supabase.from('leads').count(CountOption.exact), 0),
      // 2: deals count
      _safeQuery(() => _supabase.from('deals').count(CountOption.exact), 0),
      // 3: won deals for revenue
      _safeQuery(() => _supabase.from('deals').select('value, stage'), <dynamic>[]),
      // 4: recent activities
      _safeQuery(() => _supabase.from('activities').select().order('created_at', ascending: false).limit(10), <dynamic>[]),
      // 5: tasks due today
      _safeQuery(() => _supabase.from('tasks').select().gte('due_date', startOfDay.toIso8601String()).lt('due_date', endOfDay.toIso8601String()).order('due_date', ascending: true).limit(10), <dynamic>[]),
      // 6: pipeline stages
      _safeQuery(() => _supabase.from('deals').select('stage'), <dynamic>[]),
    ]);

    // Process revenue
    double revenueWon = 0.0;
    final wonDeals = results[3] as List<dynamic>;
    for (final deal in wonDeals) {
      final stage = deal['stage'] as String? ?? '';
      if (stage == 'closedWon' || stage == 'closed_won') {
        revenueWon += ((deal['value'] as num?)?.toDouble() ?? 0.0);
      }
    }

    // Process pipeline
    final Map<String, int> rawPipeline = {};
    final stageRows = results[6] as List<dynamic>;
    for (final item in stageRows) {
      final s = item['stage'] as String?;
      if (s != null) {
        rawPipeline[s] = (rawPipeline[s] ?? 0) + 1;
      }
    }

    return {
      'totalContacts': results[0] as int,
      'totalLeads': results[1] as int,
      'totalDeals': results[2] as int,
      'revenueWon': revenueWon,
      'recentActivities': results[4] as List<dynamic>,
      'tasksDueToday': results[5] as List<dynamic>,
      'rawPipeline': rawPipeline,
    };
  }

  /// Runs a query with error handling — returns fallback on failure
  Future<dynamic> _safeQuery(Future<dynamic> Function() query, dynamic fallback) async {
    try {
      return await query();
    } catch (e) {
      print('[Dashboard] query error: $e');
      return fallback;
    }
  }
}
