import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://iyylebbrcawebwsqxzup.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5eWxlYmJyY2F3ZWJ3c3F4enVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMzMwMzksImV4cCI6MjA4NjcwOTAzOX0.KvcQj5CYblv708lgKzBQPbnd6oDiiH4AC1cMhwMnRjY',
  );

  try {
    final res = await supabase.rpc('get_table_columns', params: {'table_name': 'notifications'});
    print('Columns: $res');
  } catch (e) {
    print('Error: $e');
    // Fallback: try to select 1 row to see what we get
    try {
      final res = await supabase.from('notifications').select().limit(1);
      print('One row: $res');
    } catch (e2) {
      print('Error 2: $e2');
    }
  }
}
