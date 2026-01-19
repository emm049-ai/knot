import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/contact_model.dart';
import '../../../../core/utils/relationship_health_calculator.dart';
import 'package:intl/intl.dart';

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final health = RelationshipHealthCalculator.calculateHealth(contact);
    final healthStatus = RelationshipHealthCalculator.getHealthStatus(health);
    final healthEmoji = RelationshipHealthCalculator.getHealthEmoji(health);

    Color healthColor;
    switch (healthStatus) {
      case 'blooming':
        healthColor = AppTheme.growthGreen;
        break;
      case 'healthy':
        healthColor = AppTheme.growthGreen;
        break;
      case 'wilting':
        healthColor = AppTheme.alertCoral;
        break;
      default:
        healthColor = AppTheme.mediumGray;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1),
                child: Text(
                  contact.name[0].toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primaryIndigo,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    if (contact.company != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        contact.company!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (contact.lastContactedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last contacted: ${DateFormat('MMM d, y').format(contact.lastContactedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Health Indicator
              Column(
                children: [
                  Text(
                    healthEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: health / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: healthColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
