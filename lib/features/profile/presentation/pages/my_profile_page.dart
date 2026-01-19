import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/knot_app_bar.dart';
import '../../../../core/services/user_profile_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  Map<String, dynamic>? _persona;
  Map<String, Map<String, dynamic>>? _phasesStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      final profile = await UserProfileService.getUserProfile(user.id);
      _persona = profile?.persona;
      _phasesStatus = await UserProfileService.getPhasesStatus(user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editPersonaField(String key, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${key.replaceAll('_', ' ').toUpperCase()}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue != null && newValue != currentValue) {
      // Update persona in database
      try {
        final user = await SupabaseService.getCurrentUser();
        if (user == null) return;

        final updatedPersona = Map<String, dynamic>.from(_persona ?? {});
        updatedPersona[key] = newValue;

        await Supabase.instance.client
            .from('users')
            .update({'profile_persona': updatedPersona})
            .eq('id', user.id);

        setState(() => _persona = updatedPersona);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Updated!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'My Profile',
        extraActions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/profile/build'),
            tooltip: 'Build Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile completeness summary
                  if (_phasesStatus != null) ...[
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Completeness',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ..._phasesStatus!.entries.map((entry) {
                              final phase = entry.key;
                              final status = entry.value;
                              final completeness = status['completeness'] ?? 0;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _getPhaseName(phase),
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        Text(
                                          '$completeness%',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryIndigo,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: completeness / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryIndigo,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // What I know about you
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'What I Know About You',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () async {
                                  final user = await SupabaseService.getCurrentUser();
                                  if (user != null) {
                                    await UserProfileService.updatePersona(user.id);
                                    await _loadProfile();
                                  }
                                },
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_persona == null || _persona!.isEmpty)
                            Text(
                              'Complete your profile to see what I know about you!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            )
                          else
                            ..._persona!.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key.replaceAll('_', ' ').toUpperCase(),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppTheme.primaryIndigo,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          onPressed: () => _editPersonaField(
                                            entry.key,
                                            entry.value.toString(),
                                          ),
                                          tooltip: 'Edit',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.value.toString(),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getPhaseName(String phase) {
    const names = {
      'basic_info': 'Basic Info',
      'goals': 'Goals & Aspirations',
      'communication_style': 'Communication Style',
      'interests': 'Interests & Hobbies',
      'work_education': 'Work & Education',
    };
    return names[phase] ?? phase;
  }
}
