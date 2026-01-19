import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class AIService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY']!;
  static const List<String> _fallbackModels = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-pro',
    'gemini-1.5-flash-latest',
    'gemini-1.5-pro-latest',
  ];
  static late String _activeModelName;

  static void initialize() {
    _activeModelName = dotenv.env['GEMINI_MODEL'] ?? _fallbackModels.first;
  }

  static String _normalizeModelName(String modelName) {
    if (modelName.startsWith('models/')) {
      return modelName.substring('models/'.length);
    }
    return modelName;
  }

  static GenerativeModel _modelFor(String modelName) {
    return GenerativeModel(
      model: _normalizeModelName(modelName),
      apiKey: _apiKey,
    );
  }

  static Future<String?> _discoverGenerateContentModel() async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey'),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final models = data['models'] as List<dynamic>? ?? [];
      for (final model in models) {
        final modelMap = model as Map<String, dynamic>;
        final methods = modelMap['supportedGenerationMethods'] as List<dynamic>? ?? [];
        if (methods.contains('generateContent')) {
          final name = modelMap['name'] as String?;
          if (name != null && name.isNotEmpty) {
            return name;
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  // Public method for generating text (used by other services)
  static Future<String> generateTextWithFallback(String prompt) async {
    return await _generateTextWithFallback(prompt);
  }

  static Future<String> _generateTextWithFallback(String prompt) async {
    final triedModels = <String>{};
    final candidates = <String>[
      _activeModelName,
      ..._fallbackModels,
    ];
    String? lastError;

    for (final modelName in candidates) {
      if (!triedModels.add(modelName)) {
        continue;
      }
      try {
        final model = _modelFor(modelName);
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text != null && text.trim().isNotEmpty) {
          _activeModelName = modelName;
          return text;
        }
      } catch (_) {
        lastError = _.toString();
        // Try next model
      }
    }

    final discoveredModel = await _discoverGenerateContentModel();
    if (discoveredModel != null && triedModels.add(discoveredModel)) {
      try {
        final model = _modelFor(discoveredModel);
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text != null && text.trim().isNotEmpty) {
          _activeModelName = discoveredModel;
          return text;
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    if (lastError != null) {
      final normalized = lastError.toLowerCase();
      if (normalized.contains('permission') ||
          normalized.contains('api key') ||
          normalized.contains('unauth') ||
          normalized.contains('403')) {
        throw Exception(
          'Gemini API permission error. Please verify:\n'
          '1) Gemini API is enabled\n'
          '2) Billing is enabled for the project\n'
          '3) Your API key is from the same project and not restricted\n'
          'Last error: $lastError',
        );
      }
    }

    throw Exception(
      'No available Gemini models found. Please check your API key '
      'permissions in Google Cloud Console.\n'
      'Last error: ${lastError ?? 'unknown'}',
    );
  }

  // Extract structured data from voice transcription
  static Future<Map<String, dynamic>> extractContactInfo(String transcription) async {
    final prompt = '''
Extract the following information from this networking conversation:
- Name
- Company
- Job Title
- Personal Facts (hobbies, interests, etc.)
- Action Items (with dates if mentioned)

Text: "$transcription"

Return a JSON object with keys: name, company, jobTitle, personalFacts (array), actionItems (array of objects with text and date).
''';

    try {
      final text = await _generateTextWithFallback(prompt);
      
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!);
      }
      return jsonDecode(text);
    } catch (e) {
      throw Exception('Failed to extract contact info: $e');
    }
  }

  // Transcribe audio using Google Speech-to-Text API
  // Note: Gemini API key can be used for Speech-to-Text if it's a Google Cloud API key
  // Otherwise, you'll need a separate SPEECH_TO_TEXT_API_KEY
  static Future<String> transcribeAudio(File audioFile) async {
    // Try using Speech-to-Text API key if available, otherwise use Gemini key
    final speechApiKey = dotenv.env['SPEECH_TO_TEXT_API_KEY'] ?? _apiKey;
    final fileName = audioFile.path.toLowerCase();
    String encoding = 'ENCODING_UNSPECIFIED';
    if (fileName.endsWith('.wav')) {
      encoding = 'LINEAR16';
    } else if (fileName.endsWith('.mp3')) {
      encoding = 'MP3';
    } else if (fileName.endsWith('.flac')) {
      encoding = 'FLAC';
    }
    
    try {
      final audioBytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      final response = await http.post(
        Uri.parse('https://speech.googleapis.com/v1/speech:recognize?key=$speechApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'config': {
            'encoding': encoding, // Match actual file encoding
            'sampleRateHertz': encoding == 'LINEAR16' ? 16000 : 44100,
            'languageCode': 'en-US',
            'enableAutomaticPunctuation': true,
          },
          'audio': {
            'content': base64Audio,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['alternatives'][0]['transcript'] as String;
        }
        throw Exception('No transcription found in response: ${response.body}');
      } else {
        // If API key doesn't work, provide helpful error
        if (response.statusCode == 403) {
          throw Exception('Speech-to-Text API access denied. Please ensure:\n'
              '1. Google Speech-to-Text API is enabled in Google Cloud Console\n'
              '2. Your API key has Speech-to-Text permissions\n'
              '3. Or set SPEECH_TO_TEXT_API_KEY in .env with a valid key');
        }
        throw Exception('Failed to transcribe audio: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('Speech-to-Text')) {
        rethrow;
      }
      
      // Check if error is about audio being too long
      if (e.toString().contains('too long') || e.toString().contains('Sync input too long')) {
        throw Exception(
          'Audio recording is too long (over 3 minutes).\n\n'
          'Please keep your recordings under 3 minutes for best results.\n'
          'You can record multiple shorter segments if needed.',
        );
      }
      
      throw Exception('Audio transcription failed: $e\n\n'
          'Note: You may need to enable Google Speech-to-Text API in Google Cloud Console\n'
          'and ensure your API key has the necessary permissions.');
    }
  }

  // Generate follow-up email
  static Future<String> generateFollowUpEmail(
    String contactName,
    String lastInteraction,
    List<String> personalFacts,
  ) async {
    final facts = personalFacts.where((fact) => fact.trim().isNotEmpty).toList();
    final factsText = facts.isEmpty ? 'None provided' : facts.join(', ');
    final prompt = '''
Write a warm, concise follow-up email to $contactName based on the details below.

Last interaction: $lastInteraction
Personal facts to reference (use at most one if relevant): $factsText

Rules:
- Do NOT use placeholders like [Your Name], [Company], [Role], or [Project].
- If a detail is missing, gracefully omit it instead of inventing facts.
- Include a clear subject line.
- Keep it 1-2 short paragraphs plus a sign-off.
''';

    try {
      final text = await _generateTextWithFallback(prompt);
      return text;
    } catch (e) {
      throw Exception('Failed to generate email: $e');
    }
  }

  static Future<String> generateMessage({
    required String contactName,
    required String messageType,
    String? userPrompt,
    String? firstInteractionContext,
    String? relationshipNature,
    String? relationshipGoal,
    String? personalDetails,
    String? lastInteraction,
  }) async {
    final prompt = '''
Write a ${messageType.toLowerCase()} message for $contactName.

Details:
- First interaction context: ${firstInteractionContext ?? 'Unknown'}
- Relationship nature: ${relationshipNature ?? 'Unknown'}
- Relationship goal: ${relationshipGoal ?? 'Unknown'}
- Personal details: ${personalDetails ?? 'None provided'}
- Last interaction: ${lastInteraction ?? 'None'}
- User prompt: ${userPrompt ?? 'None'}

Rules:
- Do NOT use placeholders like [Your Name], [Company], or [Role].
- If a detail is missing, omit it instead of inventing facts.
- If this is an email, include a clear subject line.
- Keep it concise and warm.
''';

    try {
      return await _generateTextWithFallback(prompt);
    } catch (e) {
      throw Exception('Failed to generate message: $e');
    }
  }

  // Generate pre-meeting brief
  static Future<String> generatePreMeetingBrief(
    String contactName,
    List<Map<String, dynamic>> notes,
    String? lastContactDate,
  ) async {
    final notesSummary = notes.map((n) => n['content']).join('\n');
    
    final prompt = '''
Generate a 3-bullet point brief for meeting with $contactName.

Last contacted: ${lastContactDate ?? 'Never'}
Notes: $notesSummary

Format as 3 concise bullet points:
- Last interaction summary
- Key personal fact to remember
- Suggested conversation starter
''';

    try {
      final text = await _generateTextWithFallback(prompt);
      return text;
    } catch (e) {
      throw Exception('Failed to generate brief: $e');
    }
  }

  static Future<String> generatePreMeetingAnswer({
    required String contactName,
    required List<Map<String, dynamic>> notes,
    required String question,
  }) async {
    final notesSummary = notes.map((n) => n['content']).join('\n');
    final prompt = '''
You are preparing for a meeting with $contactName.

Notes: $notesSummary
Question/Goal: "$question"

Provide a concise response with actionable talking points. If notes are missing, say what you'd ask to fill gaps.
''';

    try {
      return await _generateTextWithFallback(prompt);
    } catch (e) {
      throw Exception('Failed to generate pre-meeting response: $e');
    }
  }

  static Future<String> generateConnectionSuggestions(
    String prompt,
    List<Map<String, dynamic>> contacts,
  ) async {
    final contactSummaries = contacts.map((contact) {
      final name = contact['name']?.toString() ?? 'Unknown';
      final company = contact['company']?.toString() ?? 'Unknown';
      final title = contact['job_title']?.toString() ?? 'Unknown';
      final relationship = contact['relationship_nature']?.toString();
      return '- $name | $company | $title${relationship != null && relationship.isNotEmpty ? ' | $relationship' : ''}';
    }).join('\n');

    final aiPrompt = '''
Given the user's need: "$prompt"
Suggest which contacts they should reach out to and why.

Contacts:
$contactSummaries

Return 3-5 suggestions, each with a short reason. If no match is obvious, ask 1-2 clarifying questions.
''';

    try {
      return await _generateTextWithFallback(aiPrompt);
    } catch (e) {
      throw Exception('Failed to generate suggestions: $e');
    }
  }

  // Generate avatar prompt using Gemini
  static Future<String> generateAvatarPrompt({
    required String contactName,
    String? jobTitle,
    String? company,
    String? role,
    String? skinTone,
    String? outfit,
    String? accessory,
  }) async {
    final prompt = '''
Generate a detailed, professional prompt for creating a full-body avatar image of a person named $contactName.

Details:
- Job/Role: ${role ?? jobTitle ?? 'Professional'}
- Company: ${company ?? 'Not specified'}
- Skin tone: ${skinTone ?? 'Medium'}
- Outfit: ${outfit ?? 'Professional attire'}
- Accessory: ${accessory ?? 'None'}

Create a prompt that describes:
1. A friendly, professional full-body character
2. Appropriate clothing for their role (${outfit ?? 'professional attire'})
3. ${accessory != null && accessory != 'None' ? 'Holding or wearing: $accessory' : 'No accessories'}
4. ${skinTone ?? 'Medium'} skin tone
5. Bitmoji-style, colorful, fun but professional
6. Standing pose, facing forward
7. Clean white or light background

Return ONLY the image generation prompt, nothing else. Make it detailed and specific for best results.
''';

    try {
      final text = await _generateTextWithFallback(prompt);
      // Clean up the response to get just the prompt
      return text.trim();
    } catch (e) {
      // Fallback prompt if Gemini fails
      return 'A friendly professional full-body avatar of $contactName, ${skinTone ?? 'medium'} skin tone, wearing ${outfit ?? 'professional attire'}${accessory != null && accessory != 'None' ? ', with $accessory' : ''}, Bitmoji-style, colorful and fun but professional, standing pose, white background';
    }
  }

  // Classify OCR text
  static Future<Map<String, dynamic>> classifyOCRText(String rawText) async {
    final prompt = '''
Classify this text from a business card or note:
"$rawText"

Extract:
- Name
- Email (if contains @ and .com)
- Phone (if looks like phone number)
- Company
- Job Title
- Any dates (set as deadline if found)

Return JSON with keys: name, email, phone, company, jobTitle, deadline.
''';

    try {
      final text = await _generateTextWithFallback(prompt);
      
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!);
      }
      return jsonDecode(text);
    } catch (e) {
      throw Exception('Failed to classify text: $e');
    }
  }
}
