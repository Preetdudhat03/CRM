import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Test Supabase Connection', () async {
    try {
      await Supabase.initialize(
        url: 'https://iyylebbrcawebwsqxzup.supabase.co',
        anonKey: 'sb_publishable_Ek1PWmFz6ZR13fgSg2u4rg_DZi_FRrS',
      );
      final client = Supabase.instance.client;
      final res = await client.from('roles').select();
      print('SUCCESS: \$res');
    } catch (e) {
      print('FAIL: \$e');
    }
  });
}
