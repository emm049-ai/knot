import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ai_service.dart';

class VoiceService {
  static final AudioRecorder _recorder = AudioRecorder();

  static Future<bool> checkPermissions() async {
    final micPermission = await Permission.microphone.request();
    return micPermission.isGranted;
  }

  static Future<File> startRecording() async {
    if (kIsWeb) {
      throw Exception('Voice recording is not supported on web. Please use this feature on a mobile device.');
    }
    
    if (!await checkPermissions()) {
      throw Exception('Microphone permission not granted');
    }

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: filePath,
    );

    return File(filePath);
  }

  static Future<File?> stopRecording() async {
    final path = await _recorder.stop();
    if (path != null) {
      return File(path);
    }
    return null;
  }

  static Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  static Future<Map<String, dynamic>> recordAndExtract() async {
    final recordingFile = await startRecording();
    
    // Wait for user to stop recording (this would be handled by UI)
    // For now, we'll assume the file is ready
    
    final transcription = await AIService.transcribeAudio(recordingFile);
    final extractedData = await AIService.extractContactInfo(transcription);
    
    return {
      'transcription': transcription,
      'extractedData': extractedData,
    };
  }

  static void dispose() {
    _recorder.dispose();
  }
}
