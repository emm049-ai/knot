import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ai_service.dart';
import 'core/services/linkedin_service.dart';

// Firebase temporarily disabled for web compatibility
// import 'firebase_mobile.dart' if (dart.library.html) 'firebase_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  // Initialize Gemini AI
  AIService.initialize();
  
  // Initialize LinkedIn OAuth
  LinkedInService.initialize();
  
  // Firebase temporarily disabled for web compatibility
  // Will be re-enabled for mobile builds
  // if (!kIsWeb) {
  //   try {
  //     await Firebase.initializeApp();
  //   } catch (e) {
  //     print('Firebase initialization skipped: $e');
  //   }
  // }
  
  // Initialize notifications
  await NotificationService.initialize();
  
  runApp(
    const ProviderScope(
      child: KnotApp(),
    ),
  );
}

class KnotApp extends StatelessWidget {
  const KnotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Knot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        // Wrap with back button handler
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            
            final router = AppRouter.router;
            
            // If we can pop the current route, do it
            if (router.canPop()) {
              router.pop();
            } else {
              // Get current location
              final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
              
              // If we're not on home/login/signup, navigate to home
              if (currentLocation != '/home' && 
                  currentLocation != '/login' && 
                  currentLocation != '/signup' &&
                  currentLocation != '/onboarding') {
                router.go('/home');
              } else if (currentLocation == '/home') {
                // On home page, show exit confirmation
                final shouldExit = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Exit Knot?'),
                    content: const Text('Are you sure you want to exit the app?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Exit'),
                      ),
                    ],
                  ),
                );
                
                if (shouldExit == true && context.mounted) {
                  // Let the system handle app exit
                }
              }
            }
          },
          child: child!,
        );
      },
    );
  }
}
