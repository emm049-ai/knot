import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/knot_app_bar.dart';

class ImportContactsPage extends StatelessWidget {
  const ImportContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Import Contacts',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose Import Source',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Select where your contact information is coming from',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // LinkedIn Import
          _buildImportOption(
            context,
            icon: Icons.business,
            title: 'LinkedIn',
            description: 'Import from LinkedIn profile URL or OAuth',
            color: AppTheme.primaryIndigo,
            onTap: () => context.push('/import/linkedin'),
          ),
          
          const SizedBox(height: 12),
          
          // Written Notes Import
          _buildImportOption(
            context,
            icon: Icons.note,
            title: 'Written Notes',
            description: 'Scan handwritten notes with OCR',
            color: AppTheme.growthGreen,
            onTap: () => context.push('/import/written-notes'),
          ),
          
          const SizedBox(height: 12),
          
          // Business Card Import
          _buildImportOption(
            context,
            icon: Icons.credit_card,
            title: 'Business Card',
            description: 'Scan a business card with camera',
            color: AppTheme.primaryIndigo,
            onTap: () => context.push('/import/business-card'),
          ),
          
          const SizedBox(height: 12),
          
          // Phone Contacts Import
          _buildImportOption(
            context,
            icon: Icons.phone,
            title: 'Phone Contacts',
            description: 'Import from device contacts',
            color: AppTheme.growthGreen,
            onTap: () => context.push('/import/phone-contacts'),
          ),
          
          const SizedBox(height: 12),
          
          // Email Interactions Import
          _buildImportOption(
            context,
            icon: Icons.email,
            title: 'Email Interactions',
            description: 'Import from email history',
            color: AppTheme.alertCoral,
            onTap: () => context.push('/import/email-interactions'),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      title,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.mediumGray,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
