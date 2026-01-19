import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/knot_app_bar.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../core/theme/app_theme.dart';

class RecordInteractionPage extends StatefulWidget {
  const RecordInteractionPage({super.key});

  @override
  State<RecordInteractionPage> createState() => _RecordInteractionPageState();
}

class _RecordInteractionPageState extends State<RecordInteractionPage> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  String? _selectedContactId;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isRecording = false;
  String? _attachedLabel;
  String _inputType = 'manual';
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _recordingTimer?.cancel();
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

  Future<void> _startVoiceRecording() async {
    setState(() {
      _isRecording = true;
      _isProcessing = false;
      _recordingDuration = Duration.zero;
    });
    try {
      await VoiceService.startRecording();
      _startTimer();
    } catch (e) {
      _stopTimer();
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    try {
      setState(() => _isProcessing = true);
      final file = await VoiceService.stopRecording();
      _stopTimer();
      if (file == null) {
        setState(() {
          _isRecording = false;
          _isProcessing = false;
        });
        return;
      }
      final transcription = await AIService.transcribeAudio(file);
      setState(() {
        _summaryController.text = transcription;
        _attachedLabel = 'Voice note captured';
        _inputType = 'voice';
        _isRecording = false;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing recording: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  Future<void> _captureScreenshot() async {
    setState(() => _isProcessing = true);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }
      final text = await OCRService.scanImage(File(image.path));
      setState(() {
        _summaryController.text = text;
        _attachedLabel = 'Screenshot imported';
        _inputType = 'ocr';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading screenshot: $e')),
        );
      }
    }
  }

  Future<void> _capturePdf() async {
    setState(() => _isProcessing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }
      final fileName = result.files.first.name;
      setState(() {
        _summaryController.text =
            'PDF captured: $fileName\nAdd a short summary of the interaction.';
        _attachedLabel = 'PDF captured: $fileName';
        _inputType = 'manual';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing PDF: $e')),
        );
      }
    }
  }

  Future<void> _saveInteraction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContactId == null) return;

    setState(() => _isProcessing = true);
    try {
      await SupabaseService.createNote(
        _selectedContactId!,
        _summaryController.text.trim(),
        _inputType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interaction saved')),
        );
        setState(() {
          _summaryController.clear();
          _attachedLabel = null;
          _inputType = 'manual';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving interaction: $e'),
            backgroundColor: AppTheme.alertCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Record Interaction',
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRecording
                              ? _stopVoiceRecording
                              : (_isProcessing ? null : _startVoiceRecording),
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? 'Stop' : 'Voice Note'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isRecording ? AppTheme.alertCoral : null,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _isProcessing || _isRecording ? null : _captureScreenshot,
                          icon: const Icon(Icons.image),
                          label: const Text('Screenshot'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isProcessing || _isRecording ? null : _capturePdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                        ),
                      ],
                    ),
                    if (_isRecording) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Recording... ${_formatDuration(_recordingDuration)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (_attachedLabel != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _attachedLabel!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _summaryController,
                      decoration: const InputDecoration(
                        labelText: 'Interaction Summary',
                        hintText: 'Paste text, summarize, or add details',
                      ),
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please add a summary or notes';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _saveInteraction,
                      icon: const Icon(Icons.save),
                      label: Text(_isProcessing ? 'Saving...' : 'Save Interaction'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
