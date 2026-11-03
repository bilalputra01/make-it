import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressBar extends StatelessWidget {
  final String label;
  final double progress; // 0.0 to 1.0

  const ProgressBar({super.key, required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.progressLabel),
            Text('$percentage%', style: AppTextStyles.progressValue),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              backgroundColor: AppColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.progressFill,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
