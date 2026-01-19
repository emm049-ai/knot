import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/knot_app_bar.dart';

class AddContactOptionsPage extends StatelessWidget {
  const AddContactOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnotAppBar(
        context: context,
        titleText: 'Add a Contact',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose how you want to add a contact',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You can start with the basics and build the profile over time.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _buildOption(
            context,
            icon: Icons.edit,
            title: 'Add Manually',
            description: 'Enter details yourself and build a fuller profile',
            color: AppTheme.primaryIndigo,
            onTap: () => context.push('/capture'),
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.business,
            title: 'LinkedIn',
            description: 'Import from LinkedIn profile URL or OAuth',
            color: AppTheme.primaryIndigo,
            onTap: () => context.push('/import/linkedin'),
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.credit_card,
            title: 'Business Card',
            description: 'Scan a business card with the camera',
            color: AppTheme.growthGreen,
            onTap: () => context.push('/import/business-card'),
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.note,
            title: 'Written Notes',
            description: 'Scan handwritten notes with OCR',
            color: AppTheme.growthGreen,
            onTap: () => context.push('/import/written-notes'),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
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
              const Icon(
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
