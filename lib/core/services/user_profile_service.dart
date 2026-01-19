import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import 'ai_service.dart';

class UserProfileService {
  static final _client = Supabase.instance.client;

  // Get user profile
  static Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('id, profile_completeness, current_profile_phase, profile_persona, last_question_date, onboarding_completed, total_questions_answered')
          .eq('id', userId)
          .single();
      
      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Check if user needs onboarding
  static Future<bool> needsOnboarding(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile?.onboardingCompleted != true;
    } catch (e) {
      print('Error checking onboarding: $e');
      return true;
    }
  }

  // Check if weekly questions are ready
  static Future<bool> areWeeklyQuestionsReady(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null || !profile.onboardingCompleted) return false;
      
      if (profile.lastQuestionDate == null) return true;
      
      final daysSince = DateTime.now().difference(profile.lastQuestionDate!).inDays;
      return daysSince >= 7;
    } catch (e) {
      print('Error checking weekly questions: $e');
      return false;
    }
  }

  // Get initial questions (9 questions: 3 per phase)
  static Map<String, List<String>> getInitialQuestions() {
    return {
      'basic_info': [
        "What's the story of how you got to where you are today?",
        "What are the three most important things someone should know about your world right now?",
        "How do you usually spend your energy when you aren't 'on the clock'?",
      ],
      'goals': [
        "If everything goes exactly as planned, what does your life look like in three years?",
        "What is the one thing you are most driven to change or build right now?",
        "What does a 'successful' year look like to you personally and professionally?",
      ],
      'communication_style': [
        "How would your closest friends describe your style of connecting with others?",
        "What makes you feel truly heard or understood in a conversation?",
        "What is your philosophy on staying in touch with the people who matter to you?",
      ],
    };
  }

  // Get all answers for a phase
  static Future<List<ProfileAnswer>> getPhaseAnswers(
    String userId,
    String phase,
  ) async {
    try {
      final response = await _client
          .from('user_profile_answers')
          .select()
          .eq('user_id', userId)
          .eq('phase', phase)
          .order('created_at');
      
      return (response as List)
          .map((json) => ProfileAnswer.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting phase answers: $e');
      return [];
    }
  }

  // Generate next question for a phase
  static Future<String> generateNextQuestion(
    String userId,
    String phase,
    List<ProfileAnswer> previousAnswers,
  ) async {
    try {
      // Get user profile for context
      final profile = await getUserProfile(userId);
      
      // Build context from previous answers
      final answered = previousAnswers
          .where((a) => !a.skipped && a.answer != null)
          .toList();
      
      final context = answered
          .map((a) => 'Q: ${a.question}\nA: ${a.answer}')
          .join('\n\n');

      // Determine question progression based on number of answers
      final answerCount = answered.length;
      
      // For basic_info phase, start with open-ended question
      if (phase == 'basic_info') {
        if (answerCount == 0) {
          // First question: open-ended introduction
          return 'Who are you? Tell me a bit about yourself.';
        } else {
          // After the first answer, use AI to analyze what they shared and generate follow-ups
          return await _generatePersonalizedFollowUp(phase, context);
        }
      }
      
      // For other phases, use AI to generate questions based on previous answers
      return await _generatePersonalizedFollowUp(phase, context);
    } catch (e) {
      print('Error generating question: $e');
      // Fallback questions
      final fallbacks = {
        'basic_info': 'Tell me about yourself. What\'s your name?',
        'goals': 'What are you hoping to achieve?',
        'communication_style': 'How do you prefer to communicate?',
        'interests': 'What do you enjoy doing?',
        'work_education': 'Tell me about your background.',
      };
      return fallbacks[phase] ?? 'Tell me more about yourself.';
    }
  }

  // Generate personalized follow-up questions based on user's previous answers
  static Future<String> _generatePersonalizedFollowUp(
    String phase,
    String context,
  ) async {
    final phaseDescriptions = {
      'basic_info': 'basic information about who they are (name, age, student/employment status, background)',
      'goals': 'their goals, aspirations, and what they want to achieve',
      'communication_style': 'how they prefer to communicate and their writing style',
      'interests': 'their hobbies, interests, and what they enjoy doing',
      'work_education': 'their work history, education, and professional background',
    };
    
    final phaseDesc = phaseDescriptions[phase] ?? 'information about them';

    final prompt = '''
You are having a natural conversation with someone to learn about them for a networking app profile.

Phase focus: $phaseDesc

What they've shared so far:
$context

Based on what they've told you, generate ONE natural follow-up question that:
1. Builds on what they just shared (don't repeat what you already know)
2. Goes slightly deeper but gradually (not too deep too fast)
3. Feels like a friendly conversation, not an interview
4. Is specific to what they mentioned
5. Helps you understand them better for the $phaseDesc phase

Examples:
- If they mentioned being a student → ask about their major, year, or what they're studying
- If they mentioned work → ask about their role, how long, or what they enjoy about it
- If they mentioned hobbies → ask about how they got into it or what they like about it
- If they mentioned goals → ask about steps they're taking or challenges they face

Keep it simple, conversational, and natural. Return ONLY the question, nothing else.
''';

    final question = await AIService.generateTextWithFallback(prompt);
    return question.trim();
  }

  // Save answer
  static Future<void> saveAnswer(ProfileAnswer answer) async {
    try {
      await _client.from('user_profile_answers').upsert({
        'id': answer.id,
        'user_id': answer.userId,
        'phase': answer.phase,
        'question': answer.question,
        'answer': answer.answer,
        'answer_type': answer.answerType,
        'skipped': answer.skipped,
        'answer_later': answer.answerLater,
        'question_set': answer.questionSet,
      });
      
      // Update profile completeness and total questions answered
      await _updateProfileCompleteness(answer.userId);
      
      // Update last question date if not skipped
      if (!answer.skipped && answer.answer != null) {
        await _client.from('users').update({
          'last_question_date': DateTime.now().toIso8601String(),
        }).eq('id', answer.userId);
      }
    } catch (e) {
      print('Error saving answer: $e');
      rethrow;
    }
  }

  // Mark onboarding as complete
  static Future<void> markOnboardingComplete(String userId) async {
    try {
      await _client.from('users').update({
        'onboarding_completed': true,
        'last_question_date': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      print('Error marking onboarding complete: $e');
      rethrow;
    }
  }

  // Generate weekly questions (3 questions from any phase)
  static Future<List<Map<String, String>>> generateWeeklyQuestions(String userId) async {
    try {
      // Get all previous answers for context
      final allAnswers = await _client
          .from('user_profile_answers')
          .select()
          .eq('user_id', userId)
          .eq('skipped', false)
          .not('answer', 'is', null)
          .order('created_at');
      
      // Get answer later questions that should be included
      final answerLaterQuestions = await _client
          .from('user_profile_answers')
          .select()
          .eq('user_id', userId)
          .eq('answer_later', true)
          .eq('skipped', false)
          .filter('answer', 'is', null)
          .order('created_at');
      
      // Build context from all answers
      final context = (allAnswers as List)
          .map((a) => 'Q: ${a['question']}\nA: ${a['answer']}')
          .join('\n\n');
      
      // Get profile for additional context
      final profile = await getUserProfile(userId);
      
      // Generate 3 questions using AI
      final questionSet = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final questions = await _generateWeeklyQuestionsAI(
        context,
        profile?.persona ?? {},
        answerLaterQuestions.length,
      );
      
      // Format questions with phases
      final phases = ['basic_info', 'goals', 'communication_style'];
      final result = <Map<String, String>>[];
      
      for (int i = 0; i < questions.length && i < 3; i++) {
        // Determine which phase this question belongs to (can span phases)
        final phase = phases[i % phases.length];
        result.add({
          'phase': phase,
          'question': questions[i],
          'question_set': 'weekly_$questionSet',
        });
      }
      
      // Add answer later questions to the set
      for (final q in answerLaterQuestions) {
        result.add({
          'phase': q['phase'] as String,
          'question': q['question'] as String,
          'question_set': 'weekly_$questionSet',
        });
      }
      
      return result;
    } catch (e) {
      print('Error generating weekly questions: $e');
      // Fallback to basic questions
      return [
        {'phase': 'basic_info', 'question': 'Tell me more about yourself.', 'question_set': 'weekly_${DateTime.now().toIso8601String().split('T')[0]}'},
        {'phase': 'goals', 'question': 'What are you working towards?', 'question_set': 'weekly_${DateTime.now().toIso8601String().split('T')[0]}'},
        {'phase': 'communication_style', 'question': 'How do you prefer to communicate?', 'question_set': 'weekly_${DateTime.now().toIso8601String().split('T')[0]}'},
      ];
    }
  }

  // Generate weekly questions using AI
  static Future<List<String>> _generateWeeklyQuestionsAI(
    String context,
    Map<String, dynamic> persona,
    int answerLaterCount,
  ) async {
    final prompt = '''
You are generating personalized questions for a user profile building system. The app learns about users through weekly questions to provide better advice.

User's previous answers:
$context

User persona summary:
${persona.toString()}

Generate 3 open-ended questions that:
1. Are short and open to interpretation (encourage long responses)
2. Are designed to get maximum information about the user
3. Can span different phases (Basic Info, Goals, Communication) based on what you need to learn
4. Build on what they've already shared but go deeper
5. Are conversational and natural, not interview-like

${answerLaterCount > 0 ? 'Note: The user has $answerLaterCount question(s) they marked "answer later" that will also be included this week.' : ''}

Return ONLY the 3 questions, one per line, nothing else. No numbering, no prefixes.
''';

    final response = await AIService.generateTextWithFallback(prompt);
    final questions = response
        .split('\n')
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .take(3)
        .toList();
    
    // Ensure we have 3 questions
    while (questions.length < 3) {
      questions.add('Tell me more about yourself.');
    }
    
    return questions;
  }

  // Get next question for current phase (for weekly system)
  static Future<Map<String, String>?> getNextQuestionForPhase(
    String userId,
    String phase,
  ) async {
    try {
      // Check if we need weekly questions
      final needsWeekly = await areWeeklyQuestionsReady(userId);
      if (needsWeekly) {
        // Generate weekly questions
        final weeklyQuestions = await generateWeeklyQuestions(userId);
        // Save them to database
        for (final q in weeklyQuestions) {
          // Check if question already exists
          final existing = await _client
              .from('user_profile_answers')
              .select()
              .eq('user_id', userId)
              .eq('question', q['question']!)
              .eq('question_set', q['question_set']!)
              .maybeSingle();
          
          if (existing == null) {
            await _client.from('user_profile_answers').insert({
              'user_id': userId,
              'phase': q['phase']!,
              'question': q['question']!,
              'question_set': q['question_set']!,
              'skipped': false,
            });
          }
        }
      }
      
      // Get unanswered questions for this phase
      final unanswered = await _client
          .from('user_profile_answers')
          .select()
          .eq('user_id', userId)
          .eq('phase', phase)
          .eq('skipped', false)
          .filter('answer', 'is', null)
          .order('created_at')
          .limit(1)
          .maybeSingle();
      
      if (unanswered != null) {
        return {
          'id': unanswered['id'] as String,
          'phase': unanswered['phase'] as String,
          'question': unanswered['question'] as String,
          'question_set': unanswered['question_set'] as String? ?? 'initial',
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting next question: $e');
      return null;
    }
  }

  // Update profile completeness and total questions answered
  static Future<void> _updateProfileCompleteness(String userId) async {
    try {
      // Get all answers
      final allAnswers = await _client
          .from('user_profile_answers')
          .select()
          .eq('user_id', userId);
      
      // Count total answered (not skipped, has answer)
      final totalAnswered = (allAnswers as List)
          .where((a) => a['skipped'] == false && a['answer'] != null)
          .length;
      
      // Calculate overall progress (out of 9 for initial, then ongoing)
      final initialAnswers = (allAnswers as List)
          .where((a) => a['question_set'] == 'initial' && a['skipped'] == false && a['answer'] != null)
          .length;
      
      // Update user record
      await _client.from('users').update({
        'total_questions_answered': totalAnswered,
      }).eq('id', userId);
    } catch (e) {
      print('Error updating profile completeness: $e');
    }
  }

  // Get overall progress (e.g., 6/9)
  static Future<Map<String, int>> getOverallProgress(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return {'answered': 0, 'total': 9};
      
      // For initial onboarding: 9 questions total
      if (!profile.onboardingCompleted) {
        final initialAnswersResponse = await _client
            .from('user_profile_answers')
            .select()
            .eq('user_id', userId)
            .eq('question_set', 'initial')
            .eq('skipped', false)
            .not('answer', 'is', null);
        
        final initialAnswers = (initialAnswersResponse as List).length;
        
        return {
          'answered': initialAnswers,
          'total': 9,
        };
      }
      
      // For weekly questions: check if questions are available for this week
      final currentWeekSet = 'weekly_${DateTime.now().toIso8601String().split('T')[0]}';
      
      // Check if weekly questions exist for this week
      final weeklyQuestionsResponse = await _client
          .from('user_profile_answers')
          .select()
          .eq('user_id', userId)
          .eq('question_set', currentWeekSet);
      
      final weeklyQuestions = (weeklyQuestionsResponse as List);
      
      // If no weekly questions exist yet, check if they should be generated
      if (weeklyQuestions.isEmpty) {
        final needsWeekly = await areWeeklyQuestionsReady(userId);
        if (!needsWeekly) {
          // No questions needed yet, show 100% (all done)
          return {
            'answered': 3,
            'total': 3, // 100% complete
          };
        } else {
          // Questions should be generated but haven't been yet
          return {
            'answered': 0,
            'total': 3, // Questions will be generated
          };
        }
      }
      
      // Count answered questions for current week
      final weeklyAnswersResponse = await _client
          .from('user_profile_answers')
          .select()
          .eq('user_id', userId)
          .eq('question_set', currentWeekSet)
          .eq('skipped', false)
          .not('answer', 'is', null);
      
      final weeklyAnswers = (weeklyAnswersResponse as List).length;
      
      return {
        'answered': weeklyAnswers,
        'total': weeklyQuestions.length, // Use actual number of weekly questions
      };
    } catch (e) {
      print('Error getting overall progress: $e');
      return {'answered': 0, 'total': 9};
    }
  }

  // Generate/update persona summary
  static Future<void> updatePersona(String userId) async {
    try {
      final answers = await _client
          .from('user_profile_answers')
          .select()
          .eq('user_id', userId)
          .eq('skipped', false)
          .not('answer', 'is', null)
          .order('created_at');

      if (answers.isEmpty) return;

      final context = (answers as List)
          .map((a) => 'Q: ${a['question']}\nA: ${a['answer']}')
          .join('\n\n');

      final prompt = '''
Based on the following profile answers, create a concise persona summary of this user. Include:
- Communication style and preferences
- Personality traits
- Interests and hobbies
- Goals and aspirations
- Professional background
- What they value in relationships

Profile answers:
$context

Return a JSON object with keys: communication_style, personality, interests, goals, background, values.
Keep each value to 1-2 sentences.
''';

      final personaText = await AIService.generateTextWithFallback(prompt);
      
      // Try to parse as JSON, fallback to text
      Map<String, dynamic> persona;
      try {
        persona = Map<String, dynamic>.from(
          _parseJsonFromText(personaText),
        );
      } catch (_) {
        persona = {'summary': personaText};
      }

      await _client.from('users').update({
        'profile_persona': persona,
      }).eq('id', userId);
    } catch (e) {
      print('Error updating persona: $e');
    }
  }

  // Get all phases with their status
  static Future<Map<String, Map<String, dynamic>>> getPhasesStatus(
    String userId,
  ) async {
    final profile = await getUserProfile(userId);
    final phases = [
      'basic_info',
      'goals',
      'communication_style',
      'interests',
      'work_education',
    ];

    final status = <String, Map<String, dynamic>>{};
    for (final phase in phases) {
      final answers = await getPhaseAnswers(userId, phase);
      final answered = answers.where((a) => !a.skipped && a.answer != null).length;
      
      status[phase] = {
        'completeness': profile?.profileCompleteness[phase] ?? 0,
        'questions_answered': answered,
        'total_questions': answers.length,
      };
    }
    return status;
  }
}

// Helper function for JSON parsing
dynamic _parseJsonFromText(String text) {
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
  
  // Try to parse as JSON
  try {
    return jsonDecode(cleaned);
  } catch (_) {
    // Fallback to text summary
    return {'summary': cleaned};
  }
}
