import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/contact_model.dart';
import '../../../../core/models/note_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/avatar_service.dart';
import '../../../../core/services/avatar_library_service.dart';
import '../../../../core/utils/relationship_health_calculator.dart';
import '../../../../features/gamification/presentation/widgets/relationship_plant_widget.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/knot_app_bar.dart';
import '../../../drafts/presentation/widgets/conversational_draft_widget.dart';
import '../../../../core/services/draft_conversation_service.dart';
import '../../../../core/models/user_profile_model.dart';

class ContactDetailPage extends StatefulWidget {
  final String contactId;

  const ContactDetailPage({super.key, required this.contactId});

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  Contact? _contact;
  List<Note> _notes = [];
  bool _isLoading = true;
  bool _isGeneratingEmail = false;
  List<DraftConversation> _conversationHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadContact();
    _loadConversationHistory();
  }

  @override
  void dispose() {
    // Auto-save any active conversations when leaving
    _saveActiveConversations();
    super.dispose();
  }

  Future<void> _saveActiveConversations() async {
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return;

      // Mark all active conversations for this contact as completed
      for (final conversation in _conversationHistory) {
        if (!conversation.completed) {
          await DraftConversationService.completeConversation(conversation.id);
        }
      }
    } catch (e) {
      print('Error saving conversations: $e');
    }
  }

  Future<void> _loadConversationHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return;

      final history = await DraftConversationService.getConversationHistory(
        userId: user.id,
        contactId: widget.contactId,
        limit: 25,
      );

      if (mounted) {
        setState(() {
          _conversationHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
      print('Error loading conversation history: $e');
    }
  }

  Future<void> _loadContact() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService.getCurrentUser();
      if (user == null) return;

      final contacts = await SupabaseService.getContacts((await user)!.id);
      final contactData = contacts.firstWhere(
        (c) => c['id'] == widget.contactId,
      );
      
      final notesData = await SupabaseService.getNotes(widget.contactId);

      setState(() {
        _contact = Contact.fromJson(contactData);
        _notes = notesData.map((json) => Note.fromJson(json)).toList();
        _isLoading = false;
      });
      
      // Load conversation history after contact is loaded
      await _loadConversationHistory();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contact: $e')),
        );
      }
    }
  }

  Future<void> _generateFollowUpEmail() async {
    if (_contact == null) return;

    setState(() => _isGeneratingEmail = true);
    try {
      final lastNote = _notes.isNotEmpty ? _notes.first.content : 'No previous interaction';
      final personalFacts = <String>[
        if (_contact!.firstInteractionContext != null &&
            _contact!.firstInteractionContext!.isNotEmpty)
          'First interaction: ${_contact!.firstInteractionContext}',
        if (_contact!.relationshipNature != null &&
            _contact!.relationshipNature!.isNotEmpty)
          'Relationship: ${_contact!.relationshipNature}',
        if (_contact!.relationshipGoal != null &&
            _contact!.relationshipGoal!.isNotEmpty)
          'Goal: ${_contact!.relationshipGoal}',
        if (_contact!.maritalStatus != null &&
            _contact!.maritalStatus!.isNotEmpty)
          'Marital status: ${_contact!.maritalStatus}',
        if (_contact!.kidsDetails != null && _contact!.kidsDetails!.isNotEmpty)
          'Kids: ${_contact!.kidsDetails}',
        if (_contact!.additionalDetails != null &&
            _contact!.additionalDetails!.isNotEmpty)
          'Other: ${_contact!.additionalDetails}',
        ...?_contact!.tags,
      ];
      
      final email = await AIService.generateFollowUpEmail(
        _contact!.name,
        lastNote,
        personalFacts,
      );

      if (mounted) {
        String currentDraft = email;
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => Dialog(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Follow-Up Email',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: ConversationalDraftWidget(
                          initialDraft: email,
                          context: 'email',
                          contactId: _contact!.id,
                          onDraftReady: (finalDraft) {
                            currentDraft = finalDraft;
                            setDialogState(() {});
                          },
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: currentDraft));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email copied to clipboard! Open your email app to send.'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            // Try to open email app
                            if (_contact!.email != null) {
                              final emailUri = Uri(
                                scheme: 'mailto',
                                path: _contact!.email,
                                query: 'subject=Follow-up&body=${Uri.encodeComponent(currentDraft)}',
                              );
                              launchUrl(emailUri);
                            }
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Copy & Open Email'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating email: $e'),
            backgroundColor: AppTheme.alertCoral,
            duration: const Duration(seconds: 5),
          ),
        );
        print('Email generation error: $e');
      }
    } finally {
      setState(() => _isGeneratingEmail = false);
    }
  }

  Future<void> _addNote() async {
    if (_contact == null) return;

    final noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Enter your note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && noteController.text.trim().isNotEmpty) {
      try {
        await SupabaseService.createNote(
          widget.contactId,
          noteController.text.trim(),
          'manual',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note added successfully!'),
              backgroundColor: AppTheme.growthGreen,
            ),
          );
          // Reload contact to show new note
          _loadContact();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding note: $e'),
              backgroundColor: AppTheme.alertCoral,
            ),
          );
          print('Note creation error: $e');
        }
      }
    }
  }

  bool _hasImageApiKey() {
    // Check if any image generation API key is available
    final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final stabilityKey = dotenv.env['STABILITY_AI_API_KEY'] ?? '';
    return geminiKey.isNotEmpty || stabilityKey.isNotEmpty;
  }

  Future<void> _openAvatarEditor() async {
    if (_contact == null) return;

    String selectedRole = _contact!.avatarRole ?? 'Auto';
    String selectedSkin = _contact!.avatarSkinTone ?? 'Auto';
    String selectedOutfit = _contact!.avatarOutfit ?? 'Auto';
    String selectedAccessory = _contact!.avatarAccessory ?? 'Auto';
    bool isGenerating = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Customize Profile Look',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Role',
                  value: selectedRole,
                  items: _avatarRoles,
                  onChanged: (value) => selectedRole = value ?? 'Auto',
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: 'Skin Tone',
                  value: selectedSkin,
                  items: _skinToneOptions,
                  onChanged: (value) => selectedSkin = value ?? 'Auto',
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: 'Outfit',
                  value: selectedOutfit,
                  items: _outfitOptions,
                  onChanged: (value) => selectedOutfit = value ?? 'Auto',
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: 'Accessory',
                  value: selectedAccessory,
                  items: _accessoryOptions,
                  onChanged: (value) => selectedAccessory = value ?? 'Auto',
                ),
                const SizedBox(height: 20),
                // Only show AI generation if API key is available
                if (_hasImageApiKey())
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isGenerating
                          ? null
                          : () async {
                              setSheetState(() => isGenerating = true);
                              try {
                                // Generate prompt using Gemini
                                final prompt = await AIService.generateAvatarPrompt(
                                  contactName: _contact!.name,
                                  jobTitle: _contact!.jobTitle,
                                  company: _contact!.company,
                                  role: selectedRole == 'Auto'
                                      ? _inferRole(_contact!.jobTitle)
                                      : selectedRole,
                                  skinTone: selectedSkin == 'Auto' ? null : selectedSkin,
                                  outfit: selectedOutfit == 'Auto' ? null : selectedOutfit,
                                  accessory: selectedAccessory == 'Auto' ? null : selectedAccessory,
                                );
                                
                                // Generate image using free API
                                final imageUrl = await AvatarService.generateAvatarImage(prompt);
                                
                                // Save to Supabase
                                await SupabaseService.updateContact(
                                  _contact!.id,
                                  {
                                    'avatar_url': imageUrl,
                                    'avatar_role': selectedRole,
                                    'avatar_skin_tone': selectedSkin,
                                    'avatar_outfit': selectedOutfit,
                                    'avatar_accessory': selectedAccessory,
                                  },
                                );
                                
                                if (!mounted) return;
                                setState(() {
                                  _contact = _contact!.copyWith(avatarUrl: imageUrl);
                                });
                                Navigator.pop(context, true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('AI avatar generated successfully!'),
                                    backgroundColor: AppTheme.growthGreen,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('AI generation failed: ${e.toString()}'),
                                    backgroundColor: AppTheme.alertCoral,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              } finally {
                                setSheetState(() => isGenerating = false);
                              }
                            },
                      icon: isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: const Text('Generate AI Avatar (Optional)'),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppTheme.mediumGray),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI avatar generation requires an API key. The custom avatar above works great!',
                            style: TextStyle(fontSize: 12, color: AppTheme.mediumGray),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == true) {
      try {
        final updated = await SupabaseService.updateContact(
          _contact!.id,
          {
            'avatar_role': selectedRole,
            'avatar_skin_tone': selectedSkin,
            'avatar_outfit': selectedOutfit,
            'avatar_accessory': selectedAccessory,
          },
        );
        setState(() {
          _contact = Contact.fromJson(updated);
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile look: $e'),
            backgroundColor: AppTheme.alertCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _contact == null) {
      return Scaffold(
        appBar: KnotAppBar(
          context: context,
          titleText: 'Contact',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final health = RelationshipHealthCalculator.calculateHealth(_contact!);
    final healthEmoji = RelationshipHealthCalculator.getHealthEmoji(health);

    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: _contact!.name,
        extraActions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _openAvatarEditor,
                      child: ContactAvatarProfile(contact: _contact!),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _openAvatarEditor,
                      icon: const Icon(Icons.edit),
                      label: const Text('Customize look'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _contact!.name,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    if (_contact!.company != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _contact!.company!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    if (_contact!.jobTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _contact!.jobTitle!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 16),
                    RelationshipPlantWidget(health: health, size: 80),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            ElevatedButton.icon(
              onPressed: _isGeneratingEmail ? null : _generateFollowUpEmail,
              icon: _isGeneratingEmail
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.email),
              label: const Text('Draft Follow-Up Email'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contact Details
            Text(
              'Details',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_contact!.email != null)
                      _buildDetailRow(Icons.email, 'Email', _contact!.email!),
                    if (_contact!.phone != null) ...[
                      const Divider(),
                      _buildDetailRow(Icons.phone, 'Phone', _contact!.phone!),
                    ],
                    if (_contact!.linkedinUrl != null) ...[
                      const Divider(),
                      _buildDetailRow(
                        Icons.link,
                        'LinkedIn',
                        _contact!.linkedinUrl!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Notes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                TextButton(
                  onPressed: _addNote,
                  child: const Text('Add Note'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_notes.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No notes yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              )
            else
              ..._notes.map((note) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(note.content),
                      subtitle: Text(
                        '${note.inputType} • ${DateFormat('MMM d, y').format(note.createdAt)}',
                      ),
                    ),
                  )),
            
            const SizedBox(height: 24),
            
            // Conversation History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conversation History',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                if (_isLoadingHistory)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_conversationHistory.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No conversations yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              )
            else
              ..._conversationHistory.map((conversation) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(
                      conversation.topicName ?? 
                      '${conversation.context} conversation',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      DateFormat('MMM d, y • h:mm a').format(conversation.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (conversation.conversationHistory.isEmpty)
                              Text(
                                'No conversation history',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              ...conversation.conversationHistory.map((msg) {
                                final isUser = msg['role'] == 'user';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? AppTheme.primaryIndigo.withOpacity(0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isUser ? Icons.person : Icons.smart_toy,
                                            size: 16,
                                            color: isUser 
                                                ? AppTheme.primaryIndigo 
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isUser ? 'You' : 'Assistant',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isUser 
                                                  ? AppTheme.primaryIndigo 
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(msg['content'] as String),
                                      if (msg['changes'] != null) ...[
                                        const SizedBox(height: 8),
                                        ...(msg['changes'] as List).map((change) => Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Text(
                                                '• $change',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.accentTeal,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            )),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.mediumGray),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarStyle {
  final String role;
  final String skinTone;
  final String outfit;
  final String accessory;

  const _AvatarStyle({
    required this.role,
    required this.skinTone,
    required this.outfit,
    required this.accessory,
  });
}

const List<String> _avatarRoles = [
  'Auto',
  'Finance',
  'Construction',
  'Recruiter',
  'Professor',
  'Healthcare',
  'Sales',
  'Engineer',
  'Creative',
  'General',
];

const List<String> _skinToneOptions = [
  'Auto',
  'Light',
  'Tan',
  'Medium',
  'Brown',
  'Deep',
];

const List<String> _outfitOptions = [
  'Auto',
  'Blazer',
  'Vest',
  'Hoodie',
  'Jacket',
  'Lab Coat',
  'Safety Vest',
];

const List<String> _accessoryOptions = [
  'Auto',
  'Glasses',
  'Hard Hat',
  'Clipboard',
  'None',
];

class ContactAvatarProfile extends StatefulWidget {
  const ContactAvatarProfile({super.key, required this.contact});

  final Contact contact;

  @override
  State<ContactAvatarProfile> createState() => _ContactAvatarProfileState();
}

class _ContactAvatarProfileState extends State<ContactAvatarProfile> {
  String? _libraryAvatarPath;
  bool _isLoadingLibrary = true;

  @override
  void initState() {
    super.initState();
    _loadLibraryAvatar();
  }

  Future<void> _loadLibraryAvatar() async {
    try {
      final avatarPath = await AvatarLibraryService.findMatchingAvatar(widget.contact);
      if (mounted) {
        setState(() {
          _libraryAvatarPath = avatarPath;
          _isLoadingLibrary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLibrary = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Priority 1: User-uploaded or AI-generated avatar (avatarUrl)
    if (widget.contact.avatarUrl != null && widget.contact.avatarUrl!.isNotEmpty) {
      // Check if it's a base64 data URL
      if (widget.contact.avatarUrl!.startsWith('data:image')) {
        final base64String = widget.contact.avatarUrl!.split(',')[1];
        final imageBytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 200,
            height: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackAvatar(),
            ),
          ),
        );
      } else {
        // Regular network URL
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 200,
            height: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Image.network(
              widget.contact.avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackAvatar(),
            ),
          ),
        );
      }
    }

    // Priority 2: Library avatar (if matched)
    if (!_isLoadingLibrary && _libraryAvatarPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 200,
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            _libraryAvatarPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackAvatar(),
          ),
        ),
      );
    }

    // Priority 3: Programmatic avatar (fallback)
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    final style = _resolveAvatarStyle(widget.contact);
    final skinColor = _skinToneColor(style.skinTone);
    final shirtColor = _roleColor(style.role);
    final pantsColor = _pantsColorForRole(style.role);
    final hairColor = _hairColorForRole(style.role);
    final accentColor = _accentColorForRole(style.role);

    return Container(
      width: 200,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightGray.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Background gradient
          Positioned(
            top: 10,
            child: Container(
              width: 180,
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    shirtColor.withOpacity(0.08),
                    shirtColor.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          // Head
          Positioned(
            top: 20,
            child: _buildHead(
              skinColor: skinColor,
              hairColor: hairColor,
              accentColor: accentColor,
              initial: widget.contact.name.trim().isNotEmpty
                  ? widget.contact.name.trim()[0].toUpperCase()
                  : '?',
              role: style.role,
              accessory: style.accessory,
              showInitial: false,
            ),
          ),
          // Torso
          Positioned(
            top: 100,
            child: _buildTorso(
              shirtColor: shirtColor,
              accentColor: accentColor,
              outfit: style.outfit,
            ),
          ),
          // Arms
          Positioned(
            top: 138,
            child: _buildArms(
              sleeveColor: shirtColor,
              skinColor: skinColor,
              outfit: style.outfit,
            ),
          ),
          // Legs
          Positioned(
            top: 190,
            child: _buildLegs(
              pantsColor: pantsColor,
              accentColor: accentColor,
            ),
          ),
          // Accessory (hand-held)
          if (style.accessory == 'Clipboard')
            Positioned(
              top: 175,
              right: 8,
              child: _buildAccessory(style.accessory, accentColor),
            ),
        ],
      ),
    );
  }
}

DropdownButtonFormField<String> _buildDropdownField({
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return DropdownButtonFormField<String>(
    value: items.contains(value) ? value : items.first,
    items: items
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}

_AvatarStyle _resolveAvatarStyle(Contact contact) {
  final inferredRole = _inferRole(contact.jobTitle);
  final role = contact.avatarRole == null || contact.avatarRole == 'Auto'
      ? inferredRole
      : contact.avatarRole!;
  final skinTone =
      contact.avatarSkinTone == null || contact.avatarSkinTone == 'Auto'
          ? 'Medium'
          : contact.avatarSkinTone!;
  final outfit = contact.avatarOutfit == null || contact.avatarOutfit == 'Auto'
      ? _defaultOutfitForRole(role)
      : contact.avatarOutfit!;
  final accessory =
      contact.avatarAccessory == null || contact.avatarAccessory == 'Auto'
          ? _defaultAccessoryForRole(role)
          : contact.avatarAccessory!;

  return _AvatarStyle(
    role: role,
    skinTone: skinTone,
    outfit: outfit,
    accessory: accessory,
  );
}

String _inferRole(String? jobTitle) {
  final title = (jobTitle ?? '').toLowerCase();
  if (title.contains('finance') ||
      title.contains('account') ||
      title.contains('invest')) {
    return 'Finance';
  }
  if (title.contains('construction') ||
      title.contains('contractor') ||
      title.contains('builder') ||
      title.contains('foreman')) {
    return 'Construction';
  }
  if (title.contains('recruit') || title.contains('talent')) {
    return 'Recruiter';
  }
  if (title.contains('professor') ||
      title.contains('teacher') ||
      title.contains('lecturer')) {
    return 'Professor';
  }
  if (title.contains('doctor') ||
      title.contains('nurse') ||
      title.contains('medical') ||
      title.contains('health')) {
    return 'Healthcare';
  }
  if (title.contains('sales') || title.contains('account executive')) {
    return 'Sales';
  }
  if (title.contains('engineer') ||
      title.contains('developer') ||
      title.contains('software')) {
    return 'Engineer';
  }
  if (title.contains('designer') ||
      title.contains('creative') ||
      title.contains('artist')) {
    return 'Creative';
  }
  return 'General';
}

String _defaultOutfitForRole(String role) {
  switch (role) {
    case 'Finance':
      return 'Vest';
    case 'Construction':
      return 'Safety Vest';
    case 'Recruiter':
      return 'Blazer';
    case 'Professor':
      return 'Blazer';
    case 'Healthcare':
      return 'Lab Coat';
    case 'Engineer':
      return 'Jacket';
    case 'Sales':
      return 'Blazer';
    case 'Creative':
      return 'Hoodie';
    default:
      return 'Jacket';
  }
}

String _defaultAccessoryForRole(String role) {
  switch (role) {
    case 'Construction':
      return 'Hard Hat';
    case 'Recruiter':
      return 'Clipboard';
    case 'Professor':
      return 'Glasses';
    case 'Healthcare':
      return 'Clipboard';
    default:
      return 'None';
  }
}

Color _roleColor(String role) {
  switch (role) {
    case 'Finance':
      return AppTheme.primaryIndigo;
    case 'Construction':
      return AppTheme.accentAmber;
    case 'Recruiter':
      return AppTheme.accentTeal;
    case 'Professor':
      return AppTheme.accentPurple;
    case 'Healthcare':
      return AppTheme.growthGreen;
    case 'Sales':
      return AppTheme.alertCoral;
    case 'Engineer':
      return Colors.blueGrey;
    case 'Creative':
      return Colors.pinkAccent;
    default:
      return AppTheme.primaryIndigo;
  }
}

Color _skinToneColor(String tone) {
  switch (tone) {
    case 'Light':
      return const Color(0xFFF5D7C4);
    case 'Tan':
      return const Color(0xFFE1B899);
    case 'Medium':
      return const Color(0xFFC9926B);
    case 'Brown':
      return const Color(0xFF9C6B4A);
    case 'Deep':
      return const Color(0xFF6A4A3C);
    default:
      return const Color(0xFFC9926B);
  }
}

Widget _buildHead({
  required Color skinColor,
  required Color hairColor,
  required Color accentColor,
  required String initial,
  required String role,
  required String accessory,
  required bool showInitial,
}) {
  return SizedBox(
    width: 120,
    height: 120,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        // Hair (back layer)
        Positioned(
          top: 8,
          child: Container(
            width: 90,
            height: 38,
            decoration: BoxDecoration(
              color: hairColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          top: 20,
          child: Container(
            width: 76,
            height: 20,
            decoration: BoxDecoration(
              color: hairColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        // Face
        Positioned(
          top: 28,
          child: Container(
            width: 88,
            height: 80,
            decoration: BoxDecoration(
              color: skinColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showInitial)
                  Text(
                    initial,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Eyebrows
        Positioned(
          top: 42,
          left: 24,
          child: _buildBrow(accentColor),
        ),
        Positioned(
          top: 42,
          right: 24,
          child: _buildBrow(accentColor),
        ),
        // Eyes
        Positioned(
          top: 50,
          left: 28,
          child: Row(
            children: [
              _buildEye(accentColor, irisColor: Colors.black87),
              const SizedBox(width: 10),
              _buildEye(accentColor, irisColor: Colors.black87),
            ],
          ),
        ),
        // Nose
        Positioned(
          top: 62,
          child: Container(
            width: 12,
            height: 8,
            decoration: BoxDecoration(
              color: skinColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // Mouth
        Positioned(
          top: 70,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // Ears
        Positioned(
          top: 56,
          left: 4,
          child: _buildEar(skinColor),
        ),
        Positioned(
          top: 56,
          right: 4,
          child: _buildEar(skinColor),
        ),
        // Hard Hat
        if (accessory == 'Hard Hat')
          Positioned(
            top: 0,
            child: Container(
              width: 86,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentAmber,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        // Glasses
        if (accessory == 'Glasses')
          Positioned(
            top: 48,
            child: Container(
              width: 64,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: accentColor, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 24,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 18,
                    color: accentColor,
                  ),
                  Container(
                    width: 24,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildTorso({
  required Color shirtColor,
  required Color accentColor,
  required String outfit,
}) {
  return SizedBox(
    width: 130,
    height: 100,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        // Base shirt
        Container(
          width: 120,
          height: 88,
          decoration: BoxDecoration(
            color: shirtColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        // White shirt/collar for blazer/vest
        if (outfit == 'Blazer' || outfit == 'Vest')
          Positioned(
            top: 10,
            child: Container(
              width: 88,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        // Blazer lapels
        if (outfit == 'Blazer')
          Positioned(
            top: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 50,
                  decoration: BoxDecoration(
                    color: shirtColor.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 28,
                  height: 50,
                  decoration: BoxDecoration(
                    color: shirtColor.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ],
            ),
          ),
        // Tie for blazer
        if (outfit == 'Blazer')
          Positioned(
            top: 20,
            child: Container(
              width: 12,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        // Vest
        if (outfit == 'Vest')
          Positioned(
            top: 12,
            child: Container(
              width: 100,
              height: 48,
              decoration: BoxDecoration(
                color: shirtColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),
        // Safety vest
        if (outfit == 'Safety Vest')
          Positioned(
            top: 12,
            child: Container(
              width: 100,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 3,
                      height: 20,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 20,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Lab coat
        if (outfit == 'Lab Coat')
          Positioned(
            top: 8,
            child: Container(
              width: 108,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.98),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: accentColor.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 2,
                    color: accentColor.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ),
        // Belt
        Positioned(
          bottom: 10,
          child: Container(
            width: 70,
            height: 12,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 16,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildArms({
  required Color sleeveColor,
  required Color skinColor,
  required String outfit,
}) {
  final sleeve = outfit == 'Lab Coat'
      ? Colors.white.withOpacity(0.9)
      : sleeveColor.withOpacity(0.9);
  return SizedBox(
    width: 160,
    height: 48,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildArm(sleeve, skinColor, rotate: -0.2),
        _buildArm(sleeve, skinColor, rotate: 0.2),
      ],
    ),
  );
}

Widget _buildLegs({
  required Color pantsColor,
  required Color accentColor,
}) {
  return SizedBox(
    width: 110,
    height: 56,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 34,
              decoration: BoxDecoration(
                color: pantsColor,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 12,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        Column(
          children: [
            Container(
              width: 32,
              height: 34,
              decoration: BoxDecoration(
                color: pantsColor,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 12,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildEye(Color accentColor, {required Color irisColor}) {
  return Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: accentColor.withOpacity(0.9), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Iris
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: irisColor,
            shape: BoxShape.circle,
          ),
        ),
        // Pupil
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
        // Highlight
        Positioned(
          top: 2,
          left: 3,
          child: Container(
            width: 2,
            height: 2,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildEar(Color skinColor) {
  return Container(
    width: 14,
    height: 20,
    decoration: BoxDecoration(
      color: skinColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: skinColor.withOpacity(0.7),
        width: 1.5,
      ),
    ),
    child: Center(
      child: Container(
        width: 6,
        height: 8,
        decoration: BoxDecoration(
          color: skinColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
  );
}

Widget _buildArm(Color sleeve, Color skinColor, {required double rotate}) {
  return Transform.rotate(
    angle: rotate,
    child: Row(
      children: [
        Container(
          width: 28,
          height: 46,
          decoration: BoxDecoration(
            color: sleeve,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 20,
          height: 24,
          decoration: BoxDecoration(
            color: skinColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    ),
  );
}

Widget _buildBrow(Color accentColor) {
  return Container(
    width: 18,
    height: 4,
    decoration: BoxDecoration(
      color: accentColor.withOpacity(0.8),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
  );
}

Widget _buildAccessory(String accessory, Color accentColor) {
  switch (accessory) {
    case 'Clipboard':
      return Container(
        width: 36,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withOpacity(0.5)),
        ),
        child: Center(
          child: Container(
            width: 20,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
    case 'Hard Hat':
      return Container(
        width: 30,
        height: 20,
        decoration: BoxDecoration(
          color: AppTheme.accentAmber,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    default:
      return const SizedBox.shrink();
  }
}

Color _pantsColorForRole(String role) {
  switch (role) {
    case 'Construction':
      return Colors.blueGrey;
    case 'Creative':
      return Colors.deepPurple.withOpacity(0.8);
    case 'Finance':
      return Colors.indigo.withOpacity(0.8);
    case 'Healthcare':
      return Colors.teal.withOpacity(0.8);
    default:
      return AppTheme.mediumGray.withOpacity(0.8);
  }
}

Color _hairColorForRole(String role) {
  switch (role) {
    case 'Creative':
      return Colors.deepPurple;
    case 'Construction':
      return Colors.brown;
    case 'Finance':
      return Colors.black87;
    case 'Professor':
      return Colors.blueGrey;
    default:
      return Colors.black87;
  }
}

Color _accentColorForRole(String role) {
  switch (role) {
    case 'Construction':
      return AppTheme.accentAmber;
    case 'Recruiter':
      return AppTheme.accentTeal;
    case 'Professor':
      return AppTheme.accentPurple;
    case 'Healthcare':
      return AppTheme.growthGreen;
    case 'Sales':
      return AppTheme.alertCoral;
    default:
      return AppTheme.primaryIndigo;
  }
}
