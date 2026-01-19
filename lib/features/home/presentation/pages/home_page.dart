import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/quick_stats_widget.dart';
import '../../../../core/widgets/knot_app_bar.dart';
import '../../../../core/widgets/back_button_handler.dart';
import '../../../profile/presentation/widgets/profile_avatar_widget.dart';
import '../../../../core/services/user_profile_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _completeness = 0;
  bool _weeklyQuestionsReady = false;
  Map<String, int> _progress = {'answered': 0, 'total': 9};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this page
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await UserProfileService.getUserProfile(user.id);
        final weeklyReady = await UserProfileService.areWeeklyQuestionsReady(user.id);
        final progress = await UserProfileService.getOverallProgress(user.id);
        if (mounted) {
          // Calculate completeness from progress (answered/total)
          final answered = progress['answered'] ?? 0;
          final total = progress['total'] ?? 9;
          final calculatedCompleteness = total > 0 ? ((answered / total) * 100).round() : 0;
          
          setState(() {
            _completeness = calculatedCompleteness;
            _weeklyQuestionsReady = weeklyReady;
            _progress = progress;
          });
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      showExitDialog: true,
      child: Scaffold(
        appBar: KnotAppBar(
          context: context,
          titleText: 'Knot',
          titleWidget: const Text(
            'Knot',
            style: TextStyle(
              color: AppTheme.primaryIndigo,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          extraActions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.go('/settings'),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: AppTheme.offWhite,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryIndigo.withOpacity(0.22),
                AppTheme.accentTeal.withOpacity(0.22),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Weekly questions notification
              if (_weeklyQuestionsReady)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentAmber,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.quiz,
                            color: AppTheme.accentAmber,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'New questions are ready!',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentAmber,
                                  ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _weeklyQuestionsReady = false;
                              });
                            },
                            child: const Text('Later'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Answer these questions to help us give you better advice.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/profile/build'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentAmber,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Answer Questions'),
                      ),
                    ],
                  ),
                ),
              // Profile Avatar
              Center(
                child: ProfileAvatarWidget(
                  completeness: _completeness,
                  onTap: () {
                    if (_completeness == 100) {
                      context.go('/profile/no-questions');
                    } else {
                      context.go('/profile/build');
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: QuickStatsWidget(
                  compact: true,
                  onTotalContactsTap: () => context.go('/contacts'),
                  onStreakTap: () => context.go('/stats'),
                  onNeedsAttentionTap: () => context.go('/needs-attention'),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ActionTile(
                    icon: Icons.person_add,
                    label: 'Add Contact',
                    color: AppTheme.primaryIndigo,
                    onTap: () => context.go('/actions/add-contact'),
                  ),
                  _ActionTile(
                    icon: Icons.message,
                    label: 'Create Message',
                    color: AppTheme.accentTeal,
                    onTap: () => context.go('/actions/create-message'),
                  ),
                  _ActionTile(
                    icon: Icons.mic,
                    label: 'Record Interaction',
                    color: AppTheme.alertCoral,
                    onTap: () => context.go('/actions/record-interaction'),
                  ),
                  _ActionTile(
                    icon: Icons.event_note,
                    label: 'Pre-Meeting',
                    color: AppTheme.accentPurple,
                    onTap: () => context.go('/actions/pre-meeting'),
                  ),
                  _ActionTile(
                    icon: Icons.search,
                    label: 'Search',
                    color: AppTheme.growthGreen,
                    onTap: () => context.go('/actions/search'),
                  ),
                  _ActionTile(
                    icon: Icons.people,
                    label: 'All Contacts',
                    color: AppTheme.accentAmber,
                    onTap: () => context.go('/contacts'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.96),
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
