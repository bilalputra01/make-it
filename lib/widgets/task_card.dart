import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  const TaskCard({super.key, required this.task, this.onTap, this.onToggle});

  String? get _labelAsset {
    switch (task.label.name.toLowerCase()) {
      case 'kuliah':
        return 'assets/figma/label-kuliah.svg';
      case 'kerja':
        return 'assets/figma/label-kerja.svg';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelAsset = _labelAsset;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            key: ValueKey('task-card-${task.id}'),
            constraints: const BoxConstraints(minHeight: 53),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _priorityColor(task.priority),
                  offset: const Offset(-2, 0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: task.isCompleted
                      ? 'Tandai ${task.title} belum selesai'
                      : 'Tandai ${task.title} selesai',
                  child: GestureDetector(
                    key: ValueKey('task-toggle-${task.id}'),
                    onTap: onToggle,
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: task.isCompleted
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 11,
                                color: Colors.white,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/figma/task-checkbox.svg',
                              width: 14,
                              height: 14,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.taskTitle.copyWith(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (labelAsset != null)
                            SvgPicture.asset(labelAsset, width: 7, height: 7)
                          else
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Color(task.label.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              task.label.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.taskMeta.copyWith(
                                color: _labelTextColor(task.label.name),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '  ·  ${task.durationText}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.taskMeta,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    task.priorityText,
                    style: AppTextStyles.priorityLabel.copyWith(
                      color: _priorityColor(task.priority),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }

  Color _labelTextColor(String label) {
    switch (label.toLowerCase()) {
      case 'kuliah':
        return const Color(0xFF2F5A42);
      case 'kerja':
        return const Color(0xFF2F5480);
      default:
        return AppColors.textSecondary;
    }
  }
}
