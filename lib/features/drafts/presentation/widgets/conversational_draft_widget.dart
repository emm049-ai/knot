import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/draft_conversation_service.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/user_profile_model.dart';
import '../../../../core/theme/app_theme.dart';

class ConversationalDraftWidget extends StatefulWidget {
  final String initialDraft;
  final String context; // 'email', 'linkedin', 'text', 'pre_meeting', 'search'
  final String? contactId;
  final Function(String)? onDraftReady;

  const ConversationalDraftWidget({
    super.key,
    required this.initialDraft,
    required this.context,
    this.contactId,
    this.onDraftReady,
  });

  @override
  State<ConversationalDraftWidget> createState() => _ConversationalDraftWidgetState();
}

class _ConversationalDraftWidgetState extends State<ConversationalDraftWidget> {
  DraftConversation? _draft;
  String _currentDraft = '';
  bool _isRefining = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  File? _recordingFile;
  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _draftController = TextEditingController();
  bool _showHistory = false;
  List<String> _lastChanges = [];
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _currentDraft = widget.initialDraft;
    _draftController.text = widget.initialDraft;
    // Listen to text changes to update button state
    _requestController.addListener(() {
      if (mounted) setState(() {});
    });
    _initializeDraft();
  }

  @override
  void dispose() {
    _requestController.dispose();
    _draftController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDraft() async {
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return;

      _draft = await DraftConversationService.getOrCreateDraft(
        userId: user.id,
        contactId: widget.contactId,
        context: widget.context,
        initialDraft: widget.initialDraft,
        topicName: null, // Auto-generate
      );

      if (mounted) {
        setState(() {
          _currentDraft = _draft!.currentDraft;
          _draftController.text = _currentDraft;
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Error initializing draft: $e');
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
    try {
      _recordingFile = await VoiceService.startRecording();
      _startTimer();
    } catch (e) {
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _stopTimer();
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });
    try {
      final file = await VoiceService.stopRecording();
      if (file != null) {
        final transcription = await AIService.transcribeAudio(file);
        // Show transcription dialog
        if (mounted) {
          final editedText = await _showTranscriptionDialog(transcription);
          if (editedText != null && editedText.isNotEmpty) {
            _requestController.text = editedText;
            await _refineDraft(editedText, isVoiceInput: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error transcribing: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTranscribing = false);
      }
    }
  }

  Future<String?> _showTranscriptionDialog(String transcription) async {
    final controller = TextEditingController(text: transcription);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Transcription'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Edit if needed...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  Future<void> _refineDraft(String request, {bool isVoiceInput = false}) async {
    final trimmedRequest = request.trim();
    if (trimmedRequest.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a refinement request')),
        );
      }
      return;
    }
    
    if (_draft == null) {
      // Try to initialize draft first
      await _initializeDraft();
      if (_draft == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Draft not initialized. Please try again.')),
          );
        }
        return;
      }
    }

    setState(() => _isRefining = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) {
        setState(() => _isRefining = false);
        return;
      }

      final oldDraft = _currentDraft;
      final refinedDraft = await DraftConversationService.refineDraft(
        userId: user.id,
        draft: _draft!,
        userRequest: trimmedRequest,
        isVoiceInput: isVoiceInput,
      );

      // Get changes for highlighting
      _lastChanges = DraftConversationService.getChangedSections(
        oldDraft,
        refinedDraft,
      );

      // Reload draft to get updated history
      _draft = await DraftConversationService.getOrCreateDraft(
        userId: user.id,
        contactId: widget.contactId,
        context: widget.context,
        initialDraft: widget.initialDraft,
        topicName: _draft?.topicName, // Keep existing topic name
      );

      if (mounted) {
        setState(() {
          _currentDraft = refinedDraft;
          _draftController.text = refinedDraft;
          _requestController.clear();
        });
        widget.onDraftReady?.call(refinedDraft);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refining draft: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefining = false);
      }
    }
  }

  Future<void> _savePreference(String preference) async {
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return;

      await DraftConversationService.savePreference(
        userId: user.id,
        itemType: 'draft',
        itemId: _draft?.id,
        preference: preference,
        context: widget.context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preference saved!')),
        );
      }
    } catch (e) {
      print('Error saving preference: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Draft display with highlighting
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Draft',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_up_outlined),
                          onPressed: () => _savePreference('like'),
                          tooltip: 'Like',
                        ),
                        IconButton(
                          icon: const Icon(Icons.thumb_down_outlined),
                          onPressed: () => _savePreference('dislike'),
                          tooltip: 'Dislike',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _draftController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Draft will appear here...',
                  ),
                  onChanged: (value) {
                    setState(() => _currentDraft = value);
                  },
                ),
                if (_lastChanges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: const Text('Recent Changes'),
                    initiallyExpanded: false,
                    children: [
                      ..._lastChanges.map((change) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16, color: AppTheme.accentTeal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    change,
                                    style: TextStyle(
                                      color: AppTheme.accentTeal,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Refinement input
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Refine Draft',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _requestController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'E.g., "Make it more casual" or "Add mention of the project"',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      onPressed: _isRecording
                          ? _stopRecording
                          : (_isTranscribing ? null : _startRecording),
                      tooltip: 'Record',
                    ),
                  ),
                ),
                if (_isRecording || _isTranscribing) ...[
                  const SizedBox(height: 8),
                  Text(
                    _isTranscribing
                        ? 'Transcribing...'
                        : 'Recording: ${_formatDuration(_recordingDuration)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isRefining || _isInitializing || _draft == null || _requestController.text.trim().isEmpty)
                        ? null
                        : () {
                            final request = _requestController.text.trim();
                            if (request.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a refinement request')),
                              );
                              return;
                            }
                            _refineDraft(request);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isRefining || _isInitializing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Refine'),
                  ),
                ),
                if (_isInitializing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Initializing draft...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Conversation history (collapsible)
        if (_draft != null && _draft!.conversationHistory.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            child: ExpansionTile(
              title: Text(
                'Conversation History (${_draft!.conversationHistory.length} messages)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              initiallyExpanded: _showHistory,
              onExpansionChanged: (expanded) {
                setState(() => _showHistory = expanded);
              },
              children: [
                ..._draft!.conversationHistory.map((msg) {
                  final isUser = msg['role'] == 'user';
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              color: isUser ? AppTheme.primaryIndigo : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUser ? 'You' : 'Assistant',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isUser ? AppTheme.primaryIndigo : Colors.grey,
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
      ],
    );
  }
}
