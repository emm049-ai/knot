import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/knot_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  String? _bccEmail;
  bool _notificationsEnabled = true;
  bool _callTipsEnabled = true;
  bool _callTipsIncludeLastInteraction = true;
  bool _callTipsIncludeAdvice = true;
  bool _calendarSyncEnabled = false;
  bool _calendarSyncFollowups = true;
  bool _calendarSyncBirthdays = true;
  bool _calendarSyncUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      await SupabaseService.ensureUserExists(user.id);
      final profile = await SupabaseService.getUserProfile(user.id);
      setState(() {
        _bccEmail = profile?['bcc_email'] as String?;
        _notificationsEnabled =
            (profile?['notifications_enabled'] as bool?) ?? true;
        _callTipsEnabled = (profile?['call_tips_enabled'] as bool?) ?? true;
        _callTipsIncludeLastInteraction =
            (profile?['call_tips_include_last_interaction'] as bool?) ?? true;
        _callTipsIncludeAdvice =
            (profile?['call_tips_include_advice'] as bool?) ?? true;
        _calendarSyncEnabled =
            (profile?['calendar_sync_enabled'] as bool?) ?? false;
        _calendarSyncFollowups =
            (profile?['calendar_sync_followups'] as bool?) ?? true;
        _calendarSyncBirthdays =
            (profile?['calendar_sync_birthdays'] as bool?) ?? true;
        _calendarSyncUpdates =
            (profile?['calendar_sync_updates'] as bool?) ?? true;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final user = await SupabaseService.getCurrentUser();
    if (user == null) return;
    try {
      await SupabaseService.updateUserProfile(user.id, {key: value});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save setting.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Settings',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder(
                          future: SupabaseService.getCurrentUser(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Text(snapshot.data!.email ?? 'No email');
                            }
                            return const Text('Not logged in');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        subtitle: const Text(
                          'Show tips when you enter a call',
                        ),
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                            _updateSetting('notifications_enabled', value);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _callTipsEnabled,
                        onChanged: _notificationsEnabled
                            ? (value) {
                                setState(() => _callTipsEnabled = value);
                                _updateSetting('call_tips_enabled', value);
                              }
                            : null,
                        title: const Text('Call tips'),
                        subtitle: const Text(
                          'Get reminders right before a call begins',
                        ),
                      ),
                      SwitchListTile(
                        value: _callTipsIncludeLastInteraction,
                        onChanged: (_notificationsEnabled && _callTipsEnabled)
                            ? (value) {
                                setState(() =>
                                    _callTipsIncludeLastInteraction = value);
                                _updateSetting(
                                  'call_tips_include_last_interaction',
                                  value,
                                );
                              }
                            : null,
                        title: const Text('Include last interaction'),
                        subtitle: const Text(
                          'Pull in the latest notes or messages',
                        ),
                      ),
                      SwitchListTile(
                        value: _callTipsIncludeAdvice,
                        onChanged: (_notificationsEnabled && _callTipsEnabled)
                            ? (value) {
                                setState(() =>
                                    _callTipsIncludeAdvice = value);
                                _updateSetting(
                                  'call_tips_include_advice',
                                  value,
                                );
                              }
                            : null,
                        title: const Text('Include next-step advice'),
                        subtitle: const Text(
                          'Suggested approach for the conversation',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.calendar_today),
                        value: _calendarSyncEnabled,
                        onChanged: (value) {
                          setState(() => _calendarSyncEnabled = value);
                          _updateSetting('calendar_sync_enabled', value);
                        },
                        title: const Text('Calendar Sync'),
                        subtitle: const Text(
                          'Sync follow-ups, birthdays, and updates',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _calendarSyncFollowups,
                        onChanged: _calendarSyncEnabled
                            ? (value) {
                                setState(() =>
                                    _calendarSyncFollowups = value);
                                _updateSetting(
                                  'calendar_sync_followups',
                                  value,
                                );
                              }
                            : null,
                        title: const Text('Follow-up reminders'),
                        subtitle: const Text('Auto-create follow-up events'),
                      ),
                      SwitchListTile(
                        value: _calendarSyncBirthdays,
                        onChanged: _calendarSyncEnabled
                            ? (value) {
                                setState(() =>
                                    _calendarSyncBirthdays = value);
                                _updateSetting(
                                  'calendar_sync_birthdays',
                                  value,
                                );
                              }
                            : null,
                        title: const Text('Birthdays'),
                        subtitle:
                            const Text('Add contact birthdays to calendar'),
                      ),
                      SwitchListTile(
                        value: _calendarSyncUpdates,
                        onChanged: _calendarSyncEnabled
                            ? (value) {
                                setState(() => _calendarSyncUpdates = value);
                                _updateSetting(
                                  'calendar_sync_updates',
                                  value,
                                );
                              }
                            : null,
                        title: const Text('Updates & milestones'),
                        subtitle: const Text('Sync milestones and events'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('BCC Email'),
                    subtitle: Text(
                      _bccEmail == null
                          ? 'Coming soon'
                          : 'Coming soon · $_bccEmail',
                    ),
                    trailing: const Icon(Icons.lock, color: AppTheme.mediumGray),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('About'),
                        subtitle: const Text('Version 1.0.0'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('Terms of Service'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: () async {
                      await SupabaseService.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.alertCoral,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
    );
  }
}
