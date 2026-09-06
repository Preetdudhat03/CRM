import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_health_service.dart';

/// Represents the connection state of the Supabase backend.
enum SupabaseConnectionState {
  healthy,
  paused,
  checking,
  unknown,
}

/// Provider that tracks whether the Supabase project is paused.
/// Any provider/service can report a paused state, and the UI reacts.
class SupabaseHealthNotifier extends StateNotifier<SupabaseConnectionState> {
  Timer? _retryTimer;

  SupabaseHealthNotifier() : super(SupabaseConnectionState.unknown);

  /// Call this when any Supabase query detects a paused-project error.
  void reportPaused() {
    if (state != SupabaseConnectionState.paused) {
      state = SupabaseConnectionState.paused;
      // Schedule periodic re-checks every 30 seconds
      _startRetryTimer();
    }
  }

  /// Call this when a Supabase query succeeds, meaning the project is live.
  void reportHealthy() {
    if (state != SupabaseConnectionState.healthy) {
      state = SupabaseConnectionState.healthy;
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  /// Actively check Supabase health.
  Future<void> checkHealth() async {
    state = SupabaseConnectionState.checking;
    try {
      await SupabaseHealthService.checkHealth();
      state = SupabaseConnectionState.healthy;
      _retryTimer?.cancel();
      _retryTimer = null;
    } on SupabasePausedException {
      state = SupabaseConnectionState.paused;
      _startRetryTimer();
    } catch (e) {
      // Unknown error — keep current state or set unknown
      if (state == SupabaseConnectionState.checking) {
        state = SupabaseConnectionState.unknown;
      }
    }
  }

  /// Alias to check health
  Future<void> refresh() => checkHealth();

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkHealth();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }
}

final supabaseHealthProvider =
    StateNotifierProvider<SupabaseHealthNotifier, SupabaseConnectionState>(
  (ref) => SupabaseHealthNotifier(),
);

/// Convenience: is the Supabase project currently paused?
final isSupabasePausedProvider = Provider<bool>((ref) {
  return ref.watch(supabaseHealthProvider) == SupabaseConnectionState.paused;
});
