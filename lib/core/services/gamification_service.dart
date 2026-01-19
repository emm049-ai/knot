import '../services/supabase_service.dart';
import '../models/contact_model.dart';

class GamificationService {
  // Calculate and update relationship health for all contacts
  static Future<void> updateRelationshipHealth(String userId) async {
    final contacts = await SupabaseService.getContacts(userId);
    
    for (final contactData in contacts) {
      final contact = Contact.fromJson(contactData);
      final daysSinceContact = contact.lastContactedAt != null
          ? DateTime.now().difference(contact.lastContactedAt!).inDays
          : 0;
      
      // Decay rate: 1% per day
      final health = (100 - (daysSinceContact * 1.0)).clamp(0, 100).toInt();
      
      await SupabaseService.updateContact(contact.id, {
        'relationship_health': health,
      });
    }
  }

  // Update streak count
  static Future<void> updateStreak(String userId) async {
    final user = await SupabaseService.getCurrentUser();
    if (user == null) return;

    // Check if user had an interaction today
    final today = DateTime.now();
    final contacts = await SupabaseService.getContacts(userId);
    
    bool hasInteractionToday = contacts.any((contactData) {
      final contact = Contact.fromJson(contactData);
      if (contact.lastContactedAt == null) return false;
      
      final lastContactDate = contact.lastContactedAt!;
      return lastContactDate.year == today.year &&
          lastContactDate.month == today.month &&
          lastContactDate.day == today.day;
    });

    if (hasInteractionToday) {
      // Increment streak (this would be handled by backend cron job in production)
      // For now, we'll just track it locally
    }
  }

  // Get contacts that need attention (health < 50)
  static Future<List<Contact>> getContactsNeedingAttention(String userId) async {
    final contactsData = await SupabaseService.getContacts(userId);
    final contacts = contactsData
        .map((json) => Contact.fromJson(json))
        .where((contact) => contact.relationshipHealth < 50)
        .toList();
    
    return contacts;
  }
}
