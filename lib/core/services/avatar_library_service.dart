import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/contact_model.dart';

/// Avatar metadata for matching
class AvatarMetadata {
  final String id;
  final String assetPath; // Path to image asset
  final String description;
  final List<String> jobKeywords; // e.g., ['finance', 'accountant', 'banker']
  final String? gender; // 'male', 'female', 'neutral', null for any
  final String? ageRange; // 'young', 'adult', 'senior', null for any
  final List<String>? ethnicity; // ['asian', 'black', 'white', 'hispanic', etc.], null for any
  final String? outfit; // 'business', 'casual', 'formal', 'uniform', etc.
  final String? accessory; // 'glasses', 'hat', 'clipboard', etc.

  AvatarMetadata({
    required this.id,
    required this.assetPath,
    required this.description,
    required this.jobKeywords,
    this.gender,
    this.ageRange,
    this.ethnicity,
    this.outfit,
    this.accessory,
  });

  factory AvatarMetadata.fromJson(Map<String, dynamic> json) {
    return AvatarMetadata(
      id: json['id'] as String,
      assetPath: json['assetPath'] as String,
      description: json['description'] as String,
      jobKeywords: List<String>.from(json['jobKeywords'] ?? []),
      gender: json['gender'] as String?,
      ageRange: json['ageRange'] as String?,
      ethnicity: json['ethnicity'] != null
          ? List<String>.from(json['ethnicity'])
          : null,
      outfit: json['outfit'] as String?,
      accessory: json['accessory'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetPath': assetPath,
      'description': description,
      'jobKeywords': jobKeywords,
      'gender': gender,
      'ageRange': ageRange,
      'ethnicity': ethnicity,
      'outfit': outfit,
      'accessory': accessory,
    };
  }
}

class AvatarLibraryService {
  static List<AvatarMetadata>? _avatarLibrary;
  static const String _libraryPath = 'assets/avatars/avatar_library.json';

  /// Load avatar library from assets
  static Future<List<AvatarMetadata>> loadAvatarLibrary() async {
    if (_avatarLibrary != null) return _avatarLibrary!;

    try {
      final String jsonString =
          await rootBundle.loadString(_libraryPath);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _avatarLibrary = jsonList
          .map((json) => AvatarMetadata.fromJson(json))
          .toList();
      return _avatarLibrary!;
    } catch (e) {
      print('Error loading avatar library: $e');
      // Return empty library if file doesn't exist yet
      _avatarLibrary = [];
      return _avatarLibrary!;
    }
  }

  /// Find best matching avatar for a contact
  static Future<String?> findMatchingAvatar(Contact contact) async {
    final library = await loadAvatarLibrary();
    if (library.isEmpty) return null;

    // Score each avatar based on how well it matches
    final scores = <AvatarMetadata, int>{};

    for (final avatar in library) {
      int score = 0;

      // Job title matching (highest weight)
      final jobTitle = (contact.jobTitle ?? '').toLowerCase();
      for (final keyword in avatar.jobKeywords) {
        if (jobTitle.contains(keyword.toLowerCase())) {
          score += 10;
          break;
        }
      }

      // Company/industry matching
      final company = (contact.company ?? '').toLowerCase();
      for (final keyword in avatar.jobKeywords) {
        if (company.contains(keyword.toLowerCase())) {
          score += 5;
          break;
        }
      }

      // Gender matching (if specified in avatar and contact)
      if (avatar.gender != null) {
        // You'd need to add gender field to Contact model
        // For now, we'll skip this or infer from name
        // score += 3 if matches
      }

      // Age range matching (if specified)
      if (avatar.ageRange != null) {
        // You'd need to add age/birthday to Contact model
        // For now, we'll skip this
      }

      // Outfit matching (if contact has outfit preference)
      if (avatar.outfit != null &&
          contact.avatarOutfit != null &&
          contact.avatarOutfit != 'Auto') {
        if (avatar.outfit!.toLowerCase() ==
            contact.avatarOutfit!.toLowerCase()) {
          score += 5;
        }
      }

      // Accessory matching
      if (avatar.accessory != null &&
          contact.avatarAccessory != null &&
          contact.avatarAccessory != 'Auto') {
        if (avatar.accessory!.toLowerCase() ==
            contact.avatarAccessory!.toLowerCase()) {
          score += 3;
        }
      }

      scores[avatar] = score;
    }

    // Find avatar with highest score
    if (scores.isEmpty) return null;

    final bestMatch = scores.entries.reduce((a, b) => a.value > b.value ? a : b);

    // Only return if score is above threshold (at least some job match)
    if (bestMatch.value >= 5) {
      return bestMatch.key.assetPath;
    }

    // If no good match, return a random avatar or null
    return null;
  }

  /// Get all avatars (for admin/manual selection)
  static Future<List<AvatarMetadata>> getAllAvatars() async {
    return await loadAvatarLibrary();
  }

  /// Add a new avatar to the library (for future: save to Supabase or local storage)
  static Future<void> addAvatar(AvatarMetadata avatar) async {
    final library = await loadAvatarLibrary();
    library.add(avatar);
    // In production, you'd save this to Supabase or local storage
    // For now, it's just in memory
  }
}
