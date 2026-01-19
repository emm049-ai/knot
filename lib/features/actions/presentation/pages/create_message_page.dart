import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/draft_conversation_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/knot_app_bar.dart';
import '../../../drafts/presentation/widgets/conversational_draft_widget.dart';

class CreateMessagePage extends StatefulWidget {
  const CreateMessagePage({super.key});

  @override
  State<CreateMessagePage> createState() => _CreateMessagePageState();
}

class _CreateMessagePageState extends State<CreateMessagePage> {
  final _formKey = GlobalKey<FormState>();
  final _contextController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  String? _selectedContactId;
  String _messageType = 'Email';
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _generatedDraft;
  bool _showConversation = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    // Auto-save any active conversations when leaving
    _saveActiveConversations();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _saveActiveConversations() async {
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null || _selectedContactId == null) return;

      // Get active conversations for this contact and mark as completed
      final history = await DraftConversationService.getConversationHistory(
        userId: user.id,
        contactId: _selectedContactId!,
        limit: 25,
      );

      for (final conversation in history) {
        if (!conversation.completed) {
          await DraftConversationService.completeConversation(conversation.id);
        }
      }
    } catch (e) {
      print('Error saving conversations: $e');
    }
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

  Future<String?> _askForContextIfNeeded() async {
    if (_contextController.text.trim().isNotEmpty) {
      return _contextController.text.trim();
    }
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a quick prompt?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Optional: add any context or goal',
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
            child: const Text('Use Prompt'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _generateMessage() async {
    if (!_formKey.currentState!.validate()) return;
    final contact = _contacts.firstWhere(
      (c) => c['id'] == _selectedContactId,
    );

    setState(() => _isGenerating = true);
    try {
      final prompt = await _askForContextIfNeeded();
      final notes = await SupabaseService.getNotes(contact['id']);
      final lastInteraction =
          notes.isNotEmpty ? notes.first['content']?.toString() : null;

      final message = await AIService.generateMessage(
        contactName: contact['name'],
        messageType: _messageType,
        userPrompt: prompt,
        firstInteractionContext: contact['first_interaction_context'],
        relationshipNature: contact['relationship_nature'],
        relationshipGoal: contact['relationship_goal'],
        personalDetails: _buildPersonalDetails(contact),
        lastInteraction: lastInteraction,
      );

      if (!mounted) return;
      setState(() {
        _generatedDraft = message;
        _showConversation = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating message: $e'),
            backgroundColor: AppTheme.alertCoral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  String _buildPersonalDetails(Map<String, dynamic> contact) {
    final details = <String>[];
    final maritalStatus = contact['marital_status']?.toString();
    if (maritalStatus != null && maritalStatus.isNotEmpty) {
      details.add('Marital status: $maritalStatus');
    }
    final kidsDetails = contact['kids_details']?.toString();
    if (kidsDetails != null && kidsDetails.isNotEmpty) {
      details.add('Kids: $kidsDetails');
    }
    final additional = contact['additional_details']?.toString();
    if (additional != null && additional.isNotEmpty) {
      details.add('Other: $additional');
    }
    return details.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Create a Message',
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
                    DropdownButtonFormField<String>(
                      value: _messageType,
                      decoration: const InputDecoration(
                        labelText: 'Message Type',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Email', child: Text('Email')),
                        DropdownMenuItem(value: 'LinkedIn', child: Text('LinkedIn')),
                        DropdownMenuItem(value: 'Text', child: Text('Text Message')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _messageType = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contextController,
                      decoration: const InputDecoration(
                        labelText: 'Optional prompt',
                        hintText: 'What do you want to say or ask?',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateMessage,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate Message'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    // Conversational draft widget (collapsible)
                    if (_generatedDraft != null && _selectedContactId != null) ...[
                      const SizedBox(height: 24),
                      ExpansionTile(
                        title: const Text('Refine Draft'),
                        subtitle: const Text('Have a conversation to improve your message'),
                        initiallyExpanded: _showConversation,
                        onExpansionChanged: (expanded) {
                          setState(() => _showConversation = expanded);
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ConversationalDraftWidget(
                              initialDraft: _generatedDraft!,
                              context: _messageType.toLowerCase() == 'text message' 
                                  ? 'text' 
                                  : _messageType.toLowerCase(),
                              contactId: _selectedContactId,
                              onDraftReady: (finalDraft) {
                                setState(() {
                                  _generatedDraft = finalDraft;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
