import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/contacts/presentation/pages/contacts_list_page.dart';
import '../../features/contacts/presentation/pages/contact_detail_page.dart';
import '../../features/capture/presentation/pages/capture_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/import/presentation/pages/import_contacts_page.dart';
import '../../features/import/presentation/pages/linkedin_import_page.dart';
import '../../features/import/presentation/pages/written_notes_import_page.dart';
import '../../features/import/presentation/pages/business_card_import_page.dart';
import '../../features/import/presentation/pages/phone_contacts_import_page.dart';
import '../../features/import/presentation/pages/email_interactions_import_page.dart';
import '../../features/actions/presentation/pages/add_contact_options_page.dart';
import '../../features/actions/presentation/pages/create_message_page.dart';
import '../../features/actions/presentation/pages/record_interaction_page.dart';
import '../../features/actions/presentation/pages/pre_meeting_page.dart';
import '../../features/actions/presentation/pages/search_actions_page.dart';
import '../../features/stats/presentation/pages/usage_stats_page.dart';
import '../../features/attention/presentation/pages/needs_attention_page.dart';
import '../../features/profile/presentation/pages/profile_building_page.dart';
import '../../features/profile/presentation/pages/my_profile_page.dart';
import '../../features/profile/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/no_questions_page.dart';
import '../../core/services/user_profile_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isGoingToAuth = state.matchedLocation == '/login' || 
                           state.matchedLocation == '/signup';

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !isGoingToAuth) {
        return '/login';
      }

      // If logged in and trying to access auth pages
      if (isLoggedIn && isGoingToAuth) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
        redirect: (context, state) async {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            final needsOnboarding = await UserProfileService.needsOnboarding(user.id);
            if (needsOnboarding) {
              return '/onboarding';
            }
          }
          return null;
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsListPage(),
      ),
      GoRoute(
        path: '/contacts/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ContactDetailPage(contactId: id);
        },
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) {
          // Check for pre-filled data from import
          final extra = state.extra as Map<String, dynamic>?;
          return CapturePage(prefillData: extra);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportContactsPage(),
      ),
      GoRoute(
        path: '/import/linkedin',
        builder: (context, state) => const LinkedInImportPage(),
      ),
      GoRoute(
        path: '/import/written-notes',
        builder: (context, state) => const WrittenNotesImportPage(),
      ),
      GoRoute(
        path: '/import/business-card',
        builder: (context, state) => const BusinessCardImportPage(),
      ),
      GoRoute(
        path: '/import/phone-contacts',
        builder: (context, state) => const PhoneContactsImportPage(),
      ),
      GoRoute(
        path: '/import/email-interactions',
        builder: (context, state) => const EmailInteractionsImportPage(),
      ),
      GoRoute(
        path: '/actions/add-contact',
        builder: (context, state) => const AddContactOptionsPage(),
      ),
      GoRoute(
        path: '/actions/create-message',
        builder: (context, state) => const CreateMessagePage(),
      ),
      GoRoute(
        path: '/actions/record-interaction',
        builder: (context, state) => const RecordInteractionPage(),
      ),
      GoRoute(
        path: '/actions/pre-meeting',
        builder: (context, state) => const PreMeetingPage(),
      ),
      GoRoute(
        path: '/actions/search',
        builder: (context, state) => const SearchActionsPage(),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const UsageStatsPage(),
      ),
      GoRoute(
        path: '/needs-attention',
        builder: (context, state) => const NeedsAttentionPage(),
      ),
      GoRoute(
        path: '/profile/build',
        builder: (context, state) => const ProfileBuildingPage(),
      ),
      GoRoute(
        path: '/profile/view',
        builder: (context, state) => const MyProfilePage(),
      ),
      GoRoute(
        path: '/profile/no-questions',
        builder: (context, state) => const NoQuestionsPage(),
      ),
    ],
  );
}
