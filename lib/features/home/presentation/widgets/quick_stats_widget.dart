import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/models/contact_model.dart';

class QuickStatsWidget extends StatefulWidget {
  final bool compact;
  final VoidCallback? onTotalContactsTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onNeedsAttentionTap;

  const QuickStatsWidget({
    super.key,
    this.compact = false,
    this.onTotalContactsTap,
    this.onStreakTap,
    this.onNeedsAttentionTap,
  });

  @override
  State<QuickStatsWidget> createState() => _QuickStatsWidgetState();
}

class _QuickStatsWidgetState extends State<QuickStatsWidget> {
  int _totalContacts = 0;
  int _streakCount = 0;
  int _needsAttention = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final contacts = await SupabaseService.getContacts(user.id);
      final contactsNeedingAttention =
          await GamificationService.getContactsNeedingAttention(user.id);
      final profile = await SupabaseService.getUserProfile(user.id);

      setState(() {
        _totalContacts = contacts.length;
        _needsAttention = contactsNeedingAttention.length;
        _streakCount = (profile?['streak_count'] as int?) ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCompactStat(
            context,
            Icons.people,
            '$_totalContacts',
            AppTheme.primaryIndigo,
            widget.onTotalContactsTap,
          ),
          _buildCompactStat(
            context,
            Icons.local_fire_department,
            '$_streakCount',
            AppTheme.accentAmber,
            widget.onStreakTap,
          ),
          _buildCompactStat(
            context,
            Icons.warning,
            '$_needsAttention',
            AppTheme.alertCoral,
            widget.onNeedsAttentionTap,
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildStatCard(
          context,
          'Total Contacts',
          '$_totalContacts',
          Icons.people,
          AppTheme.primaryIndigo,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          context,
          'Active Streak',
          '$_streakCount days',
          Icons.local_fire_department,
          AppTheme.growthGreen,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          context,
          'Needs Attention',
          '$_needsAttention',
          Icons.warning,
          AppTheme.alertCoral,
        ),
      ],
    );
  }

  Widget _buildCompactStat(
    BuildContext context,
    IconData icon,
    String value,
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
