import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/knot_app_bar.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/contact_model.dart';
import 'package:uuid/uuid.dart';

class CapturePage extends StatefulWidget {
  final Map<String, dynamic>? prefillData;
  
  const CapturePage({super.key, this.prefillData});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _preferredNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _firstInteractionContextController = TextEditingController();
  final _relationshipNatureController = TextEditingController();
  final _relationshipGoalController = TextEditingController();
  final _maritalStatusController = TextEditingController();
  final _kidsCountController = TextEditingController();
  final _kidsDetailsController = TextEditingController();
  final _additionalDetailsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isRecording = false;
  bool _isProcessing = false;
  File? _recordingFile;

  @override
  void initState() {
    super.initState();
    // Pre-fill form if data provided from import
    if (widget.prefillData != null) {
      final prefill = widget.prefillData!;
      _applyNamePrefill(prefill['name']?.toString());
      _companyController.text = prefill['company']?.toString() ?? '';
      _jobTitleController.text = prefill['jobTitle']?.toString() ?? '';
      _emailController.text = prefill['email']?.toString() ?? '';
      _phoneController.text = prefill['phone']?.toString() ?? '';
      if (prefill['linkedin_url'] != null) {
        // Store LinkedIn URL in notes if not already there
        _linkedinController.text = prefill['linkedin_url'].toString();
      }
      if (prefill['headline'] != null && _jobTitleController.text.isEmpty) {
        _jobTitleController.text = prefill['headline'].toString();
      }
    }
  }

  void _applyNamePrefill(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return;
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return;
    _firstNameController.text = parts.first;
    if (parts.length > 1) {
      _lastNameController.text = parts.last;
      if (parts.length > 2) {
        _middleNameController.text = parts.sublist(1, parts.length - 1).join(' ');
      }
    }
  }

  String _buildDisplayName() {
    final preferred = _preferredNameController.text.trim();
    if (preferred.isNotEmpty) return preferred;
    final first = _firstNameController.text.trim();
    final middle = _middleNameController.text.trim();
    final last = _lastNameController.text.trim();
    final suffix = _suffixController.text.trim();
    final nameParts = [
      if (first.isNotEmpty) first,
      if (middle.isNotEmpty) middle,
      if (last.isNotEmpty) last,
      if (suffix.isNotEmpty) suffix,
    ];
    return nameParts.join(' ');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _preferredNameController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedinController.dispose();
    _firstInteractionContextController.dispose();
    _relationshipNatureController.dispose();
    _relationshipGoalController.dispose();
    _maritalStatusController.dispose();
    _kidsCountController.dispose();
    _kidsDetailsController.dispose();
    _additionalDetailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceRecording() async {
    setState(() {
      _isRecording = true;
      _isProcessing = true;
    });

    try {
      final recordingFile = await VoiceService.startRecording();
      setState(() => _recordingFile = recordingFile);
    } catch (e) {
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
      final file = await VoiceService.stopRecording();
      if (file != null) {
        setState(() {
          _isRecording = false;
          _isProcessing = true;
        });

        // Transcribe and extract
        final transcription = await AIService.transcribeAudio(file);
        final extractedData = await AIService.extractContactInfo(transcription);

        // Populate form
        setState(() {
          _applyNamePrefill(extractedData['name']?.toString());
          _companyController.text = extractedData['company'] ?? '';
          _jobTitleController.text = extractedData['jobTitle'] ?? '';
          _notesController.text = transcription;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _isRecording = false;
          _isProcessing = false;
        });
      }
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

  Future<void> _scanBusinessCard() async {
    setState(() => _isProcessing = true);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final imageFile = File(image.path);
      final extractedData = await OCRService.scanAndClassify(imageFile);

      setState(() {
        _applyNamePrefill(extractedData['name']?.toString());
        _companyController.text = extractedData['company'] ?? '';
        _jobTitleController.text = extractedData['jobTitle'] ?? '';
        _emailController.text = extractedData['email'] ?? '';
        _phoneController.text = extractedData['phone'] ?? '';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final displayName = _buildDisplayName();
      if (displayName.isEmpty) {
        throw Exception('Please provide at least a first and last name.');
      }

      final kidsCount = int.tryParse(_kidsCountController.text.trim());
      final contactData = {
        'name': displayName,
        'first_name': _firstNameController.text.trim().isEmpty
            ? null
            : _firstNameController.text.trim(),
        'middle_name': _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        'last_name': _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
        'suffix': _suffixController.text.trim().isEmpty
            ? null
            : _suffixController.text.trim(),
        'preferred_name': _preferredNameController.text.trim().isEmpty
            ? null
            : _preferredNameController.text.trim(),
        'company': _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        'job_title': _jobTitleController.text.trim().isEmpty
            ? null
            : _jobTitleController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'linkedin_url': _linkedinController.text.trim().isEmpty
            ? null
            : _linkedinController.text.trim(),
        'first_interaction_context': _firstInteractionContextController.text.trim().isEmpty
            ? null
            : _firstInteractionContextController.text.trim(),
        'relationship_nature': _relationshipNatureController.text.trim().isEmpty
            ? null
            : _relationshipNatureController.text.trim(),
        'relationship_goal': _relationshipGoalController.text.trim().isEmpty
            ? null
            : _relationshipGoalController.text.trim(),
        'marital_status': _maritalStatusController.text.trim().isEmpty
            ? null
            : _maritalStatusController.text.trim(),
        'kids_count': kidsCount,
        'kids_details': _kidsDetailsController.text.trim().isEmpty
            ? null
            : _kidsDetailsController.text.trim(),
        'additional_details': _additionalDetailsController.text.trim().isEmpty
            ? null
            : _additionalDetailsController.text.trim(),
      };

      final contact = await SupabaseService.createContact(user.id, contactData);

      // Save note if exists
      if (_notesController.text.trim().isNotEmpty) {
        await SupabaseService.createNote(
          contact['id'],
          _notesController.text.trim(),
          _recordingFile != null ? 'voice' : 'manual',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact saved!')),
        );
        context.go('/contacts');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving contact: $e'),
            backgroundColor: AppTheme.alertCoral,
            duration: const Duration(seconds: 5),
          ),
        );
        print('Full error details: $e');
        print('Error type: ${e.runtimeType}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Add Contact',
      ),
      body: _isProcessing && !_isRecording
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Capture Methods
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Quick Capture',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isRecording
                                        ? _stopVoiceRecording
                                        : _startVoiceRecording,
                                    icon: Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                    ),
                                    label: Text(_isRecording ? 'Stop' : 'Voice'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isRecording
                                          ? AppTheme.alertCoral
                                          : AppTheme.primaryIndigo,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _scanBusinessCard,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Scan'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Form Fields
                    Text(
                      'Name & Identity',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        hintText: 'Enter first name',
                      ),
                      validator: (value) {
                        final first = value?.trim() ?? '';
                        final preferred = _preferredNameController.text.trim();
                        if (first.isEmpty && preferred.isEmpty) {
                          return 'First or preferred name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _middleNameController,
                      decoration: const InputDecoration(
                        labelText: 'Middle Name',
                        hintText: 'Enter middle name (optional)',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        hintText: 'Enter last name',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _suffixController,
                      decoration: const InputDecoration(
                        labelText: 'Suffix',
                        hintText: 'e.g., Jr., Sr., III',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _preferredNameController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Name',
                        hintText: 'What they prefer to be called',
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Contact Details',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company',
                        hintText: 'Enter company name',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _jobTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Job Title',
                        hintText: 'Enter job title',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter email address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        hintText: 'Enter phone number',
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _linkedinController,
                      decoration: const InputDecoration(
                        labelText: 'LinkedIn URL',
                        hintText: 'https://www.linkedin.com/in/...',
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Relationship Context',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _firstInteractionContextController,
                      decoration: const InputDecoration(
                        labelText: 'Context of First Interaction',
                        hintText: 'Where/when did you meet?',
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _relationshipNatureController,
                      decoration: const InputDecoration(
                        labelText: 'Nature of Relationship',
                        hintText: 'Mentor, peer, client, friend, etc.',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _relationshipGoalController,
                      decoration: const InputDecoration(
                        labelText: 'Aim of Relationship',
                        hintText: 'What do you want to build together?',
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Personal Details',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _maritalStatusController,
                      decoration: const InputDecoration(
                        labelText: 'Marital Status',
                        hintText: 'Optional',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _kidsCountController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Kids',
                        hintText: 'Optional',
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _kidsDetailsController,
                      decoration: const InputDecoration(
                        labelText: 'Kids Details',
                        hintText: 'Names/ages/other details (optional)',
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _additionalDetailsController,
                      decoration: const InputDecoration(
                        labelText: 'Other Personal Details',
                        hintText: 'Anything else that helps build a fuller picture',
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Interaction Notes',
                        hintText: 'Any additional notes or context',
                      ),
                      maxLines: 4,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _saveContact,
                      child: const Text('Save Contact'),
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
