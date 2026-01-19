import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/widgets/knot_app_bar.dart';

class EmailInteractionsImportPage extends StatefulWidget {
  const EmailInteractionsImportPage({super.key});

  @override
  State<EmailInteractionsImportPage> createState() => _EmailInteractionsImportPageState();
}

class _EmailInteractionsImportPageState extends State<EmailInteractionsImportPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _emailInteractions = [];
  final _emailController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadEmailInteractions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadEmailInteractions() async {
    setState(() => _isLoading = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final interactions = await SupabaseService.client
          .from('email_interactions')
          .select()
          .eq('user_id', user.id)
          .order('received_at', ascending: false)
          .limit(100);

      setState(() {
        _emailInteractions = List<Map<String, dynamic>>.from(interactions);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading email interactions: $e')),
        );
      }
    }
  }

  Future<void> _importFromEmail() async {
    final emailText = _emailController.text.trim();
    if (emailText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email content')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Use AI to extract contact info from email
      final extractedData = await AIService.extractContactInfo(emailText);
      
      // Navigate to capture page with pre-filled data
      context.push('/capture', extra: {
        'prefill': extractedData,
        'source': 'email',
        'emailContent': emailText,
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing email: $e')),
        );
      }
    }
  }

  Future<void> _importFromInteraction(Map<String, dynamic> interaction) async {
    setState(() => _isProcessing = true);
    try {
      final emailBody = interaction['body'] as String? ?? '';
      final toEmail = interaction['to_email'] as String? ?? '';
      
      // Extract contact info from email
      final extractedData = await AIService.extractContactInfo(emailBody);
      
      // Add email if found
      if (toEmail.isNotEmpty && !extractedData.containsKey('email')) {
        extractedData['email'] = toEmail;
      }
      
      // Navigate to capture page
      context.push('/capture', extra: {
        'prefill': extractedData,
        'source': 'email_interaction',
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Import from Email',
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
                      Icons.email,
                      size: 48,
                      color: AppTheme.alertCoral,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Import from Email',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Extract contact information from email content',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Manual Email Entry
            Text(
              'Option 1: Paste Email Content',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Content',
                hintText: 'Paste email content here...',
                prefixIcon: Icon(Icons.email),
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _importFromEmail,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Extract Contact Info'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Email Interactions
            Text(
              'Option 2: From Email Interactions',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_emailInteractions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No email interactions yet',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email interactions will appear here after you set up BCC email tracking',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._emailInteractions.map((interaction) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.email),
                      title: Text(interaction['subject'] ?? 'No subject'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('To: ${interaction['to_email']}'),
                          if (interaction['received_at'] != null)
                            Text(
                              'Received: ${DateTime.parse(interaction['received_at']).toString().split(' ')[0]}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _importFromInteraction(interaction),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
