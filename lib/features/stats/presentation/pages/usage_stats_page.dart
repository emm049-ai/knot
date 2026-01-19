import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/knot_app_bar.dart';

class UsageStatsPage extends StatefulWidget {
  const UsageStatsPage({super.key});

  @override
  State<UsageStatsPage> createState() => _UsageStatsPageState();
}

class _UsageStatsPageState extends State<UsageStatsPage> {
  bool _isLoading = true;
  int _totalContacts = 0;
  int _streakCount = 0;
  int _needsAttention = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return;
      final contacts = await SupabaseService.getContacts(user.id);
      final attention = await GamificationService.getContactsNeedingAttention(user.id);
      final profile = await SupabaseService.getUserProfile(user.id);
      setState(() {
        _totalContacts = contacts.length;
        _needsAttention = attention.length;
        _streakCount = (profile?['streak_count'] as int?) ?? 0;
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
        titleText: 'Usage Stats',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statTile(
                  context,
                  icon: Icons.people,
                  label: 'Total Contacts',
                  value: '$_totalContacts',
                  color: AppTheme.primaryIndigo,
                ),
                const SizedBox(height: 12),
                _statTile(
                  context,
                  icon: Icons.local_fire_department,
                  label: 'Active Streak',
                  value: '$_streakCount days',
                  color: AppTheme.accentAmber,
                ),
                const SizedBox(height: 12),
                _statTile(
                  context,
                  icon: Icons.warning,
                  label: 'Needs Attention',
                  value: '$_needsAttention',
                  color: AppTheme.alertCoral,
                ),
              ],
            ),
    );
  }

  Widget _statTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.displaySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
