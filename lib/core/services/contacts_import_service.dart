import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'supabase_service.dart';
import '../models/contact_model.dart' as app_models;

class ContactsImportService {
  // Import from device contacts
  static Future<List<app_models.Contact>> importFromDevice() async {
    // Request permission
    final permission = await Permission.contacts.request();
    if (!permission.isGranted) {
      throw Exception('Contacts permission not granted');
    }

    // Get all contacts
    final deviceContacts = await FlutterContacts.getContacts(withProperties: true);
    
    // Convert to app contacts
    final List<app_models.Contact> contacts = [];
    final user = await SupabaseService.getCurrentUser();
    if (user == null) throw Exception('User not logged in');

    for (final deviceContact in deviceContacts) {
      if (deviceContact.displayName.isNotEmpty) {
        final contact = app_models.Contact(
          id: '', // Will be set when saved
          userId: user.id,
          name: deviceContact.displayName,
          email: deviceContact.emails.isNotEmpty
              ? deviceContact.emails.first.address
              : null,
          phone: deviceContact.phones.isNotEmpty
              ? deviceContact.phones.first.number
              : null,
          createdAt: DateTime.now(),
        );
        contacts.add(contact);
      }
    }

    return contacts;
  }

  // Import single contact from device
  static Future<app_models.Contact?> importSingleContact(Contact deviceContact) async {
    final user = await SupabaseService.getCurrentUser();
    if (user == null) return null;

    if (deviceContact.displayName.isEmpty) {
      return null;
    }

    return app_models.Contact(
      id: '',
      userId: user.id,
      name: deviceContact.displayName,
      email: deviceContact.emails.isNotEmpty
          ? deviceContact.emails.first.address
          : null,
      phone: deviceContact.phones.isNotEmpty
          ? deviceContact.phones.first.number
          : null,
      createdAt: DateTime.now(),
    );
  }

  // Batch import contacts to database
  static Future<int> batchImportContacts(List<app_models.Contact> contacts) async {
    final user = await SupabaseService.getCurrentUser();
    if (user == null) throw Exception('User not logged in');

    int imported = 0;
    for (final contact in contacts) {
      try {
        await SupabaseService.createContact(user.id, {
          'name': contact.name,
          'email': contact.email,
          'phone': contact.phone,
          'company': contact.company,
          'job_title': contact.jobTitle,
        });
        imported++;
      } catch (e) {
        print('Error importing contact ${contact.name}: $e');
      }
    }

    return imported;
  }
}
