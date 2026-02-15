import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations/fade_in_slide.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(currentUserProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      // AuthGate will automatically redirect to home when user is set
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _checkConnection() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      // We'll expose a simple connectivity check method in AuthService 
      // or just try to fetch a public resource. 
      // For now, let's just use Supabase client directly via a test query
      // Since we don't have direct access here easily without importing Supabase,
      // let's add a test method to AuthService.
      final isConnected = await auth.checkConnection();
      
      if (!mounted) return;
      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('✅ Connected to Supabase!'),
             backgroundColor: Colors.green,
             duration: Duration(seconds: 2),
           ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('❌ Connection Failed! Check internet & project URL.'),
             backgroundColor: Colors.red,
           ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FadeInSlide(
                delay: 0,
                child: Icon(
                  Icons.business_center,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              FadeInSlide(
                delay: 0.1,
                child: Text(
                  'Field CRM',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInSlide(
                delay: 0.2,
                child: Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
              const SizedBox(height: 48),
              FadeInSlide(
                delay: 0.3,
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 16),
              FadeInSlide(
                delay: 0.4,
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 32),
              FadeInSlide(
                delay: 0.5,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              // DEVELOPMENT ONLY: Connection Check
              FadeInSlide(
                delay: 0.6,
                child: TextButton.icon(
                  onPressed: _checkConnection,
                  icon: const Icon(Icons.wifi_find),
                  label: const Text('Check Database Connection'),
                ),
              ),
              const SizedBox(height: 8),
              FadeInSlide(
                delay: 0.7,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
