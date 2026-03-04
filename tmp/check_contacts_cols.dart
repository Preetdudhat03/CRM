import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://[SUPABASE_PROJECT_URL].supabase.co',
    '[SUPABASE_ANON_KEY]'
  );
  // Need the actual url and key... but I don't have them in plaintext here.
}
