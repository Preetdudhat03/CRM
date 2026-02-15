import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../main_layout_screen.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    // Simple gate: if user is null, show login, else show main layout
    if (user == null) {
      return const LoginScreen();
    } else {
      return const MainLayoutScreen();
    }
  }
}
