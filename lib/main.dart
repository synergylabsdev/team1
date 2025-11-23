import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize Auth Service
  await AuthService().initialize();
  
  runApp(const SampleFinderApp());
}

class SampleFinderApp extends StatefulWidget {
  const SampleFinderApp({super.key});

  @override
  State<SampleFinderApp> createState() => _SampleFinderAppState();
}

class _SampleFinderAppState extends State<SampleFinderApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    // Handle deep links when app is opened from a link
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );

    // Handle deep link if app was opened from a link
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    print('Deep link received: $uri');
    
    // Check if this is an auth callback
    if (uri.scheme == AppConstants.deepLinkScheme &&
        uri.host == 'auth-callback') {
      try {
        // Supabase handles the session from the URL automatically
        // We just need to check if the session was set
        final session = SupabaseService.client.auth.currentSession;
        
        if (session != null) {
          // Reload user profile
          await AuthService().loadUserProfile();
          
          // Navigate to appropriate screen
          if (mounted) {
            final navigator = Navigator.of(context);
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        } else {
          // Try to get session from URL if not already set
          await SupabaseService.client.auth.getSessionFromUrl(uri);
          await AuthService().loadUserProfile();
          
          if (mounted) {
            final navigator = Navigator.of(context);
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        print('Error handling auth callback: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error verifying email: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SampleFinder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Small delay for smooth transition
    
    if (mounted) {
      final authService = AuthService();
      final isOnboardingCompleted = authService.isOnboardingCompleted;
      final isAuthenticated = authService.isAuthenticated;

      setState(() {
        _isLoading = false;
      });

      if (!isOnboardingCompleted) {
        // Show onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else if (!isAuthenticated) {
        // Show login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.explore,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SampleFinder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
          ],
        ),
      ),
    );
  }
}
