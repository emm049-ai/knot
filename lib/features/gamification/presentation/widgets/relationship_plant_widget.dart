import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/relationship_health_calculator.dart';

class RelationshipPlantWidget extends StatelessWidget {
  final int health; // 0-100
  final double size;

  const RelationshipPlantWidget({
    super.key,
    required this.health,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final status = RelationshipHealthCalculator.getHealthStatus(health);
    final emoji = RelationshipHealthCalculator.getHealthEmoji(health);

    Color plantColor;
    String plantText;
    
    switch (status) {
      case 'blooming':
        plantColor = AppTheme.growthGreen;
        plantText = '🌺';
        break;
      case 'healthy':
        plantColor = AppTheme.growthGreen;
        plantText = '🌿';
        break;
      case 'wilting':
        plantColor = AppTheme.alertCoral;
        plantText = '🍂';
        break;
      case 'dead':
        plantColor = AppTheme.mediumGray;
        plantText = '💀';
        break;
      default:
        plantColor = AppTheme.growthGreen;
        plantText = '🌱';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: plantColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              plantText,
              style: TextStyle(fontSize: size * 0.6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$health%',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: plantColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          status.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mediumGray,
              ),
        ),
      ],
    );
  }
}
