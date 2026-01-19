import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_router.dart';

class BackButtonHandler extends StatelessWidget {
  final Widget child;
  final bool showExitDialog;

  const BackButtonHandler({
    super.key,
    required this.child,
    this.showExitDialog = false,
  });

  @override
  Widget build(BuildContext context) {
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
              currentLocation != '/signup') {
            router.go('/home');
          } else if (currentLocation == '/home' && showExitDialog) {
            // On home page, show exit confirmation if requested
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
      child: child,
    );
  }
}
