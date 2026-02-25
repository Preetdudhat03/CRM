import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchDashboardMetrics() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Each query is individually wrapped so one failure doesn't kill the dashboard
    int totalContacts = 0;
    int totalLeads = 0;
    int totalDeals = 0;
    double revenueWon = 0.0;
    List<dynamic> recentActivities = [];
    List<dynamic> tasksDueToday = [];
    Map<String, int> rawPipeline = {};

    // 1. Contacts count
    try {
      totalContacts = await _supabase.from('contacts').count(CountOption.exact);
    } catch (e) {
      print('[Dashboard] contacts count error: $e');
    }

    // 2. Leads count
    try {
      totalLeads = await _supabase.from('leads').count(CountOption.exact);
    } catch (e) {
      print('[Dashboard] leads count error: $e');
    }

    // 3. Deals count
    try {
      totalDeals = await _supabase.from('deals').count(CountOption.exact);
    } catch (e) {
      print('[Dashboard] deals count error: $e');
    }

    // 4. Revenue from won deals
    try {
      final wonDeals = await _supabase
          .from('deals')
          .select('value, stage');
      // Sum all deals where stage matches closedWon (camelCase or snake_case)
      for (final deal in wonDeals) {
        final stage = deal['stage'] as String? ?? '';
        if (stage == 'closedWon' || stage == 'closed_won') {
          revenueWon += ((deal['value'] as num?)?.toDouble() ?? 0.0);
        }
      }
    } catch (e) {
      print('[Dashboard] revenue error: $e');
    }

    // 5. Recent activities
    try {
      recentActivities = await _supabase
          .from('activities')
          .select()
          .order('created_at', ascending: false)
          .limit(10);
    } catch (e) {
      print('[Dashboard] activities error: $e');
      // Fallback: if activities table fails, show empty list
    }

    // 6. Tasks due today
    try {
      tasksDueToday = await _supabase
          .from('tasks')
          .select()
          .gte('due_date', startOfDay.toIso8601String())
          .lt('due_date', endOfDay.toIso8601String())
          .order('due_date', ascending: true)
          .limit(10);
    } catch (e) {
      print('[Dashboard] tasks error: $e');
    }

    // 7. Pipeline stages
    try {
      final stageRows = await _supabase
          .from('deals')
          .select('stage');
      for (final item in stageRows) {
        final s = item['stage'] as String?;
        if (s != null) {
          rawPipeline[s] = (rawPipeline[s] ?? 0) + 1;
        }
      }
    } catch (e) {
      print('[Dashboard] pipeline error: $e');
    }

    return {
      'totalContacts': totalContacts,
      'totalLeads': totalLeads,
      'totalDeals': totalDeals,
      'revenueWon': revenueWon,
      'recentActivities': recentActivities,
      'tasksDueToday': tasksDueToday,
      'rawPipeline': rawPipeline,
    };
  }
}
