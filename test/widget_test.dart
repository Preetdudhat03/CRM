import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm/providers/theme_provider.dart';

void main() {
  test('ThemeModeNotifier default and toggle test', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final notifier = ThemeModeNotifier(prefs);
    expect(notifier.state, ThemeMode.system);

    notifier.setTheme(ThemeMode.dark);
    expect(notifier.state, ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');

    notifier.setTheme(ThemeMode.light);
    expect(notifier.state, ThemeMode.light);
    expect(prefs.getString('theme_mode'), 'light');
  });
}
