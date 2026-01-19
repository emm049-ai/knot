import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile_model.dart';
import 'ai_service.dart';
import 'user_profile_service.dart';

class DraftConversationService {
  static final _client = Supabase.instance.client;

  // Generate topic name from context
  static String _generateTopicName(String context, String? contactName) {
    final contextNames = {
      'email': 'Email',
      'linkedin': 'LinkedIn',
      'text': 'Text message',
      'pre_meeting': 'Pre-meeting',
      'search': 'Search',
    };
    final contextName = contextNames[context] ?? context;
    if (contactName != null) {
      return '$contextName to $contactName';
    }
    return contextName;
  }

  // Create or get existing draft conversation
  static Future<DraftConversation> getOrCreateDraft({
    required String userId,
    String? contactId,
    required String context, // 'email', 'linkedin', 'text', 'pre_meeting', 'search'
    required String initialDraft,
    String? topicName,
  }) async {
    try {
      // Generate topic name if not provided
      String? contactName;
      if (contactId != null) {
        final contact = await _client
            .from('contacts')
            .select('name')
            .eq('id', contactId)
            .single();
        contactName = contact['name'] as String?;
      }
      final finalTopicName = topicName ?? _generateTopicName(context, contactName);

      // Check if draft exists with same topic
      final query = _client
          .from('draft_conversations')
          .select()
          .eq('user_id', userId)
          .eq('context', context);
      
      List<Map<String, dynamic>> existing;
      if (contactId != null) {
        existing = await query
            .eq('contact_id', contactId)
            .order('updated_at', ascending: false)
            .limit(1);
      } else {
        existing = await query
            .order('updated_at', ascending: false)
            .limit(1);
        // Filter for null contact_id in the results
        existing = existing.where((item) => item['contact_id'] == null).toList();
      }

      if (existing.isNotEmpty) {
        final draft = DraftConversation.fromJson(existing.first);
        // Update topic name if it changed
        if (draft.topicName != finalTopicName) {
          await _client.from('draft_conversations').update({
            'topic_name': finalTopicName,
          }).eq('id', draft.id);
        }
        return DraftConversation.fromJson({
          ...existing.first,
          'topic_name': finalTopicName,
        });
      }

      // Create new draft
      final draft = DraftConversation(
        id: const Uuid().v4(),
        userId: userId,
        contactId: contactId,
        context: context,
        initialDraft: initialDraft,
        currentDraft: initialDraft,
        conversationHistory: [],
        topicName: finalTopicName,
        completed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final draftJson = draft.toJson();
      await _client.from('draft_conversations').insert(draftJson);
      return draft;
    } catch (e) {
      print('Error getting/creating draft: $e');
      rethrow;
    }
  }

  // Get conversation history for a contact (25 most recent)
  static Future<List<DraftConversation>> getConversationHistory({
    required String userId,
    required String contactId,
    int limit = 25,
  }) async {
    try {
      final response = await _client
          .from('draft_conversations')
          .select()
          .eq('user_id', userId)
          .eq('contact_id', contactId)
          .order('updated_at', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((json) => DraftConversation.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting conversation history: $e');
      return [];
    }
  }

  // Mark conversation as completed
  static Future<void> completeConversation(String draftId) async {
    try {
      await _client.from('draft_conversations').update({
        'completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', draftId);
    } catch (e) {
      print('Error completing conversation: $e');
    }
  }

  // Refine draft based on user request
  static Future<String> refineDraft({
    required String userId,
    required DraftConversation draft,
    required String userRequest,
    bool isVoiceInput = false,
  }) async {
    try {
      // Get user profile for context
      final profile = await UserProfileService.getUserProfile(userId);
      final personaContext = profile?.persona ?? {};

      // Build conversation context
      final conversationContext = draft.conversationHistory
          .map((msg) => '${msg['role']}: ${msg['content']}')
          .join('\n');

      final prompt = '''
You are helping refine a ${draft.context} draft. The user wants to make changes.

Current draft:
${draft.currentDraft}

User's request:
$userRequest

${personaContext.isNotEmpty ? 'User preferences (from their profile):\n${personaContext.toString()}\n' : ''}

${conversationContext.isNotEmpty ? 'Previous conversation:\n$conversationContext\n' : ''}

Refine the draft according to the user's request. Return:
1. The refined draft (with changes made)
2. A brief summary of what you changed (for highlighting)

Format your response as JSON:
{
  "refined_draft": "...",
  "changes_summary": ["Changed: made tone more casual", "Added: mention of project deadline"]
}
''';

      final response = await AIService.generateTextWithFallback(prompt);
      
      // Parse response
      Map<String, dynamic> parsed;
      try {
        parsed = _parseJsonResponse(response);
      } catch (_) {
        // Fallback if JSON parsing fails
        parsed = {
          'refined_draft': response,
          'changes_summary': ['Updated based on your request'],
        };
      }

      final refinedDraft = parsed['refined_draft'] as String? ?? response;
      final changesSummary = (parsed['changes_summary'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Updated based on your request'];

      // Update draft
      final updatedHistory = List<Map<String, dynamic>>.from(draft.conversationHistory);
      updatedHistory.add({
        'role': 'user',
        'content': userRequest,
        'input_type': isVoiceInput ? 'voice' : 'text',
        'timestamp': DateTime.now().toIso8601String(),
      });
      updatedHistory.add({
        'role': 'assistant',
        'content': refinedDraft,
        'changes': changesSummary,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _client.from('draft_conversations').update({
        'current_draft': refinedDraft,
        'conversation_history': updatedHistory,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', draft.id);

      return refinedDraft;
    } catch (e) {
      print('Error refining draft: $e');
      rethrow;
    }
  }

  // Get changes between two drafts (for highlighting)
  static List<String> getChangedSections(String oldDraft, String newDraft) {
    // Simple word-level diff (can be enhanced)
    final oldWords = oldDraft.split(RegExp(r'\s+'));
    final newWords = newDraft.split(RegExp(r'\s+'));

    final changed = <String>[];
    int i = 0, j = 0;
    while (i < oldWords.length && j < newWords.length) {
      if (oldWords[i] != newWords[j]) {
        // Find the changed section
        final start = j;
        while (j < newWords.length && 
               (i >= oldWords.length || oldWords[i] != newWords[j])) {
          j++;
        }
        if (j > start) {
          changed.add(newWords.sublist(start, j).join(' '));
        }
        i++;
      } else {
        i++;
        j++;
      }
    }
    if (j < newWords.length) {
      changed.add(newWords.sublist(j).join(' '));
    }
    return changed;
  }

  // Save user preference (like/dislike)
  static Future<void> savePreference({
    required String userId,
    required String itemType, // 'draft', 'suggestion', 'advice'
    String? itemId,
    required String preference, // 'like' or 'dislike'
    String? context,
  }) async {
    try {
      await _client.from('user_preferences').insert({
        'user_id': userId,
        'item_type': itemType,
        'item_id': itemId,
        'preference': preference,
        'context': context,
      });
    } catch (e) {
      print('Error saving preference: $e');
    }
  }

  static Map<String, dynamic> _parseJsonResponse(String text) {
    // Remove markdown code blocks
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    // Try to extract JSON object
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(cleaned);
    if (jsonMatch != null) {
      return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    }
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }
}
