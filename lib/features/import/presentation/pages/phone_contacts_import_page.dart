import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/contacts_import_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/knot_app_bar.dart';

class PhoneContactsImportPage extends StatefulWidget {
  const PhoneContactsImportPage({super.key});

  @override
  State<PhoneContactsImportPage> createState() => _PhoneContactsImportPageState();
}

class _PhoneContactsImportPageState extends State<PhoneContactsImportPage> {
  bool _isLoading = false;
  bool _isImporting = false;
  List<Contact> _deviceContacts = [];
  Set<int> _selectedIndices = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      // Phone contacts are not supported on web
      if (kIsWeb) {
        throw Exception('Phone contacts import is not supported on web. Please use this feature on a mobile device.');
      }
      
      // Request permission first
      final permission = await Permission.contacts.request();
      if (!permission.isGranted) {
        throw Exception('Contacts permission not granted');
      }
      
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        _deviceContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  Future<void> _importSelected() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    setState(() => _isImporting = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      int imported = 0;
      String? lastError;
      for (final index in _selectedIndices) {
        final deviceContact = _deviceContacts[index];
        if (deviceContact.displayName.isNotEmpty) {
          try {
            await SupabaseService.createContact(user.id, {
              'name': deviceContact.displayName,
              'email': deviceContact.emails.isNotEmpty
                  ? deviceContact.emails.first.address
                  : null,
              'phone': deviceContact.phones.isNotEmpty
                  ? deviceContact.phones.first.number
                  : null,
            });
            imported++;
          } catch (e) {
            lastError = e.toString();
            print('Error importing ${deviceContact.displayName}: $e');
            // Continue with other contacts even if one fails
          }
        }
      }

      setState(() => _isImporting = false);
      
      if (mounted) {
        if (imported > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported $imported contact(s) successfully!'),
              backgroundColor: AppTheme.growthGreen,
            ),
          );
          context.go('/contacts');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to import contacts. ${lastError ?? "Unknown error"}'),
              backgroundColor: AppTheme.alertCoral,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isImporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing contacts: $e')),
        );
      }
    }
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) return _deviceContacts;
    return _deviceContacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final email = contact.emails.isNotEmpty
          ? contact.emails.first.address.toLowerCase()
          : '';
      final phone = contact.phones.isNotEmpty
          ? contact.phones.first.number
          : '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Import from Phone Contacts',
        extraActions: [
          if (_selectedIndices.isNotEmpty)
            TextButton(
              onPressed: _isImporting ? null : _importSelected,
              child: Text(
                'Import (${_selectedIndices.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search contacts',
                hintText: 'Search by name, email, or phone',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Contact List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contacts_outlined,
                              size: 64,
                              color: AppTheme.mediumGray,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No contacts found'
                                  : 'No contacts match your search',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          final originalIndex = _deviceContacts.indexOf(contact);
                          final isSelected = _selectedIndices.contains(originalIndex);
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1),
                              child: Text(
                                (contact.displayName.isNotEmpty ? contact.displayName[0] : '?').toUpperCase(),
                                style: TextStyle(
                                  color: AppTheme.primaryIndigo,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(contact.displayName.isNotEmpty ? contact.displayName : 'Unknown'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (contact.emails.isNotEmpty)
                                  Text(contact.emails.first.address),
                                if (contact.phones.isNotEmpty)
                                  Text(contact.phones.first.number),
                              ],
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedIndices.add(originalIndex);
                                  } else {
                                    _selectedIndices.remove(originalIndex);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIndices.remove(originalIndex);
                                } else {
                                  _selectedIndices.add(originalIndex);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
          
          // Import Button
          if (_selectedIndices.isNotEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isImporting ? null : _importSelected,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isImporting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Import ${_selectedIndices.length} Contact(s)'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
