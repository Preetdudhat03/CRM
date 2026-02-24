import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Use same sharedPreferencesProvider from theme_provider.dart
import 'theme_provider.dart';

class NotificationSettingsNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'device_notifications_enabled';

  NotificationSettingsNotifier(this._prefs) : super(_load(_prefs));

  static bool _load(SharedPreferences prefs) {
    return prefs.getBool(_key) ?? true; // Enabled by default
  }

  void toggle() {
    state = !state;
    _prefs.setBool(_key, state);
  }

  void setEnabled(bool enabled) {
    state = enabled;
    _prefs.setBool(_key, enabled);
  }
}

final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationSettingsNotifier(prefs);
});
