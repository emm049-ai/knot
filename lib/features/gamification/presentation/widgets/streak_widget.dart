import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StreakWidget extends StatelessWidget {
  final int streakCount;

  const StreakWidget({
    super.key,
    required this.streakCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.growthGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.growthGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppTheme.growthGreen,
            size: 24,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streakCount',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.growthGreen,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Day Streak',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.growthGreen,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
