import 'dart:async';
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
  /// Returns true if the given error indicates the Supabase project is
  /// paused / the database is completely unreachable.
  ///
  /// This is intentionally broad — when the free-tier project pauses,
  /// the exact error varies by platform (mobile vs web) and SDK version.
  static bool isProjectPaused(Object error) {
    // 1. Check by error TYPE first (most reliable)
    if (error is TimeoutException) return true;

    // Check runtime type name for dart:io types (works without import)
    final typeName = error.runtimeType.toString();
    if (typeName == 'SocketException' ||
        typeName == 'HttpException' ||
        typeName == 'HandshakeException' ||
        typeName == 'TlsException' ||
        typeName == 'ClientException') {
      return true;
    }

    // PostgrestException — check the HTTP status code
    if (error is PostgrestException) {
      final code = error.code;
      // 5xx errors from PostgREST mean the DB behind it is down
      if (code != null &&
          (code.startsWith('5') ||
           code == 'PGRST000' ||
           code == 'PGRST001' ||
           code == '08000' ||     // connection_exception
           code == '08003' ||     // connection_does_not_exist
           code == '08006' ||     // connection_failure
           code == '57P01' ||     // admin_shutdown
           code == '57P03')) {    // cannot_connect_now
        return true;
      }
    }

    // 2. Check by error MESSAGE (fallback — string matching)
    final errorStr = error.toString().toLowerCase();

    const patterns = [
      // Supabase-specific messages
      'project is paused',
      'project has been paused',
      'project_paused',
      'database is paused',

      // PostgREST errors
      'pgrst000',
      'pgrst001',

      // HTTP status errors
      'status 503',
      'status 502',
      'status 500',
      '503 service unavailable',
      '502 bad gateway',

      // Connection / network errors
      'connection refused',
      'connection reset',
      'connection closed',
      'connection timed out',
      'connection failed',
      'connection to server',
      'failed host lookup',
      'no address associated',
      'network is unreachable',
      'no route to host',
      'broken pipe',
      'socket',
      'socketexception',
      'handshakeexception',
      'tlsexception',
      'clientexception',
      'xmlhttprequest error',
      'fetch error',
      'fetcherror',
      'networkerror',
      'failed to fetch',

      // Timeout
      'timeoutexception',
      'timed out',
      'timeout',

      // PostgreSQL connection errors
      'no pg_hba.conf entry',
      'could not translate host name',
      'unable to connect',
      'the database system is shutting down',
      'the database system is starting up',
      'too many connections',
      'remaining connection slots are reserved',
      'server closed the connection unexpectedly',

      // Generic
      'result is not ok',
      'service unavailable',
      'bad gateway',
    ];

    for (final pattern in patterns) {
      if (errorStr.contains(pattern)) {
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
      debugPrint('[SupabaseHealth] Error type: ${e.runtimeType}');
      if (isProjectPaused(e)) {
        throw const SupabasePausedException();
      }
      // Could be an auth/RLS issue — server IS reachable
      return true;
    }
  }
}
