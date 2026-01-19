import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final int completeness; // 0-100
  final VoidCallback onTap;

  const ProfileAvatarWidget({
    super.key,
    required this.completeness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress indicator
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: completeness / 100,
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completeness == 100 
                      ? AppTheme.growthGreen 
                      : AppTheme.primaryIndigo,
                ),
              ),
            ),
            // Percentage text
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$completeness%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGray.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
