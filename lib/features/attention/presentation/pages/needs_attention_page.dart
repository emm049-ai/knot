import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/knot_app_bar.dart';

class NeedsAttentionPage extends StatefulWidget {
  const NeedsAttentionPage({super.key});

  @override
  State<NeedsAttentionPage> createState() => _NeedsAttentionPageState();
}

class _NeedsAttentionPageState extends State<NeedsAttentionPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return;
      final attention = await GamificationService.getContactsNeedingAttention(user.id);
      setState(() {
        _contacts = attention.map((c) => c.toJson()).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Needs Attention',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(
                  child: Text('No contacts need attention right now.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final name = contact['name']?.toString() ?? 'Unknown';
                    final task = _buildTaskText(contact);
                    return Card(
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text(task),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/contacts/${contact['id']}'),
                      ),
                    );
                  },
                ),
    );
  }

  String _buildTaskText(Map<String, dynamic> contact) {
    final lastContactedRaw = contact['last_contacted_at']?.toString();
    if (lastContactedRaw == null || lastContactedRaw.isEmpty) {
      return 'Reach out and log the first interaction.';
    }
    final lastContacted = DateTime.tryParse(lastContactedRaw);
    if (lastContacted == null) {
      return 'Follow up and add a note.';
    }
    final days = DateTime.now().difference(lastContacted).inDays;
    if (days >= 60) {
      return 'High priority: reconnect (last contacted $days days ago).';
    }
    if (days >= 30) {
      return 'Follow up soon (last contacted $days days ago).';
    }
    return 'Check in and record updates.';
  }
}
