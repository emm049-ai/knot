import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;
  
  // User operations
  static Future<User?> getCurrentUser() async {
    return client.auth.currentUser;
  }
  
  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  // Contact operations
  static Future<List<Map<String, dynamic>>> getContacts(String userId) async {
    final response = await client
        .from('contacts')
        .select()
        .eq('user_id', userId)
        .order('last_contacted_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  // Ensure user exists in users table (create if not exists)
  static Future<void> ensureUserExists(String userId) async {
    try {
      // Try to get user profile
      final profile = await getUserProfile(userId);
      if (profile != null) return; // User already exists
      
      // Create user record if it doesn't exist
      try {
        await client.from('users').insert({
          'id': userId,
          'bcc_email': '$userId@inbound.careercaddie.com',
          'streak_count': 0,
        });
      } catch (insertError) {
        // If insert fails (e.g., duplicate key), user might have been created
        // by another request - that's okay, check again
        final profileCheck = await getUserProfile(userId);
        if (profileCheck == null) {
          // Still doesn't exist, re-throw the error
          throw insertError;
        }
        // User exists now, we're good
      }
    } catch (e) {
      // If insert fails, user might already exist (race condition)
      // That's okay, we'll try again on next operation
      print('Note: ensureUserExists: $e');
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await client.from('users').update(updates).eq('id', userId);
  }
  
  static Future<Map<String, dynamic>> createContact(
    String userId,
    Map<String, dynamic> contactData,
  ) async {
    // Ensure user exists in users table before creating contact
    await ensureUserExists(userId);
    
    final response = await client
        .from('contacts')
        .insert({
          ...contactData,
          'user_id': userId,
          'relationship_health': 100,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return response as Map<String, dynamic>;
  }
  
  static Future<Map<String, dynamic>> updateContact(
    String contactId,
    Map<String, dynamic> updates,
  ) async {
    final response = await client
        .from('contacts')
        .update(updates)
        .eq('id', contactId)
        .select()
        .single();
    return response as Map<String, dynamic>;
  }
  
  static Future<void> deleteContact(String contactId) async {
    await client.from('contacts').delete().eq('id', contactId);
  }
  
  // Notes operations
  static Future<List<Map<String, dynamic>>> getNotes(String contactId) async {
    final response = await client
        .from('notes')
        .select()
        .eq('contact_id', contactId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  static Future<Map<String, dynamic>> createNote(
    String contactId,
    String content,
    String inputType,
  ) async {
    final response = await client
        .from('notes')
        .insert({
          'contact_id': contactId,
          'content': content,
          'input_type': inputType,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return response as Map<String, dynamic>;
  }
}
