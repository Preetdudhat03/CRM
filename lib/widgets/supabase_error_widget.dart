import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_health_service.dart';
import '../providers/supabase_health_provider.dart';

/// A reusable widget to display Supabase-related errors.
/// Automatically detects if the project is paused and shows a specialized UI.
class SupabaseErrorWidget extends ConsumerWidget {
  final Object error;
  final VoidCallback onRetry;
  final String title;

  const SupabaseErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.title = 'Error Loading Data',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if either the global state is paused OR this specific error looks like a pause
    final isPaused = ref.watch(isSupabasePausedProvider) ||
        SupabaseHealthService.isProjectPaused(error);

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isPaused
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaused ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                size: 64,
                color: isPaused ? Colors.orange.shade600 : Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPaused ? 'Database is Paused' : title,
              style: TextStyle(
                color: Colors.grey.shade900,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPaused
                  ? 'Your Supabase project is currently paused due to inactivity. Please resume it from your Supabase dashboard to continue.'
                  : error.toString().length > 100
                      ? 'Something went wrong while connecting to the database.'
                      : error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // If it was paused, we should first trigger a health check
                    if (isPaused) {
                      ref.read(supabaseHealthProvider.notifier).refresh();
                    }
                    onRetry();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
