import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/contact_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/knot_app_bar.dart';
import '../widgets/contact_card.dart';

class ContactsListPage extends StatefulWidget {
  const ContactsListPage({super.key});

  @override
  State<ContactsListPage> createState() => _ContactsListPageState();
}

class _ContactsListPageState extends State<ContactsListPage> {
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final contactsData = await SupabaseService.getContacts((await user)!.id);
      setState(() {
        _contacts = contactsData.map((json) => Contact.fromJson(json)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Contacts',
        extraActions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => context.go('/import'),
            tooltip: 'Import Contacts',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/capture'),
            tooltip: 'Add Contact',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No contacts yet',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => context.go('/capture'),
                        child: const Text('Add Your First Contact'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadContacts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ContactCard(
                          contact: contact,
                          onTap: () => context.go('/contacts/${contact.id}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
