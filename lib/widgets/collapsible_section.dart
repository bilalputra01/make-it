import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CollapsibleSection extends StatelessWidget {
  final String title;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget? child;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Text(
                  isExpanded ? '▾' : '▸',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.expandableSection),
                const Spacer(),
                Text(count.toString(), style: AppTextStyles.sectionCount),
              ],
            ),
          ),
        ),
        if (isExpanded && child != null) child!,
      ],
    );
  }
}
