import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';

class LinkedInService {
  // LinkedIn OAuth 2.0 configuration
  static String? _clientId;
  static String? _clientSecret;
  static String? _redirectUri;
  static String? _accessToken;

  static void initialize() {
    _clientId = dotenv.env['LINKEDIN_CLIENT_ID'];
    _clientSecret = dotenv.env['LINKEDIN_CLIENT_SECRET'];
    // LinkedIn requires HTTP/HTTPS redirect URLs, not custom schemes
    _redirectUri = dotenv.env['LINKEDIN_REDIRECT_URI'] ?? 'https://yourdomain.com/linkedin-callback';
  }

  // Get LinkedIn OAuth authorization URL
  static String getAuthorizationUrl() {
    if (_clientId == null || _redirectUri == null) {
      throw Exception('LinkedIn OAuth not configured. Please set LINKEDIN_CLIENT_ID and LINKEDIN_REDIRECT_URI in .env');
    }

    // OpenID Connect scopes - w_member_social requires additional API products
    final scopes = [
      'openid',
      'profile',
      'email',
    ].join(' ');

    return 'https://www.linkedin.com/oauth/v2/authorization?'
        'response_type=code&'
        'client_id=$_clientId&'
        'redirect_uri=$_redirectUri&'
        'state=random_state_string&'
        'scope=$scopes';
  }

  // Exchange authorization code for access token
  static Future<String> exchangeCodeForToken(String code) async {
    if (_clientId == null || _clientSecret == null || _redirectUri == null) {
      throw Exception('LinkedIn OAuth not configured');
    }

    final response = await http.post(
      Uri.parse('https://www.linkedin.com/oauth/v2/accessToken'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri!,
        'client_id': _clientId!,
        'client_secret': _clientSecret!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'] as String;
      return _accessToken!;
    } else {
      throw Exception('Failed to get access token: ${response.body}');
    }
  }

  // Get user's own profile
  static Future<Map<String, dynamic>> getOwnProfile() async {
    if (_accessToken == null) {
      throw Exception('Not authenticated. Please complete OAuth flow first.');
    }

    final response = await http.get(
      Uri.parse('https://api.linkedin.com/v2/userinfo'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get profile: ${response.body}');
    }
  }

  // Get profile by LinkedIn URL (requires OAuth and proper permissions)
  // Note: LinkedIn API v2 requires the person to be in your network or have granted permissions
  static Future<Map<String, dynamic>?> getProfileByUrl(String linkedInUrl) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated. Please complete OAuth flow first.');
    }

    // Extract profile ID from URL
    // Format: https://www.linkedin.com/in/username or linkedin.com/in/username
    final profileId = _extractProfileId(linkedInUrl);
    if (profileId == null) {
      return null;
    }

    try {
      // Try to get profile using LinkedIn API
      // Note: This requires the profile owner to be in your network or have granted access
      final response = await http.get(
        Uri.parse('https://api.linkedin.com/v2/people/(id:$profileId)'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'name': '${data['firstName']?['localized']?['en_US'] ?? ''} ${data['lastName']?['localized']?['en_US'] ?? ''}'.trim(),
          'linkedin_url': linkedInUrl,
          'headline': data['headline']?['localized']?['en_US'],
          'profile_id': profileId,
        };
      } else {
        // If we can't access via API, return basic info from URL
        return _extractBasicInfoFromUrl(linkedInUrl);
      }
    } catch (e) {
      // Fallback to basic extraction from URL
      return _extractBasicInfoFromUrl(linkedInUrl);
    }
  }

  // Extract profile ID from LinkedIn URL
  static String? _extractProfileId(String url) {
    final regex = RegExp(r'linkedin\.com/in/([^/?]+)');
    final match = regex.firstMatch(url.toLowerCase());
    return match?.group(1);
  }

  // Extract basic info from URL when API access is not available
  static Map<String, dynamic> _extractBasicInfoFromUrl(String linkedInUrl) {
    final profileId = _extractProfileId(linkedInUrl);
    if (profileId == null) {
      return {'linkedin_url': linkedInUrl};
    }

    // Convert profile ID to readable name (basic conversion)
    final nameParts = profileId
        .split('-')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1))
        .toList();

    return {
      'name': nameParts.join(' '),
      'linkedin_url': linkedInUrl,
      'profile_id': profileId,
    };
  }

  // Handle LinkedIn URL from share sheet
  static Future<Map<String, dynamic>?> enrichLinkedInProfile(String linkedInUrl) async {
    try {
      // First try to get profile via API if authenticated
      if (_accessToken != null) {
        final profile = await getProfileByUrl(linkedInUrl);
        if (profile != null && profile.containsKey('name') && profile['name']!.toString().isNotEmpty) {
          return profile;
        }
      }

      // Use AI to extract more info from LinkedIn URL
      try {
        final prompt = '''
Extract contact information from this LinkedIn profile URL: $linkedInUrl

The URL format is typically: linkedin.com/in/username
From the username, try to infer:
- Name (convert username format like "john-doe" to "John Doe")
- Any other information you can extract

Return contact information in the standard format.
''';
        
        final extractedData = await AIService.extractContactInfo(prompt);
        extractedData['linkedin_url'] = linkedInUrl;
        return extractedData;
      } catch (e) {
        print('AI extraction failed, using basic extraction: $e');
      }

      // Fallback to basic extraction from URL
      return _extractBasicInfoFromUrl(linkedInUrl);
    } catch (e) {
      print('Error enriching LinkedIn profile: $e');
      return _extractBasicInfoFromUrl(linkedInUrl);
    }
  }

  // Handle share intent (called from main.dart or platform-specific code)
  static Future<void> handleShareIntent(String? sharedText) async {
    if (sharedText == null || !sharedText.contains('linkedin.com')) {
      return;
    }

    final linkedInUrl = sharedText.contains('linkedin.com/in/')
        ? sharedText
        : null;

    if (linkedInUrl != null) {
      // Enrich and create contact
      final enrichedData = await enrichLinkedInProfile(linkedInUrl);
      // This would typically navigate to capture page with pre-filled data
      // or directly create the contact
    }
  }

  // Launch LinkedIn OAuth flow
  static Future<void> launchOAuthFlow() async {
    final authUrl = getAuthorizationUrl();
    final uri = Uri.parse(authUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch LinkedIn OAuth URL');
    }
  }

  // Handle OAuth callback
  static Future<void> handleOAuthCallback(Uri callbackUri) async {
    final code = callbackUri.queryParameters['code'];
    final state = callbackUri.queryParameters['state'];
    final error = callbackUri.queryParameters['error'];

    if (error != null) {
      throw Exception('LinkedIn OAuth error: $error');
    }

    if (code == null) {
      throw Exception('No authorization code received');
    }

    await exchangeCodeForToken(code);
  }
}
