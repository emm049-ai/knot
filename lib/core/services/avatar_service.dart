import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';

class AvatarService {
  // Try Google Imagen first (uses same API key as Gemini), then Stability AI, then Hugging Face
  static Future<String> generateAvatarImage(String prompt) async {
    String? lastError;
    
    // Try Google Imagen first (uses GEMINI_API_KEY)
    try {
      return await _generateWithImagen(prompt);
    } catch (e) {
      lastError = 'Google Imagen: ${e.toString()}';
      print('Google Imagen failed: $e');
    }
    
    // Try Stability AI
    try {
      return await _generateWithStabilityAI(prompt);
    } catch (e) {
      lastError = 'Stability AI: ${e.toString()}';
      print('Stability AI failed: $e');
    }
    
    // Fallback to Hugging Face
    try {
      return await _generateWithHuggingFace(prompt);
    } catch (e2) {
      print('Hugging Face failed: $e2');
      final hfError = 'Hugging Face: ${e2.toString()}';
      
      // Provide helpful error message
      throw Exception(
        'Avatar generation failed.\n\n'
        'Tried: Google Imagen, Stability AI, Hugging Face\n\n'
        'To fix:\n'
        '1. Your GEMINI_API_KEY should work with Google Imagen\n'
        '2. Or add STABILITY_AI_API_KEY to .env\n'
        '   Get free key: https://platform.stability.ai/\n\n'
        'Errors:\n$lastError\n$hfError'
      );
    }
  }

  // Google Imagen via Gemini API (tries to use GEMINI_API_KEY)
  static Future<String> _generateWithImagen(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found. Add it to .env to use Google image generation.');
    }

    // Try Gemini's image generation endpoint (if available in your tier)
    // Note: Image generation may not be available in free tier
    try {
      // First, try the experimental image generation endpoint
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt,
            }],
          }],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Try to extract image from response
        // Response format varies, so we try multiple paths
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['inlineData'] != null) {
                final imageData = part['inlineData']['data'] as String?;
                if (imageData != null) {
                  return 'data:image/png;base64,$imageData';
                }
              }
            }
          }
        }
        throw Exception('Image generation model not available in your API tier');
      } else if (response.statusCode == 404) {
        throw Exception('Image generation endpoint not found. May not be available in free tier.');
      } else {
        final errorBody = response.body;
        throw Exception('Google image generation failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      // If it's a clear "not available" error, provide helpful message
      if (e.toString().contains('404') || e.toString().contains('not available')) {
        throw Exception('Google image generation not available. Your GEMINI_API_KEY may not have access to image generation models. Try Stability AI instead.');
      }
      rethrow;
    }
  }

  // Stability AI (free tier: 25 images/month)
  static Future<String> _generateWithStabilityAI(String prompt) async {
    final apiKey = dotenv.env['STABILITY_AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('STABILITY_AI_API_KEY not found in .env. Get a free key at https://platform.stability.ai/');
    }

    // Use Stability AI v1 API (more reliable)
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image'),
    );
    
    request.headers.addAll({
      'Authorization': 'Bearer $apiKey',
      'Accept': 'application/json',
    });
    
    request.fields['text_prompts[0][text]'] = prompt;
    request.fields['cfg_scale'] = '7';
    request.fields['height'] = '1024';
    request.fields['width'] = '768';
    request.fields['samples'] = '1';
    request.fields['steps'] = '30';
    request.fields['style_preset'] = 'digital-art';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final artifacts = data['artifacts'] as List<dynamic>?;
      if (artifacts != null && artifacts.isNotEmpty) {
        final imageBase64 = artifacts[0]['base64'] as String;
        return 'data:image/png;base64,$imageBase64';
      }
      throw Exception('No image in Stability AI response');
    } else {
      throw Exception('Stability AI error: ${response.statusCode} - ${response.body}');
    }
  }

  // Hugging Face (free, no API key needed for some models)
  static Future<String> _generateWithHuggingFace(String prompt) async {
    // Try multiple models in order
    final models = [
      'stabilityai/stable-diffusion-2-1',
      'runwayml/stable-diffusion-v1-5',
      'CompVis/stable-diffusion-v1-4',
    ];
    
    final apiKey = dotenv.env['HUGGING_FACE_API_KEY'] ?? ''; // Optional

    for (final model in models) {
      try {
        final headers = <String, String>{
          'Content-Type': 'application/json',
        };
        if (apiKey.isNotEmpty) {
          headers['Authorization'] = 'Bearer $apiKey';
        }

        final response = await http.post(
          Uri.parse('https://api-inference.huggingface.co/models/$model'),
          headers: headers,
          body: jsonEncode({
            'inputs': prompt,
            'parameters': {
              'guidance_scale': 7.5,
              'num_inference_steps': 30,
            },
          }),
        );

        if (response.statusCode == 200) {
          // Check if response is JSON (error) or image
          try {
            final jsonData = jsonDecode(response.body);
            if (jsonData is Map && jsonData.containsKey('error')) {
              // Model error, try next model
              continue;
            }
          } catch (_) {
            // Not JSON, assume it's an image
            final base64Image = base64Encode(response.bodyBytes);
            return 'data:image/png;base64,$base64Image';
          }
          // If we get here, it's JSON but no error key, try to extract image
          final base64Image = base64Encode(response.bodyBytes);
          return 'data:image/png;base64,$base64Image';
        } else if (response.statusCode == 503) {
          // Model is loading, wait and retry this model
          await Future.delayed(const Duration(seconds: 15));
          // Retry this model once
          final retryResponse = await http.post(
            Uri.parse('https://api-inference.huggingface.co/models/$model'),
            headers: headers,
            body: jsonEncode({
              'inputs': prompt,
              'parameters': {
                'guidance_scale': 7.5,
                'num_inference_steps': 30,
              },
            }),
          );
          if (retryResponse.statusCode == 200) {
            final base64Image = base64Encode(retryResponse.bodyBytes);
            return 'data:image/png;base64,$base64Image';
          }
          // If retry fails, try next model
          continue;
        } else {
          // Try next model
          continue;
        }
      } catch (e) {
        // Try next model
        continue;
      }
    }
    
    throw Exception('All Hugging Face models failed. The service may be temporarily unavailable. Please try Stability AI with an API key.');
  }
}
