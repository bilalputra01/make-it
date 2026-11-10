enum TaskPriority { high, medium, low }

enum TaskSchedule { today, upcoming, anytime }

class TaskLabel {
  final String name;
  final int colorValue;

  const TaskLabel({required this.name, required this.colorValue});

  factory TaskLabel.fromJson(Map<String, dynamic> json) => TaskLabel(
    name: json['name'] as String,
    colorValue: json['colorValue'] as int,
  );

  Map<String, dynamic> toJson() => {'name': name, 'colorValue': colorValue};
}

class Task {
  final String id;
  final String title;
  final TaskLabel label;
  final int durationMinutes;
  final TaskPriority priority;
  final bool isCompleted;
  final TaskSchedule schedule;
  final DateTime? dueDate;
  final List<int> repeatDays;

  const Task({
    required this.id,
    required this.title,
    required this.label,
    required this.durationMinutes,
    required this.priority,
    this.isCompleted = false,
    this.schedule = TaskSchedule.today,
    this.dueDate,
    this.repeatDays = const [],
  });

  Task copyWith({bool? isCompleted}) {
    return Task(
      id: id,
      title: title,
      label: label,
      durationMinutes: durationMinutes,
      priority: priority,
      isCompleted: isCompleted ?? this.isCompleted,
      schedule: schedule,
      dueDate: dueDate,
      repeatDays: repeatDays,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final label = json['label'] as Map<String, dynamic>;
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      label: TaskLabel.fromJson(label),
      durationMinutes: json['durationMinutes'] as int,
      priority: TaskPriority.values.byName(json['priority'] as String),
      isCompleted: json['isCompleted'] as bool,
      schedule: TaskSchedule.values.byName(json['schedule'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      repeatDays: (json['repeatDays'] as List<dynamic>? ?? const [])
          .map((day) => day as int)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'label': label.toJson(),
    'durationMinutes': durationMinutes,
    'priority': priority.name,
    'isCompleted': isCompleted,
    'schedule': schedule.name,
    'dueDate': dueDate?.toIso8601String(),
    'repeatDays': repeatDays,
  };

  String get durationText {
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      return mins > 0 ? '$hours j $mins m' : '$hours j';
    }
    return '$durationMinutes m';
  }

  String get priorityText {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }
}
