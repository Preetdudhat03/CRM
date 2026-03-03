
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';
import 'providers/theme_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/local_notification_service.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    if (!kIsWeb) {
      await Firebase.initializeApp();
    } else {
      // On Web, Firebase usually needs options. 
      // If firebase_options.dart is missing, we try-catch to avoid crashing the whole app.
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('Firebase Web initialization skipped: $e');
      }
    }
    
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://iyylebbrcawebwsqxzup.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5eWxlYmJyY2F3ZWJ3c3F4enVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMzMwMzksImV4cCI6MjA4NjcwOTAzOX0.KvcQj5CYblv708lgKzBQPbnd6oDiiH4AC1cMhwMnRjY',
    );
    
    // Initialize Local Notifications (Mobile only mostly)
    if (!kIsWeb) {
      await LocalNotificationService.initialize();
      await PushNotificationService.init();
    }

    if (!kIsWeb) {
      // Set preferred orientations
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Make status bar transparent
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
    }

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Initialization error: $e\n$stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Text(
                'Failed to initialize app:\n$e\n\n$stackTrace',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    ));
    return;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}
