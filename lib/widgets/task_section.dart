import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import 'task_card.dart';

class TaskSection extends StatelessWidget {
  final String title;
  final int count;
  final List<Task> tasks;
  final bool showInput;
  final bool isCollapsible;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final Function(Task)? onTaskToggle;
  final VoidCallback? onAddTask;

  const TaskSection({
    super.key,
    required this.title,
    required this.count,
    required this.tasks,
    this.showInput = false,
    this.isCollapsible = false,
    this.isExpanded = true,
    this.onToggleExpand,
    this.onTaskToggle,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 166),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: isCollapsible ? onToggleExpand : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Text(title, style: AppTextStyles.sectionHeader),
                  const Spacer(),
                  Text('$count', style: AppTextStyles.sectionCount),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            for (var index = 0; index < tasks.length; index++) ...[
              TaskCard(
                task: tasks[index],
                onToggle: () => onTaskToggle?.call(tasks[index]),
              ),
              if (index < tasks.length - 1 || showInput)
                const SizedBox(height: 8),
            ],
            if (showInput) _buildAddTaskButton(),
            if (tasks.isEmpty && !showInput)
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 4, 10, 8),
                child: Text('Belum ada tugas.', style: AppTextStyles.taskMeta),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddTaskButton() {
    return InkWell(
      onTap: onAddTask,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        child: Row(
          children: [
            Image.asset('assets/figma/add-task.png', width: 14, height: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tulis tugas baru',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.inputHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
