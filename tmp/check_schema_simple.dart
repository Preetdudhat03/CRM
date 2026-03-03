import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://iyylebbrcawebwsqxzup.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5eWxlYmJyY2F3ZWJ3c3F4enVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMzMwMzksImV4cCI6MjA4NjcwOTAzOX0.KvcQj5CYblv708lgKzBQPbnd6oDiiH4AC1cMhwMnRjY',
  );

  try {
    print('Checking notifications table...');
    final List<dynamic> res = await supabase.from('notifications').select().limit(1);
    if (res.isNotEmpty) {
      print('Columns found: ${res.first.keys.toList()}');
    } else {
      print('Table is empty, trying to insert a dummy row to see what fails...');
      try {
        await supabase.from('notifications').insert({'title': 'test'});
        print('Insert successful with minimal fields');
        final List<dynamic> res2 = await supabase.from('notifications').select().limit(1);
        print('Columns found: ${res2.first.keys.toList()}');
      } catch (e) {
        print('Insert failed: $e');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
