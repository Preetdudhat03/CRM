import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Custom exception for when the Supabase project is paused.
class SupabasePausedException implements Exception {
  final String message;
  const SupabasePausedException([this.message = 'Supabase project is paused']);

  @override
  String toString() => 'SupabasePausedException: $message';
}

/// Utility class to detect and handle Supabase project paused states.
class SupabaseHealthService {
  /// Known error patterns that indicate the Supabase project is paused or
  /// the database is unavailable (not a transient network blip).
  static const _pausedPatterns = [
    'project is paused',
    'project has been paused',
    'database is paused',
    'project_paused',
    'pgrst_',         // PostgREST error codes when DB is down
    '503',            // HTTP 503 Service Unavailable
    'service unavailable',
    'connection refused',
    'connection to server',
    'no pg_hba.conf entry',
    'could not translate host name',
    'unable to connect to the database',
    'PGRST000',
    'result is not ok',
  ];

  /// Returns true if the given error indicates the Supabase project is paused.
  static bool isProjectPaused(Object error) {
    final errorStr = error.toString().toLowerCase();

    for (final pattern in _pausedPatterns) {
      if (errorStr.contains(pattern.toLowerCase())) {
        return true;
      }
    }

    // PostgrestException with specific status codes
    if (error is PostgrestException) {
      final code = error.code;
      if (code == '503' || code == 'PGRST000' || code == '502') {
        return true;
      }
    }

    return false;
  }

  /// Checks if Supabase is reachable by performing a simple, lightweight query.
  /// Returns `true` if healthy, throws [SupabasePausedException] if paused.
  static Future<bool> checkHealth() async {
    try {
      final supabase = Supabase.instance.client;
      // Try a simple count query – extremely lightweight
      await supabase
          .from('profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint('[SupabaseHealth] Health check error: $e');
      if (isProjectPaused(e)) {
        throw const SupabasePausedException();
      }
      // Could be a transient error or auth issue – still accessible
      return true;
    }
  }

  /// Wraps an error check: if the error looks like a paused-project error,
  /// throws [SupabasePausedException] instead so the UI can handle it.
  static void rethrowIfPaused(Object error) {
    if (isProjectPaused(error)) {
      throw SupabasePausedException(
        'Database is currently unavailable. The Supabase project may be paused. '
        'Please visit your Supabase dashboard to resume it.',
      );
    }
  }
}
