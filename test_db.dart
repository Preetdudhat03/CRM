import 'package:supabase_flutter/supabase_flutter.dart';
void main() async {
  try {
    await Supabase.initialize(
      url: 'https://iyylebbrcawebwsqxzup.supabase.co',
      anonKey: 'sb_publishable_Ek1PWmFz6ZR13fgSg2u4rg_DZi_FRrS',
    );
    final contacts = await Supabase.instance.client.from('contacts').select();
    print('SUCCESS: \$contacts');
  } catch (e) {
    print('ERROR: \$e');
  }
}
