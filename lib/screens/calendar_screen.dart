import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';

enum _CalendarPeriod { week, month, year }

class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final ValueChanged<Task> onTaskToggle;
  final ValueChanged<Task> onTaskEdit;
  final ValueChanged<Task> onTaskDelete;

  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.onTaskToggle,
    required this.onTaskEdit,
    required this.onTaskDelete,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  static const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _weekdayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  _CalendarPeriod _period = _CalendarPeriod.week;
  Set<String>? _selectedLabels;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  List<Task> get _visibleTasks {
    final selectedLabels = _selectedLabels;
    if (selectedLabels == null) return widget.tasks;
    return widget.tasks
        .where((task) => selectedLabels.contains(task.label.name))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _today;
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  DateTime _weekStart(DateTime date) =>
      _dateOnly(date).subtract(Duration(days: date.weekday - 1));

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month);

  DateTime _periodStart(DateTime date, _CalendarPeriod period) {
    switch (period) {
      case _CalendarPeriod.week:
        return _weekStart(date);
      case _CalendarPeriod.month:
        return _monthStart(date);
      case _CalendarPeriod.year:
        return DateTime(date.year);
    }
  }

  DateTime _periodEnd(DateTime start, _CalendarPeriod period) {
    switch (period) {
      case _CalendarPeriod.week:
        return start.add(const Duration(days: 7));
      case _CalendarPeriod.month:
        return DateTime(start.year, start.month + 1);
      case _CalendarPeriod.year:
        return DateTime(start.year + 1);
    }
  }

  DateTime _previousPeriodStart(DateTime start, _CalendarPeriod period) {
    switch (period) {
      case _CalendarPeriod.week:
        return start.subtract(const Duration(days: 7));
      case _CalendarPeriod.month:
        return DateTime(start.year, start.month - 1);
      case _CalendarPeriod.year:
        return DateTime(start.year - 1);
    }
  }

  List<Task> _tasksOnDate(DateTime date) {
    final targetDate = _dateOnly(date);
    return _visibleTasks
        .where((task) => _taskOccursOn(task, targetDate))
        .toList();
  }

  bool _taskOccursOn(Task task, DateTime date) {
    final dueDate = task.dueDate == null ? null : _dateOnly(task.dueDate!);

    if (task.repeatDays.isNotEmpty) {
      if (task.isCompleted) {
        return dueDate == null
            ? _isSameDate(date, _today)
            : _isSameDate(date, dueDate);
      }
      if (dueDate != null && date.isBefore(dueDate)) return false;
      return task.repeatDays.contains(date.weekday);
    }

    if (dueDate != null) return _isSameDate(date, dueDate);
    return task.schedule == TaskSchedule.today && _isSameDate(date, _today);
  }

  int _completedMinutesOn(DateTime date) {
    return _tasksOnDate(date)
        .where((task) => task.isCompleted)
        .fold(0, (total, task) => total + task.durationMinutes);
  }

  int _minutesBetween(DateTime start, DateTime end) {
    var total = 0;
    for (
      var date = start;
      date.isBefore(end);
      date = date.add(const Duration(days: 1))
    ) {
      total += _completedMinutesOn(date);
    }
    return total;
  }

  int _activeDaysBetween(DateTime start, DateTime end) {
    var activeDays = 0;
    for (
      var date = start;
      date.isBefore(end);
      date = date.add(const Duration(days: 1))
    ) {
      if (_completedMinutesOn(date) > 0) activeDays++;
    }
    return activeDays;
  }

  List<Task> _completedTasksOnDate(DateTime date) {
    return _tasksOnDate(date).where((task) => task.isCompleted).toList();
  }

  List<_ChartPoint> _chartPoints(DateTime start, DateTime end) {
    switch (_period) {
      case _CalendarPeriod.week:
        return List.generate(7, (index) {
          final date = start.add(Duration(days: index));
          return _ChartPoint(
            label: _weekdayNames[date.weekday - 1].substring(0, 1),
            minutes: _completedMinutesOn(date),
          );
        });
      case _CalendarPeriod.month:
        final firstWeekday = start.weekday - 1;
        final rowCount = ((firstWeekday + end.difference(start).inDays) / 7)
            .ceil();
        return List.generate(rowCount, (index) {
          final weekStart = start.add(Duration(days: index * 7 - firstWeekday));
          final weekEnd = weekStart.add(const Duration(days: 7));
          final rangeStart = weekStart.isBefore(start) ? start : weekStart;
          final rangeEnd = weekEnd.isAfter(end) ? end : weekEnd;
          return _ChartPoint(
            label: '${index + 1}',
            minutes: _minutesBetween(rangeStart, rangeEnd),
          );
        });
      case _CalendarPeriod.year:
        return List.generate(12, (index) {
          final monthStart = DateTime(start.year, index + 1);
          final monthEnd = DateTime(start.year, index + 2);
          return _ChartPoint(
            label: _shortMonths[index],
            minutes: _minutesBetween(monthStart, monthEnd),
          );
        });
    }
  }

  String _durationText(int minutes) {
    if (minutes == 0) return '0 m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '$remainingMinutes m';
    if (remainingMinutes == 0) return '$hours j';
    return '$hours j $remainingMinutes m';
  }

  String _periodTitle(DateTime start) {
    switch (_period) {
      case _CalendarPeriod.week:
        final end = start.add(const Duration(days: 6));
        if (start.month == end.month) {
          return '${start.day} – ${end.day} ${_shortMonths[end.month - 1]}';
        }
        return '${start.day} ${_shortMonths[start.month - 1]} – '
            '${end.day} ${_shortMonths[end.month - 1]}';
      case _CalendarPeriod.month:
        return '${_months[start.month - 1]} ${start.year}';
      case _CalendarPeriod.year:
        return '${start.year}';
    }
  }

  String _periodDescription() {
    switch (_period) {
      case _CalendarPeriod.week:
        return 'Estimasi durasi tugas yang selesai minggu ini';
      case _CalendarPeriod.month:
        return 'Estimasi durasi tugas yang selesai bulan ini';
      case _CalendarPeriod.year:
        return 'Estimasi durasi tugas yang selesai tahun ini';
    }
  }

  String _comparisonText(int current, int previous) {
    final previousPeriod = switch (_period) {
      _CalendarPeriod.week => 'minggu lalu',
      _CalendarPeriod.month => 'bulan lalu',
      _CalendarPeriod.year => 'tahun lalu',
    };
    if (current == previous) return 'Sama seperti $previousPeriod';
    if (previous == 0) {
      return current == 0
          ? 'Belum ada tugas selesai di periode ini'
          : 'Mulai mencatat progres tugasmu';
    }
    final difference = _durationText((current - previous).abs());
    return current > previous
        ? '$difference lebih banyak dari $previousPeriod'
        : '$difference lebih sedikit dari $previousPeriod';
  }

  void _shiftPeriod(int direction) {
    final nextDate = switch (_period) {
      _CalendarPeriod.week => _selectedDate.add(Duration(days: direction * 7)),
      _CalendarPeriod.month => _addMonths(_selectedDate, direction),
      _CalendarPeriod.year => _addMonths(_selectedDate, direction * 12),
    };
    setState(() {
      _selectedDate = nextDate;
      _visibleMonth = DateTime(nextDate.year, nextDate.month);
    });
  }

  DateTime _addMonths(DateTime date, int months) {
    final targetMonth = DateTime(date.year, date.month + months, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    return DateTime(
      targetMonth.year,
      targetMonth.month,
      math.min(date.day, lastDay).toInt(),
    );
  }

  Widget _buildMonthHeatmap(DateTime monthStart) {
    final firstWeekday = monthStart.weekday - 1;
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final weekCount = ((firstWeekday + daysInMonth) / 7).ceil();

    return Column(
      key: const ValueKey('calendar-month-heatmap'),
      children: [
        for (var weekday = 0; weekday < 7; weekday++) ...[
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 34,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _weekdays[weekday],
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    for (var week = 0; week < weekCount; week++) ...[
                      Expanded(
                        child: _buildMonthHeatmapCell(
                          monthStart,
                          week,
                          weekday,
                          firstWeekday,
                          daysInMonth,
                        ),
                      ),
                      if (week < weekCount - 1) const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (weekday < 6) const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildMonthHeatmapCell(
    DateTime monthStart,
    int week,
    int weekday,
    int firstWeekday,
    int daysInMonth,
  ) {
    final day = week * 7 + weekday - firstWeekday + 1;
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: 34);
    }

    final date = DateTime(monthStart.year, monthStart.month, day);
    final selected = _isSameDate(date, _selectedDate);
    final minutes = _completedMinutesOn(date);
    final fill = minutes == 0
        ? AppColors.cardBorder
        : AppColors.primary.withValues(
            alpha: minutes < 30
                ? 0.36
                : minutes < 60
                ? 0.54
                : minutes < 90
                ? 0.72
                : 0.90,
          );

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${_weekdayNames[date.weekday - 1]}, ${date.day} '
          '${_months[date.month - 1]}, ${_durationText(minutes)} tugas selesai',
      child: InkWell(
        key: ValueKey(
          'calendar-heatmap-day-${date.year}-${date.month}-${date.day}',
        ),
        onTap: () {
          setState(() {
            _selectedDate = date;
            _visibleMonth = DateTime(date.year, date.month);
          });
        },
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: fill,
            border: selected
                ? Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.3),
                  )
                : null,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthWeekLabels(DateTime monthStart) {
    final firstWeekday = monthStart.weekday - 1;
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final weekCount = ((firstWeekday + daysInMonth) / 7).ceil();

    return Row(
      key: const ValueKey('calendar-month-week-labels'),
      children: [
        const SizedBox(width: 32),
        Expanded(
          child: Row(
            children: [
              for (var week = 0; week < weekCount; week++) ...[
                Expanded(
                  child: Center(
                    child: Text(
                      'Mgg ${week + 1}',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (week < weekCount - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestWeekNote(DateTime monthStart, DateTime monthEnd) {
    final points = _chartPoints(monthStart, monthEnd);
    var bestWeek = -1;
    var bestMinutes = 0;
    for (var index = 0; index < points.length; index++) {
      if (points[index].minutes > bestMinutes) {
        bestWeek = index;
        bestMinutes = points[index].minutes;
      }
    }

    if (bestWeek == -1) {
      return const Text(
        'Selesaikan tugas untuk melihat minggu paling produktif.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.45,
        ),
      );
    }

    final firstWeekday = monthStart.weekday - 1;
    final weekStart = monthStart.add(
      Duration(days: bestWeek * 7 - firstWeekday),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));
    final lastMonthDay = monthEnd.subtract(const Duration(days: 1));
    final rangeStart = weekStart.isBefore(monthStart) ? monthStart : weekStart;
    final rangeEnd = weekEnd.isAfter(lastMonthDay) ? lastMonthDay : weekEnd;
    final range = rangeStart.day == rangeEnd.day
        ? '${rangeStart.day} ${_months[rangeStart.month - 1]}'
        : '${rangeStart.day} – ${rangeEnd.day} '
              '${_months[rangeEnd.month - 1]}';

    return Text(
      'Minggu terbaik: $range, dengan '
      '${_durationText(bestMinutes)} durasi tugas selesai.',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.45,
      ),
    );
  }

  String _yearComparisonText(int activeDays, int previousActiveDays) {
    if (activeDays == previousActiveDays) {
      return 'Jumlah hari aktif sama seperti periode tahun lalu';
    }

    final difference = (activeDays - previousActiveDays).abs();
    return activeDays > previousActiveDays
        ? '$difference hari aktif lebih banyak dari periode sama tahun lalu'
        : '$difference hari aktif lebih sedikit dari periode sama tahun lalu';
  }

  Widget _buildYearHeatmaps(DateTime yearStart) {
    return Column(
      key: const ValueKey('calendar-year-heatmaps'),
      children: [
        for (var row = 0; row < 4; row++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < 3; column++) ...[
                Expanded(
                  child: _buildYearMonthHeatmap(
                    DateTime(yearStart.year, row * 3 + column + 1),
                  ),
                ),
                if (column < 2) const SizedBox(width: 14),
              ],
            ],
          ),
          if (row < 3) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildYearMonthHeatmap(DateTime monthStart) {
    final firstWeekday = monthStart.weekday - 1;
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final weekCount = ((firstWeekday + daysInMonth) / 7).ceil();

    return Column(
      key: ValueKey('calendar-year-month-${monthStart.month}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _shortMonths[monthStart.month - 1],
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Column(
          children: [
            for (var weekday = 0; weekday < 7; weekday++) ...[
              Row(
                children: [
                  for (var week = 0; week < weekCount; week++) ...[
                    Expanded(
                      child: _buildYearHeatmapCell(
                        monthStart,
                        week,
                        weekday,
                        firstWeekday,
                        daysInMonth,
                      ),
                    ),
                    if (week < weekCount - 1) const SizedBox(width: 2),
                  ],
                ],
              ),
              if (weekday < 6) const SizedBox(height: 2),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildYearHeatmapCell(
    DateTime monthStart,
    int week,
    int weekday,
    int firstWeekday,
    int daysInMonth,
  ) {
    final day = week * 7 + weekday - firstWeekday + 1;
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: 9);
    }

    final date = DateTime(monthStart.year, monthStart.month, day);
    final minutes = _completedMinutesOn(date);
    final fill = minutes == 0
        ? AppColors.cardBorder
        : AppColors.primary.withValues(
            alpha: minutes < 30
                ? 0.52
                : minutes < 60
                ? 0.68
                : 0.84,
          );

    return Semantics(
      button: true,
      selected: _isSameDate(date, _selectedDate),
      label:
          '${_weekdayNames[date.weekday - 1]}, ${date.day} '
          '${_months[date.month - 1]} ${date.year}, '
          '${_durationText(minutes)} tugas selesai',
      child: InkWell(
        key: ValueKey(
          'calendar-year-heatmap-day-${date.year}-${date.month}-${date.day}',
        ),
        onTap: () {
          setState(() {
            _selectedDate = date;
            _visibleMonth = DateTime(date.year, date.month);
            _period = _CalendarPeriod.month;
          });
        },
        borderRadius: BorderRadius.circular(2),
        child: Container(
          height: 9,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildBestMonthNote(DateTime yearStart, DateTime yearEnd) {
    final points = _chartPoints(yearStart, yearEnd);
    var bestMonth = -1;
    var bestMinutes = 0;
    for (var index = 0; index < points.length; index++) {
      if (points[index].minutes > bestMinutes) {
        bestMonth = index;
        bestMinutes = points[index].minutes;
      }
    }

    final note = bestMonth == -1
        ? 'Selesaikan tugas untuk melihat bulan paling produktif.'
        : 'Bulan paling produktif: ${_months[bestMonth]}, dengan '
              '${_durationText(bestMinutes)} durasi tugas selesai.';
    return Text(
      note,
      key: const ValueKey('calendar-year-best-month'),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.45,
      ),
    );
  }

  void _changeCalendarMonth(int offset) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    setState(() {
      _visibleMonth = nextMonth;
      _selectedDate = DateTime(
        nextMonth.year,
        nextMonth.month,
        math.min(_selectedDate.day, lastDay).toInt(),
      );
    });
  }

  Future<void> _showLabelFilter() async {
    final labels = widget.tasks.map((task) => task.label.name).toSet().toList()
      ..sort();
    if (labels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada label dari tugasmu.')),
      );
      return;
    }

    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        final initial = _selectedLabels;
        final draft = initial == null ? labels.toSet() : {...initial};
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text('Filter label'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final label in labels)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(label),
                        value: draft.contains(label),
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                        onChanged: (selected) {
                          setDialogState(() {
                            if (selected == true) {
                              draft.add(label);
                            } else {
                              draft.remove(label);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, labels.toSet()),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Semua'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, draft),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Terapkan'),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() {
      _selectedLabels = selected.length == labels.length ? null : selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final periodStart = _periodStart(_selectedDate, _period);
    final periodEnd = _periodEnd(periodStart, _period);
    final totalMinutes = _minutesBetween(periodStart, periodEnd);
    final previousStart = _previousPeriodStart(periodStart, _period);
    final previousEnd = _periodEnd(previousStart, _period);
    final previousMinutes = _minutesBetween(previousStart, previousEnd);
    final comparisonText = _period == _CalendarPeriod.year
        ? _yearComparisonText(
            _activeDaysBetween(periodStart, periodEnd),
            _activeDaysBetween(previousStart, previousEnd),
          )
        : _comparisonText(totalMinutes, previousMinutes);

    return Center(
      child: ConstrainedBox(
        key: const ValueKey('calendar-screen'),
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildPeriodNavigation(periodStart),
              const SizedBox(height: 12),
              _buildSummary(totalMinutes, comparisonText),
              const SizedBox(height: 20),
              if (_period == _CalendarPeriod.month) ...[
                _buildMonthHeatmap(periodStart),
                const SizedBox(height: 8),
                _buildMonthWeekLabels(periodStart),
                const SizedBox(height: 8),
                _buildBestWeekNote(periodStart, periodEnd),
              ] else if (_period == _CalendarPeriod.year) ...[
                _buildYearHeatmaps(periodStart),
                const SizedBox(height: 8),
                _buildBestMonthNote(periodStart, periodEnd),
              ] else ...[
                _buildChart(periodStart, periodEnd),
                const SizedBox(height: 12),
                _buildProductivityNote(periodStart, periodEnd),
              ],
              const SizedBox(height: 10),
              _buildActiveDays(periodStart, periodEnd),
              if (_period == _CalendarPeriod.month) ...[
                const SizedBox(height: 12),
                _buildMonthTaskLog(),
              ] else if (_period == _CalendarPeriod.week) ...[
                const SizedBox(height: 12),
                _buildMonthCalendar(),
                const SizedBox(height: 18),
                _buildSelectedDayTasks(),
              ],
              if (_period != _CalendarPeriod.year) ...[
                const SizedBox(height: 18),
                _buildHabits(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasFilter = _selectedLabels != null;
    return Row(
      children: [
        Text(
          'Kalender',
          style: AppTextStyles.appTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Filter label kalender',
          child: InkWell(
            key: const ValueKey('calendar-filter'),
            onTap: _showLabelFilter,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset('assets/figma/calendar-filter.svg'),
                  if (hasFilter)
                    Positioned(
                      top: -3,
                      right: -4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodNavigation(DateTime periodStart) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final periodControls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _periodArrow(
              label: 'Periode sebelumnya',
              icon: Icons.chevron_left,
              onTap: () => _shiftPeriod(-1),
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                _periodTitle(periodStart),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 2),
            _periodArrow(
              label: 'Periode berikutnya',
              icon: Icons.chevron_right,
              onTap: () => _shiftPeriod(1),
            ),
          ],
        );
        final periodTabs = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final period in _CalendarPeriod.values) ...[
              if (period != _CalendarPeriod.week) const SizedBox(width: 8),
              _periodTab(period),
            ],
          ],
        );

        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              periodControls,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: periodTabs),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: periodControls),
            const SizedBox(width: 8),
            periodTabs,
          ],
        );
      },
    );
  }

  Widget _periodArrow({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 20,
          height: 24,
          child: Icon(icon, size: 15, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _periodTab(_CalendarPeriod period) {
    final selected = _period == period;
    final label = switch (period) {
      _CalendarPeriod.week => 'Minggu',
      _CalendarPeriod.month => 'Bulan',
      _CalendarPeriod.year => 'Tahun',
    };
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        key: ValueKey('calendar-view-${period.name}'),
        onTap: () => setState(() => _period = period),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
              Container(
                height: 2,
                width: label.length * 6.5,
                color: selected ? AppColors.primary : const Color(0xFFF4F4F5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(int totalMinutes, String comparisonText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _periodDescription(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _durationText(totalMinutes),
            style: const TextStyle(
              fontSize: 44,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          comparisonText,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(DateTime start, DateTime end) {
    final points = _chartPoints(start, end);
    final maximum = points.fold<int>(
      0,
      (current, point) => math.max(current, point.minutes).toInt(),
    );

    return SizedBox(
      height: 176,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(child: _buildChartBar(point, maximum)),
        ],
      ),
    );
  }

  Widget _buildChartBar(_ChartPoint point, int maximum) {
    final fraction = maximum == 0 ? 0.0 : point.minutes / maximum;
    final barHeight = math.max(4.0, 124 * fraction).toDouble();
    return Semantics(
      label: '${point.label}, ${_durationText(point.minutes)} tugas selesai',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 14,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _durationText(point.minutes),
                style: TextStyle(
                  color: point.minutes == maximum && point.minutes > 0
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: barHeight,
            width: 26,
            constraints: const BoxConstraints(maxWidth: 26),
            decoration: BoxDecoration(
              color: point.minutes == 0 ? AppColors.primary : null,
              gradient: point.minutes == 0
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primary, Color(0x8FFFFFFF)],
                    ),
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 14,
            child: Text(
              point.label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityNote(DateTime start, DateTime end) {
    DateTime? bestDate;
    var bestMinutes = 0;
    for (
      var date = start;
      date.isBefore(end);
      date = date.add(const Duration(days: 1))
    ) {
      final minutes = _completedMinutesOn(date);
      if (minutes > bestMinutes) {
        bestDate = date;
        bestMinutes = minutes;
      }
    }

    final note = bestDate == null
        ? 'Selesaikan tugasmu untuk melihat hari paling produktif.'
        : 'Hari paling produktif adalah '
              '${_weekdayNames[bestDate.weekday - 1]}, dengan '
              '${_durationText(bestMinutes)} durasi tugas selesai.';
    return Text(
      note,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.45,
      ),
    );
  }

  Widget _buildActiveDays(DateTime start, DateTime end) {
    final activeDays = _activeDaysBetween(start, end);
    final totalDays = end.difference(start).inDays;
    final value = switch (_period) {
      _CalendarPeriod.week => '$activeDays dari $totalDays',
      _CalendarPeriod.month => '$activeDays dari $totalDays hari',
      _CalendarPeriod.year => '$activeDays hari',
    };

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Hari aktif',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar() {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final rowCount = ((firstOfMonth.weekday - 1 + daysInMonth) / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                key: const ValueKey('calendar-month-heading'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _periodArrow(
              label: 'Bulan kalender sebelumnya',
              icon: Icons.chevron_left,
              onTap: () => _changeCalendarMonth(-1),
            ),
            _periodArrow(
              label: 'Bulan kalender berikutnya',
              icon: Icons.chevron_right,
              onTap: () => _changeCalendarMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final weekday in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    weekday,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < rowCount; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: _buildCalendarDay(
                    row * 7 + column - firstOfMonth.weekday + 2,
                    daysInMonth,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCalendarDay(int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: 38);
    }

    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final selected = _isSameDate(date, _selectedDate);
    final hasTasks = _tasksOnDate(date).isNotEmpty;
    return SizedBox(
      height: 38,
      child: Center(
        child: Semantics(
          button: true,
          selected: selected,
          label:
              '${_weekdayNames[date.weekday - 1]}, $day '
              '${_months[date.month - 1]} ${date.year}'
              '${hasTasks ? ', ada tugas' : ''}',
          child: InkWell(
            key: ValueKey('calendar-day-${date.year}-${date.month}-$day'),
            onTap: () {
              setState(() {
                _selectedDate = date;
                _visibleMonth = DateTime(date.year, date.month);
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                border: selected ? Border.all(color: AppColors.primary) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: date.isAfter(_today)
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                  if (hasTasks)
                    SvgPicture.asset('assets/figma/calendar-day-indicator.svg')
                  else
                    const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayTasks() {
    final tasks = _tasksOnDate(_selectedDate);
    final title =
        'Tugas, ${_selectedDate.day} '
        '${_months[_selectedDate.month - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '${tasks.length}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Tidak ada tugas pada tanggal ini.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          )
        else
          for (final task in tasks)
            TaskCard(
              task: task,
              onTap: () => widget.onTaskEdit(task),
              onToggle: () => widget.onTaskToggle(task),
              onEdit: () => widget.onTaskEdit(task),
              onDelete: () => widget.onTaskDelete(task),
            ),
      ],
    );
  }

  Widget _buildMonthTaskLog() {
    final tasks = _completedTasksOnDate(_selectedDate);
    final totalMinutes = tasks.fold<int>(
      0,
      (total, task) => total + task.durationMinutes,
    );
    final dateTitle =
        '${_weekdayNames[_selectedDate.weekday - 1]}, '
        '${_selectedDate.day} ${_months[_selectedDate.month - 1]}';

    return Column(
      key: const ValueKey('calendar-month-log'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dateTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              'Total ${_durationText(totalMinutes)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: tasks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Belum ada tugas selesai pada tanggal ini.',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < tasks.length; index++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tasks[index].title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _durationText(tasks[index].durationMinutes),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < tasks.length - 1)
                        const Divider(height: 1, color: AppColors.cardBorder),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHabits() {
    final labelNames = _visibleTasks.map((task) => task.label.name).toSet();
    if (labelNames.isEmpty) {
      return const Text(
        'Belum ada data kebiasaan. Tambahkan tugas untuk melihat progres label.',
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
          height: 1.4,
        ),
      );
    }

    final end = _today.add(const Duration(days: 1));
    final start = end.subtract(const Duration(days: 28));
    final habits =
        labelNames.map((name) {
          final tasks = _visibleTasks
              .where((task) => task.label.name == name)
              .toList();
          final dailyMinutes = List.generate(28, (index) {
            final date = start.add(Duration(days: index));
            return tasks
                .where((task) => task.isCompleted && _taskOccursOn(task, date))
                .fold(0, (total, task) => total + task.durationMinutes);
          });
          return _HabitData(
            label: name,
            dailyMinutes: dailyMinutes,
            totalMinutes: dailyMinutes.fold(
              0,
              (total, minutes) => total + minutes,
            ),
          );
        }).toList()..sort((first, second) {
          final byMinutes = second.totalMinutes.compareTo(first.totalMinutes);
          return byMinutes != 0
              ? byMinutes
              : first.label.compareTo(second.label);
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kebiasaan, 28 hari terakhir',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        for (final habit in habits) ...[
          _buildHabit(habit),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildHabit(_HabitData habit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                habit.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              _durationText(habit.totalMinutes),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var index = 0; index < habit.dailyMinutes.length; index++) ...[
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: habit.dailyMinutes[index] == 0
                        ? AppColors.cardBorder
                        : AppColors.primary.withValues(
                            alpha: habit.dailyMinutes[index] < 30
                                ? 0.47
                                : habit.dailyMinutes[index] < 60
                                ? 0.64
                                : habit.dailyMinutes[index] < 90
                                ? 0.81
                                : 0.98,
                          ),
                  ),
                ),
              ),
              if (index < habit.dailyMinutes.length - 1)
                const SizedBox(width: 2),
            ],
          ],
        ),
      ],
    );
  }
}

class _ChartPoint {
  final String label;
  final int minutes;

  const _ChartPoint({required this.label, required this.minutes});
}

class _HabitData {
  final String label;
  final List<int> dailyMinutes;
  final int totalMinutes;

  const _HabitData({
    required this.label,
    required this.dailyMinutes,
    required this.totalMinutes,
  });
}
