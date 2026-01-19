import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/linkedin_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/knot_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkedInImportPage extends StatefulWidget {
  const LinkedInImportPage({super.key});

  @override
  State<LinkedInImportPage> createState() => _LinkedInImportPageState();
}

class _LinkedInImportPageState extends State<LinkedInImportPage> {
  final _urlController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Check for OAuth callback parameters in URL (for web)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOAuthCallback();
    });
  }

  void _checkOAuthCallback() {
    // Get current route and check for query parameters
    final uri = Uri.base;
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];
    
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('LinkedIn OAuth error: $error'),
          backgroundColor: AppTheme.alertCoral,
        ),
      );
      // Clear the error from URL
      context.go('/import/linkedin');
      return;
    }
    
    if (code != null) {
      _handleOAuthCallback(code, uri.queryParameters['state']);
    }
  }

  Future<void> _handleOAuthCallback(String code, String? state) async {
    if (_isProcessing) return; // Prevent duplicate processing
    
    setState(() => _isProcessing = true);
    try {
      // Exchange code for access token
      await LinkedInService.exchangeCodeForToken(code);
      
      // Get user's own profile
      final profile = await LinkedInService.getOwnProfile();
      
      // Navigate to capture page with pre-filled data
      if (mounted) {
        // Clear the code from URL first
        context.go('/import/linkedin');
        
        // Small delay to ensure URL is cleared
        await Future.delayed(const Duration(milliseconds: 100));
        
        context.push('/capture', extra: {
          'prefill': {
            'name': '${profile['given_name'] ?? ''} ${profile['family_name'] ?? ''}'.trim(),
            'email': profile['email'],
            'linkedin_url': profile['sub'] != null 
                ? 'https://linkedin.com/in/${profile['sub']}'
                : null,
          },
          'source': 'linkedin_oauth',
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing LinkedIn OAuth: $e'),
            backgroundColor: AppTheme.alertCoral,
            duration: const Duration(seconds: 5),
          ),
        );
        // Clear the code from URL
        context.go('/import/linkedin');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _importFromUrl() async {
    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a LinkedIn URL')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final enrichedData = await LinkedInService.enrichLinkedInProfile(
        _urlController.text.trim(),
      );

      if (enrichedData != null) {
        // Navigate to capture page with pre-filled data
        context.push('/capture', extra: {
          'prefill': enrichedData,
          'source': 'linkedin',
        });
      } else {
        throw Exception('Could not enrich LinkedIn profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _importViaOAuth() async {
    setState(() => _isProcessing = true);
    try {
      await LinkedInService.launchOAuthFlow();
      // OAuth callback will be handled by the app's deep link handler
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting OAuth: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Import from LinkedIn',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.business,
                      size: 48,
                      color: AppTheme.primaryIndigo,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Import LinkedIn Profile',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter a LinkedIn profile URL or connect via OAuth',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // URL Import
            Text(
              'Option 1: Import from URL',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'LinkedIn Profile URL',
                hintText: 'https://linkedin.com/in/username',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _importFromUrl,
              icon: const Icon(Icons.download),
              label: const Text('Import from URL'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // OAuth Import
            Text(
              'Option 2: Connect with LinkedIn',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _importViaOAuth,
              icon: const Icon(Icons.login),
              label: const Text('Connect LinkedIn Account'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppTheme.primaryIndigo),
              ),
            ),
            
            if (_isProcessing) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
