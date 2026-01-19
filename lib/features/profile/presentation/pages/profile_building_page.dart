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

class ProfileBuildingPage extends StatefulWidget {
  const ProfileBuildingPage({super.key});

  @override
  State<ProfileBuildingPage> createState() => _ProfileBuildingPageState();
}

class _ProfileBuildingPageState extends State<ProfileBuildingPage> {
  final List<String> _phases = [
    'basic_info',
    'goals',
    'communication_style',
  ];
  
  String _currentPhase = 'basic_info';
  String? _currentQuestion;
  String? _currentQuestionId;
  String? _currentQuestionSet;
  String? _currentAnswer;
  bool _isLoadingQuestion = false;
  bool _isSaving = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  File? _recordingFile;
  final TextEditingController _answerController = TextEditingController();
  List<ProfileAnswer> _phaseAnswers = [];
  Map<String, Map<String, dynamic>> _phasesStatus = {};
  Map<String, int> _overallProgress = {'answered': 0, 'total': 9};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingQuestion = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      // Load phase status
      _phasesStatus = await UserProfileService.getPhasesStatus(user.id);
      
      // Load current phase answers
      _phaseAnswers = await UserProfileService.getPhaseAnswers(user.id, _currentPhase);
      
      // Update overall progress
      _overallProgress = await UserProfileService.getOverallProgress(user.id);
      
      // Generate or get next question
      await _loadNextQuestion();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingQuestion = false);
      }
    }
  }

  Future<void> _loadNextQuestion() async {
    setState(() => _isLoadingQuestion = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return;

      // Get next question for current phase
      final nextQuestion = await UserProfileService.getNextQuestionForPhase(
        user.id,
        _currentPhase,
      );
      
      if (nextQuestion != null) {
        _currentQuestionId = nextQuestion['id'];
        _currentQuestion = nextQuestion['question'];
        _currentQuestionSet = nextQuestion['question_set'];
      } else {
        // No more questions in this phase, try next phase
        final currentIndex = _phases.indexOf(_currentPhase);
        if (currentIndex < _phases.length - 1) {
          setState(() {
            _currentPhase = _phases[currentIndex + 1];
          });
          await _loadProfile(); // Reload with new phase
          return;
        } else {
          // No more questions in any phase
          _currentQuestion = null;
        }
      }
      
      _currentAnswer = null;
      _answerController.clear();
      
      // Update overall progress
      _overallProgress = await UserProfileService.getOverallProgress(user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading question: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingQuestion = false);
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
        // Show transcription dialog for editing
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

  Future<void> _saveAnswer({bool skipped = false, bool answerLater = false}) async {
    if (_currentQuestion == null || _currentQuestionId == null) return;
    
    setState(() => _isSaving = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return;

      final answer = ProfileAnswer(
        id: _currentQuestionId!,
        userId: user.id,
        phase: _currentPhase,
        question: _currentQuestion!,
        answer: skipped || answerLater ? null : (_answerController.text.trim().isEmpty 
            ? _currentAnswer 
            : _answerController.text.trim()),
        answerType: skipped || answerLater ? null : (_isRecording || _recordingFile != null ? 'voice' : 'text'),
        skipped: skipped,
        answerLater: answerLater,
        questionSet: _currentQuestionSet ?? 'initial',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await UserProfileService.saveAnswer(answer);
      
      // Update persona periodically
      if (_phaseAnswers.length % 5 == 0) {
        await UserProfileService.updatePersona(user.id);
      }

      // Reload phase answers and get next question
      _phaseAnswers = await UserProfileService.getPhaseAnswers(user.id, _currentPhase);
      _phasesStatus = await UserProfileService.getPhasesStatus(user.id);
      _overallProgress = await UserProfileService.getOverallProgress(user.id);
      
      _answerController.clear();
      _currentAnswer = null;
      _recordingFile = null;
      
      await _loadNextQuestion();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(answerLater 
                ? 'Question saved for next week' 
                : 'Answer saved!'),
          ),
        );
      }
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

  Future<void> _switchPhase(String phase) async {
    setState(() {
      _currentPhase = phase;
      _currentQuestion = null;
      _currentAnswer = null;
      _answerController.clear();
    });
    await _loadProfile();
  }

  String _getPhaseName(String phase) {
    const names = {
      'basic_info': 'Basic Info',
      'goals': 'Goals',
      'communication_style': 'Communication',
    };
    return names[phase] ?? phase;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Build Your Profile',
        extraActions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile/view'),
            tooltip: 'View what I know',
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
            // Progress and Phase selector
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Overall progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: ${_overallProgress['answered']}/${_overallProgress['total']}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${((_overallProgress['answered']! / _overallProgress['total']!) * 100).round()}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryIndigo,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _overallProgress['total']! > 0 
                        ? _overallProgress['answered']! / _overallProgress['total']!
                        : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryIndigo),
                  ),
                  const SizedBox(height: 16),
                  // Phase selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _phases.asMap().entries.map((entry) {
                        final index = entry.key;
                        final phase = entry.value;
                        final isActive = phase == _currentPhase;
                        final status = _phasesStatus[phase];
                        final completeness = status?['completeness'] ?? 0;
                        
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PhaseIndicator(
                              phase: phase,
                              phaseNumber: index + 1,
                              isActive: isActive,
                              completeness: completeness,
                              onTap: () => _switchPhase(phase),
                            ),
                            if (index < _phases.length - 1)
                              Container(
                                width: 20,
                                height: 2,
                                color: isActive 
                                    ? AppTheme.primaryIndigo 
                                    : Colors.grey.shade300,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
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
                              _getPhaseName(_currentPhase),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primaryIndigo,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (_isLoadingQuestion)
                              const Center(child: CircularProgressIndicator())
                            else if (_currentQuestion != null)
                              Text(
                                _currentQuestion!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              )
                            else
                              const Text('Loading question...'),
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
                                        onPressed: _isSaving || _isLoadingQuestion
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
                                        onPressed: _isSaving || _isLoadingQuestion
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
                                                _isLoadingQuestion || 
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

class _PhaseIndicator extends StatelessWidget {
  final String phase;
  final int phaseNumber;
  final bool isActive;
  final int completeness;
  final VoidCallback onTap;

  const _PhaseIndicator({
    required this.phase,
    required this.phaseNumber,
    required this.isActive,
    required this.completeness,
    required this.onTap,
  });

  String _getPhaseName(String phase) {
    const names = {
      'basic_info': 'Basic Info',
      'goals': 'Goals',
      'communication_style': 'Communication',
    };
    return names[phase] ?? phase;
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppTheme.alertCoral,
      AppTheme.accentAmber,
      AppTheme.accentTeal,
      AppTheme.primaryIndigo,
      AppTheme.growthGreen,
    ];
    final color = colors[phaseNumber % colors.length];
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: const BoxConstraints(minWidth: 60),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '0$phaseNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? color : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getPhaseName(phase),
              style: TextStyle(
                fontSize: 11,
                color: isActive ? color : Colors.grey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
            ),
            if (completeness > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$completeness%',
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
