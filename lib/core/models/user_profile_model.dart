class UserProfile {
  final String userId;
  final Map<String, int> profileCompleteness; // phase -> percentage (0-100)
  final String currentPhase;
  final Map<String, dynamic> persona; // AI-generated persona summary
  final DateTime? lastQuestionDate;
  final bool onboardingCompleted;
  final int totalQuestionsAnswered;

  UserProfile({
    required this.userId,
    required this.profileCompleteness,
    required this.currentPhase,
    required this.persona,
    this.lastQuestionDate,
    this.onboardingCompleted = false,
    this.totalQuestionsAnswered = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['id'] as String,
      profileCompleteness: Map<String, int>.from(
        json['profile_completeness'] as Map? ?? {},
      ),
      currentPhase: json['current_profile_phase'] as String? ?? 'basic_info',
      persona: Map<String, dynamic>.from(
        json['profile_persona'] as Map? ?? {},
      ),
      lastQuestionDate: json['last_question_date'] != null
          ? DateTime.parse(json['last_question_date'])
          : null,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      totalQuestionsAnswered: json['total_questions_answered'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'profile_completeness': profileCompleteness,
      'current_profile_phase': currentPhase,
      'profile_persona': persona,
    };
  }

  int get overallCompleteness {
    if (profileCompleteness.isEmpty) return 0;
    final total = profileCompleteness.values.reduce((a, b) => a + b);
    return (total / profileCompleteness.length).round();
  }
}

class ProfileAnswer {
  final String id;
  final String userId;
  final String phase;
  final String question;
  final String? answer;
  final String? answerType; // 'text' or 'voice'
  final bool skipped;
  final bool answerLater; // If true, question will reappear next week
  final String questionSet; // 'initial' or 'weekly_YYYY-MM-DD'
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileAnswer({
    required this.id,
    required this.userId,
    required this.phase,
    required this.question,
    this.answer,
    this.answerType,
    required this.skipped,
    this.answerLater = false,
    this.questionSet = 'initial',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileAnswer.fromJson(Map<String, dynamic> json) {
    return ProfileAnswer(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      phase: json['phase'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String?,
      answerType: json['answer_type'] as String?,
      skipped: json['skipped'] as bool? ?? false,
      answerLater: json['answer_later'] as bool? ?? false,
      questionSet: json['question_set'] as String? ?? 'initial',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'phase': phase,
      'question': question,
      'answer': answer,
      'answer_type': answerType,
      'skipped': skipped,
      'answer_later': answerLater,
      'question_set': questionSet,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class DraftConversation {
  final String id;
  final String userId;
  final String? contactId;
  final String context; // 'email', 'linkedin', 'text', 'pre_meeting', 'search'
  final String initialDraft;
  final String currentDraft;
  final List<Map<String, dynamic>> conversationHistory;
  final String? topicName; // Auto-generated topic name
  final bool completed; // Whether conversation is completed
  final DateTime createdAt;
  final DateTime updatedAt;

  DraftConversation({
    required this.id,
    required this.userId,
    this.contactId,
    required this.context,
    required this.initialDraft,
    required this.currentDraft,
    required this.conversationHistory,
    this.topicName,
    this.completed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DraftConversation.fromJson(Map<String, dynamic> json) {
    return DraftConversation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contactId: json['contact_id'] as String?,
      context: json['context'] as String,
      initialDraft: json['initial_draft'] as String,
      currentDraft: json['current_draft'] as String,
      conversationHistory: List<Map<String, dynamic>>.from(
        json['conversation_history'] as List? ?? [],
      ),
      topicName: json['topic_name'] as String?,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'contact_id': contactId,
      'context': context,
      'initial_draft': initialDraft,
      'current_draft': currentDraft,
      'conversation_history': conversationHistory,
      'topic_name': topicName,
      'completed': completed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
