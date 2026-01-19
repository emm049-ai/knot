import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'ai_service.dart';

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  static Future<String> scanImage(File imageFile) async {
    if (kIsWeb) {
      throw Exception('OCR is not supported on web. Please use this feature on a mobile device.');
    }
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    return recognizedText.text;
  }

  static Future<String> scanFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image == null) {
      throw Exception('No image selected');
    }
    
    return await scanImage(File(image.path));
  }

  static Future<String> scanFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) {
      throw Exception('No image selected');
    }
    
    return await scanImage(File(image.path));
  }

  static Future<Map<String, dynamic>> scanAndClassify(File imageFile) async {
    final rawText = await scanImage(imageFile);
    return await AIService.classifyOCRText(rawText);
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
