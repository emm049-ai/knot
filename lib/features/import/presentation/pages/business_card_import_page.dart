import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/widgets/knot_app_bar.dart';

class BusinessCardImportPage extends StatefulWidget {
  const BusinessCardImportPage({super.key});

  @override
  State<BusinessCardImportPage> createState() => _BusinessCardImportPageState();
}

class _BusinessCardImportPageState extends State<BusinessCardImportPage> {
  bool _isProcessing = false;
  File? _selectedImage;
  Uint8List? _imageBytes; // For web compatibility
  Map<String, dynamic>? _extractedData;

  Future<void> _takePhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedData = null;
        });
        // Load image bytes for web compatibility
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() => _imageBytes = bytes);
        }
        await _processImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedData = null;
        });
        // Load image bytes for web compatibility
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() => _imageBytes = bytes);
        }
        await _processImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() => _isProcessing = true);
    try {
      final extractedData = await OCRService.scanAndClassify(_selectedImage!);
      setState(() {
        _extractedData = extractedData;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing business card: $e')),
        );
      }
    }
  }

  void _continueToCapture() {
    if (_extractedData != null) {
      context.push('/capture', extra: {
        'prefill': _extractedData,
        'source': 'business_card',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Import from Business Card',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 48,
                      color: AppTheme.primaryIndigo,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan Business Card',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take a photo of a business card to extract contact information',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Camera Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Business Card'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextButton.icon(
              onPressed: _isProcessing ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Or select from gallery'),
            ),
            
            if (_isProcessing) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Text(
                'Processing business card...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.mediumGray),
              ),
            ],
            
            if (_selectedImage != null && !_isProcessing) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanned Card',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb && _imageBytes != null
                            ? Image.memory(
                                _imageBytes!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            if (_extractedData != null) ...[
              const SizedBox(height: 24),
              Card(
                color: AppTheme.growthGreen.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.growthGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Information Extracted',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppTheme.growthGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_extractedData!['name'] != null)
                        _buildExtractedField('Name', _extractedData!['name']),
                      if (_extractedData!['email'] != null)
                        _buildExtractedField('Email', _extractedData!['email']),
                      if (_extractedData!['phone'] != null)
                        _buildExtractedField('Phone', _extractedData!['phone']),
                      if (_extractedData!['company'] != null)
                        _buildExtractedField('Company', _extractedData!['company']),
                      if (_extractedData!['jobTitle'] != null)
                        _buildExtractedField('Job Title', _extractedData!['jobTitle']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _continueToCapture,
                child: const Text('Continue to Add Contact'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.darkGray),
            ),
          ),
        ],
      ),
    );
  }
}
