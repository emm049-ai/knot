import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/widgets/knot_app_bar.dart';
import '../../../../core/services/user_profile_service.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_profile_model.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final List<String> _phases = ['basic_info', 'goals', 'communication_style'];
  int _currentPhaseIndex = 0;
  int _currentQuestionIndex = 0;
  String? _currentAnswer;
  bool _isSaving = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  File? _recordingFile;
  final TextEditingController _answerController = TextEditingController();
  Map<String, List<String>> _initialQuestions = {};
  Map<String, int> _phaseProgress = {}; // phase -> questions answered

  @override
  void initState() {
    super.initState();
    _initialQuestions = UserProfileService.getInitialQuestions();
    _phaseProgress = {
      'basic_info': 0,
      'goals': 0,
      'communication_style': 0,
    };
  }

  @override
  void dispose() {
    _answerController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  String _getCurrentQuestion() {
    final phase = _phases[_currentPhaseIndex];
    final questions = _initialQuestions[phase] ?? [];
    if (_currentQuestionIndex < questions.length) {
      return questions[_currentQuestionIndex];
    }
    return '';
  }

  String _getPhaseName(String phase) {
    const names = {
      'basic_info': 'Basic Info',
      'goals': 'Goals',
      'communication_style': 'Communication',
    };
    return names[phase] ?? phase;
  }

  int _getTotalAnswered() {
    return _phaseProgress.values.reduce((a, b) => a + b);
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
        if (mounted) {
          final editedText = await _showTranscriptionDialog(transcription);
          if (editedText != null) {
            setState(() {
              _currentAnswer = editedText;
              _answerController.text = editedText;
            });
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
          maxLines: 5,
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
        
        // Auto-stop at 2 minutes 50 seconds to avoid 3-minute limit
        if (_recordingDuration.inSeconds >= 170) {
          _stopRecording();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recording stopped at 2 minutes 50 seconds to ensure transcription works.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveAnswer({bool skipped = false, bool answerLater = false}) async {
    setState(() => _isSaving = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return;

      final phase = _phases[_currentPhaseIndex];
      final question = _getCurrentQuestion();
      
      final answer = ProfileAnswer(
        id: const Uuid().v4(),
        userId: user.id,
        phase: phase,
        question: question,
        answer: skipped || answerLater ? null : (_answerController.text.trim().isEmpty 
            ? _currentAnswer 
            : _answerController.text.trim()),
        answerType: skipped || answerLater ? null : (_isRecording || _recordingFile != null ? 'voice' : 'text'),
        skipped: skipped,
        answerLater: answerLater,
        questionSet: 'initial',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await UserProfileService.saveAnswer(answer);
      
      if (!skipped && !answerLater && answer.answer != null) {
        _phaseProgress[phase] = (_phaseProgress[phase] ?? 0) + 1;
      }

      _answerController.clear();
      _currentAnswer = null;
      _recordingFile = null;

      // Move to next question
      await _moveToNextQuestion();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving answer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _moveToNextQuestion() async {
    final phase = _phases[_currentPhaseIndex];
    final questions = _initialQuestions[phase] ?? [];
    
    // Move to next question in current phase
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      return;
    }
    
    // Move to next phase
    if (_currentPhaseIndex < _phases.length - 1) {
      setState(() {
        _currentPhaseIndex++;
        _currentQuestionIndex = 0;
      });
      return;
    }
    
    // All questions completed - mark onboarding as complete
    final user = await SupabaseService.getCurrentUser();
    if (user != null) {
      await UserProfileService.markOnboardingComplete(user.id);
    }
    
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _skipOnboarding() async {
    final user = await SupabaseService.getCurrentUser();
    if (user != null) {
      await UserProfileService.markOnboardingComplete(user.id);
    }
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhase = _phases[_currentPhaseIndex];
    final totalAnswered = _getTotalAnswered();
    final totalQuestions = 9;

    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Welcome to Knot',
        extraActions: [
          TextButton(
            onPressed: _isSaving ? null : _skipOnboarding,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryIndigo.withOpacity(0.1),
              AppTheme.accentTeal.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: $totalAnswered/$totalQuestions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${((totalAnswered / totalQuestions) * 100).round()}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryIndigo,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: totalAnswered / totalQuestions,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryIndigo),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These questions help us give you better advice',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            // Phase indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              color: Colors.white.withOpacity(0.5),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _phases.asMap().entries.map((entry) {
                    final index = entry.key;
                    final phase = entry.value;
                    final isActive = phase == currentPhase;
                    final isCompleted = index < _currentPhaseIndex;
                    
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? AppTheme.primaryIndigo.withOpacity(0.1)
                                : isCompleted
                                    ? AppTheme.growthGreen.withOpacity(0.1)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive 
                                  ? AppTheme.primaryIndigo
                                  : isCompleted
                                      ? AppTheme.growthGreen
                                      : Colors.grey.shade300,
                              width: isActive || isCompleted ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            _getPhaseName(phase),
                            style: TextStyle(
                              color: isActive 
                                  ? AppTheme.primaryIndigo
                                  : isCompleted
                                      ? AppTheme.growthGreen
                                      : Colors.grey,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            softWrap: false,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        if (index < _phases.length - 1)
                          Container(
                            width: 20,
                            height: 2,
                            color: isCompleted 
                                ? AppTheme.growthGreen 
                                : Colors.grey.shade300,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            // Question and answer area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current question
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPhaseName(currentPhase),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primaryIndigo,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getCurrentQuestion(),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Answer input
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _answerController,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Your Answer',
                                hintText: 'Type your answer here...',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() => _currentAnswer = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            // Voice recording button
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isRecording
                                            ? _stopRecording
                                            : (_isTranscribing ? null : _startRecording),
                                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                                        label: Text(_isRecording 
                                            ? 'Stop Recording' 
                                            : 'Record Answer'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isRecording 
                                              ? AppTheme.alertCoral 
                                              : AppTheme.accentTeal,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (_isRecording || _isTranscribing) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        _isTranscribing 
                                            ? 'Transcribing...' 
                                            : 'Recording: ${_formatDuration(_recordingDuration)}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Note: Recording limit is 2 minutes 50 seconds',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Action buttons
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isSaving
                                            ? null
                                            : () => _saveAnswer(answerLater: true),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text(
                                          'Answer Later',
                                          style: TextStyle(fontSize: 14),
                                          softWrap: false,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isSaving
                                            ? null
                                            : () => _saveAnswer(skipped: true),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text(
                                          'Pass',
                                          style: TextStyle(fontSize: 14),
                                          softWrap: false,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: (_isSaving || 
                                                (_answerController.text.trim().isEmpty && 
                                                 _currentAnswer == null))
                                        ? null
                                        : _saveAnswer,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryIndigo,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Save Answer',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
