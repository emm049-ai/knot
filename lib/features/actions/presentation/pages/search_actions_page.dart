import 'package:flutter/material.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/knot_app_bar.dart';

class SearchActionsPage extends StatefulWidget {
  const SearchActionsPage({super.key});

  @override
  State<SearchActionsPage> createState() => _SearchActionsPageState();
}

class _SearchActionsPageState extends State<SearchActionsPage> {
  final _searchController = TextEditingController();
  final _helpController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _helpController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');
      final contacts = await SupabaseService.getContacts(user.id);
      setState(() {
        _contacts = contacts;
        _filtered = contacts;
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

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filtered = _contacts);
      return;
    }
    setState(() {
      _filtered = _contacts.where((contact) {
        final name = contact['name']?.toString().toLowerCase() ?? '';
        final company = contact['company']?.toString().toLowerCase() ?? '';
        return name.contains(query) || company.contains(query);
      }).toList();
    });
  }

  Future<void> _getSuggestions() async {
    final prompt = _helpController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a prompt for suggestions.')),
      );
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final suggestion = await AIService.generateConnectionSuggestions(
        prompt,
        _contacts,
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Suggestions'),
          content: SingleChildScrollView(child: SelectableText(suggestion)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating suggestions: $e'),
            backgroundColor: AppTheme.alertCoral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Search',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by name or company',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                if (_filtered.isEmpty)
                  const Text('No contacts found.')
                else
                  ..._filtered.map(
                    (contact) => ListTile(
                      title: Text(contact['name']?.toString() ?? ''),
                      subtitle: Text(contact['company']?.toString() ?? ''),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Need help deciding who to connect with?',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _helpController,
                  decoration: const InputDecoration(
                    labelText: 'Describe what you need',
                    hintText: 'e.g., “someone in fintech for a product intro”',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _getSuggestions,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_isGenerating ? 'Generating...' : 'Get Suggestions'),
                ),
              ],
            ),
    );
  }
}
