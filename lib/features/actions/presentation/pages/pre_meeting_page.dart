import 'package:flutter/material.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/knot_app_bar.dart';

class PreMeetingPage extends StatefulWidget {
  const PreMeetingPage({super.key});

  @override
  State<PreMeetingPage> createState() => _PreMeetingPageState();
}

class _PreMeetingPageState extends State<PreMeetingPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  String? _selectedContactId;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _briefText;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');
      final contacts = await SupabaseService.getContacts(user.id);
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  Future<String?> _askForGoalIfNeeded() async {
    if (_questionController.text.trim().isNotEmpty) {
      return _questionController.text.trim();
    }
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a quick goal?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Optional: what do you want from this meeting?',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Use Goal'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _generateBrief() async {
    if (!_formKey.currentState!.validate()) return;
    final contact = _contacts.firstWhere(
      (c) => c['id'] == _selectedContactId,
    );

    setState(() {
      _isGenerating = true;
      _briefText = null;
    });
    try {
      final notes = await SupabaseService.getNotes(contact['id']);
      final lastContacted = contact['last_contacted_at']?.toString();
      final goal = await _askForGoalIfNeeded();

      final brief = goal == null || goal.isEmpty
          ? await AIService.generatePreMeetingBrief(
              contact['name'],
              notes,
              lastContacted,
            )
          : await AIService.generatePreMeetingAnswer(
              contactName: contact['name'],
              notes: notes,
              question: goal,
            );

      if (!mounted) return;
      setState(() => _briefText = brief);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating brief: $e'),
            backgroundColor: AppTheme.alertCoral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Pre-Meeting',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedContactId,
                      decoration: const InputDecoration(
                        labelText: 'Select Contact',
                      ),
                      items: _contacts
                          .map(
                            (contact) => DropdownMenuItem<String>(
                              value: contact['id'] as String,
                              child: Text(contact['name']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        _selectedContactId = value;
                      }),
                      validator: (value) =>
                          value == null ? 'Please select a contact' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        labelText: 'Optional question or goal',
                        hintText: 'Ask for recap or specific talking points',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateBrief,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate Brief'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    if (_briefText != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Pre-Meeting Brief',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(_briefText!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
