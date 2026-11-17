import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

class FocusModeScreen extends StatefulWidget {
  final List<Task> tasks;
  final ValueChanged<bool> onSessionStartedChanged;

  const FocusModeScreen({
    super.key,
    required this.tasks,
    required this.onSessionStartedChanged,
  });

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  static const _durations = [10, 25, 45, 60];

  Task? _selectedTask;
  Timer? _timer;
  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _isFreeFocus = false;
  bool _isSessionStarted = false;
  bool _isPausedSession = false;
  bool _isRunning = false;

  List<Task> get _availableTasks =>
      widget.tasks.where((task) => !task.isCompleted).toList();

  @override
  void initState() {
    super.initState();
    if (_availableTasks.isNotEmpty) {
      _selectedTask = _availableTasks.first;
    }
  }

  @override
  void didUpdateWidget(covariant FocusModeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedTaskId = _selectedTask?.id;
    Task? updatedTask;
    for (final task in _availableTasks) {
      if (task.id == selectedTaskId) {
        updatedTask = task;
        break;
      }
    }
    if (updatedTask != null) {
      _selectedTask = updatedTask;
    } else if (_availableTasks.isNotEmpty) {
      _selectedTask = _availableTasks.first;
    } else {
      _selectedTask = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectDuration(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _timer?.cancel();
      _isRunning = false;
    });
  }

  void _toggleTimer() {
    setState(() {
      _isSessionStarted = true;
      _isPausedSession = false;
      _isRunning = true;
    });
    widget.onSessionStartedChanged(true);
    _runTimer();
  }

  void _toggleSessionPlayback() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    if (_remainingSeconds == 0) {
      _remainingSeconds = _selectedMinutes * 60;
    }
    setState(() {
      _isPausedSession = false;
      _isSessionStarted = true;
      _isRunning = true;
    });
    widget.onSessionStartedChanged(true);
    _runTimer();
  }

  void _returnToPausedSession() {
    _timer?.cancel();
    setState(() {
      _isSessionStarted = false;
      _isPausedSession = true;
      _isRunning = false;
    });
    widget.onSessionStartedChanged(false);
  }

  void _runTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  Future<void> _showTaskPicker() async {
    final selectedTask = await showModalBottomSheet<Task>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        final availableHeight =
            size.height - MediaQuery.viewInsetsOf(context).bottom;
        final height = availableHeight > 800
            ? 760.0
            : (availableHeight * 0.95).clamp(0, 760).toDouble();
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: size.width < 420 ? size.width : 420,
            height: height,
            child: _FocusTaskPicker(
              tasks: _availableTasks,
              initialTask: _selectedTask,
            ),
          ),
        );
      },
    );
    if (selectedTask == null || !mounted) return;
    setState(() {
      _selectedTask = selectedTask;
      _isFreeFocus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final taskTitle = _selectedTask?.title;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isSessionStarted) {
          return _buildRunningSession(
            constraints,
            minutes: minutes,
            seconds: seconds,
          );
        }
        if (_isPausedSession) {
          return _buildPausedSession(
            constraints,
            minutes: minutes,
            seconds: seconds,
            taskTitle: taskTitle,
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildModeSelector(),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 24,
                    child: Center(
                      child: _isFreeFocus
                          ? null
                          : InkWell(
                              key: const ValueKey('focus-task-selector'),
                              onTap: _showTaskPicker,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  taskTitle ?? 'Pilih tugas',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(
                    height: (constraints.maxHeight - 254).clamp(170, 460),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            minutes,
                            key: const ValueKey('focus-minutes'),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 100,
                              fontWeight: FontWeight.w700,
                              height: 1.13,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            seconds,
                            key: const ValueKey('focus-seconds'),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 100,
                              fontWeight: FontWeight.w300,
                              height: 1.13,
                              letterSpacing: -2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildDurations(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      key: const ValueKey('focus-start'),
                      onPressed: _toggleTimer,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        _isRunning
                            ? 'Jeda'
                            : _remainingSeconds == 0
                            ? 'Mulai lagi'
                            : 'Mulai',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 24,
                    child: _isFreeFocus
                        ? null
                        : TextButton(
                            key: const ValueKey('change-focus-task'),
                            onPressed: _showTaskPicker,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            child: const Text('Ganti tugas'),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRunningSession(
    BoxConstraints constraints, {
    required String minutes,
    required String seconds,
  }) {
    final clockFontSize = (constraints.maxWidth * 0.7)
        .clamp(100, 250)
        .toDouble();
    return Container(
      key: const ValueKey('focus-running-screen'),
      width: double.infinity,
      height: constraints.maxHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Color(0xFFFCE4B0)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0, -0.2),
            child: Semantics(
              key: ValueKey(
                _isRunning ? 'focus-timer-running' : 'focus-timer-paused',
              ),
              button: true,
              label: _isRunning
                  ? 'Timer berjalan. Ketuk untuk menjeda'
                  : 'Timer dijeda. Ketuk untuk melanjutkan',
              child: GestureDetector(
                key: const ValueKey('focus-timer-display'),
                behavior: HitTestBehavior.opaque,
                onTap: _toggleSessionPlayback,
                onDoubleTap: _returnToPausedSession,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          minutes,
                          key: const ValueKey('focus-running-minutes'),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: clockFontSize,
                            fontWeight: FontWeight.w700,
                            height: 0.75,
                            letterSpacing: -5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          seconds,
                          key: const ValueKey('focus-running-seconds'),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: clockFontSize,
                            fontWeight: FontWeight.w300,
                            height: 0.75,
                            letterSpacing: -22.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!_isRunning)
            Align(
              alignment: const Alignment(0, 0.52),
              child: Semantics(
                button: true,
                label: 'Lanjutkan sesi fokus',
                child: InkWell(
                  key: const ValueKey('focus-pause-action'),
                  customBorder: const CircleBorder(),
                  onTap: _toggleSessionPlayback,
                  child: const SizedBox(
                    width: 72,
                    height: 72,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PauseBar(),
                          SizedBox(width: 8),
                          _PauseBar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPausedSession(
    BoxConstraints constraints, {
    required String minutes,
    required String seconds,
    required String? taskTitle,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              _buildModeSelector(),
              const SizedBox(height: 30),
              SizedBox(
                height: 24,
                child: Center(
                  child: _isFreeFocus
                      ? null
                      : Text(
                          taskTitle ?? 'Pilih tugas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              SizedBox(
                height: (constraints.maxHeight - 254).clamp(170, 460),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        minutes,
                        key: const ValueKey('focus-paused-minutes'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 100,
                          fontWeight: FontWeight.w700,
                          height: 1.13,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        seconds,
                        key: const ValueKey('focus-paused-seconds'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 100,
                          fontWeight: FontWeight.w300,
                          height: 1.13,
                          letterSpacing: -2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Lanjutkan sesi fokus',
                child: InkWell(
                  key: const ValueKey('focus-resume-action'),
                  customBorder: const CircleBorder(),
                  onTap: _toggleSessionPlayback,
                  child: SvgPicture.asset(
                    'assets/figma/focus-session-play.svg',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeTab(
          'Dengan tugas',
          selected: !_isFreeFocus,
          onTap: () {
            setState(() {
              _isFreeFocus = false;
              if (_selectedTask == null && _availableTasks.isNotEmpty) {
                _selectedTask = _availableTasks.first;
              }
            });
          },
        ),
        const SizedBox(width: 18),
        _buildModeTab(
          'Fokus bebas',
          selected: _isFreeFocus,
          onTap: () {
            setState(() => _isFreeFocus = true);
          },
        ),
      ],
    );
  }

  Widget _buildModeTab(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: ValueKey(
        label == 'Dengan tugas' ? 'focus-with-task-mode' : 'focus-free-mode',
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              height: 2,
              width: _tabWidth(label),
              color: selected ? AppColors.primary : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  double _tabWidth(String label) => label == 'Dengan tugas' ? 77 : 67;

  Widget _buildDurations() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final duration in _durations)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              key: ValueKey('focus-duration-$duration'),
              onTap: () => _selectDuration(duration),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _selectedMinutes == duration
                      ? Colors.black
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$duration',
                  style: TextStyle(
                    color: _selectedMinutes == duration
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FocusTaskPicker extends StatefulWidget {
  final List<Task> tasks;
  final Task? initialTask;

  const _FocusTaskPicker({required this.tasks, required this.initialTask});

  @override
  State<_FocusTaskPicker> createState() => _FocusTaskPickerState();
}

class _FocusTaskPickerState extends State<_FocusTaskPicker> {
  final _searchController = TextEditingController();
  late Task? _selectedTask = widget.initialTask;
  late bool _showAllTasks =
      widget.initialTask != null &&
      widget.initialTask!.schedule != TaskSchedule.today;
  String _query = '';

  List<Task> get _visibleTasks {
    final query = _query.trim().toLowerCase();
    return widget.tasks.where((task) {
      if (!_showAllTasks && task.schedule != TaskSchedule.today) return false;
      return query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.label.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5EB)),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 149,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(21, 31, 21, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ganti tugas',
                  key: ValueKey('focus-task-picker-title'),
                  style: TextStyle(
                    color: Color(0xFF141417),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: TextField(
                    key: const ValueKey('focus-task-search'),
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    style: const TextStyle(
                      color: Color(0xFF141417),
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari tugas',
                      hintStyle: const TextStyle(
                        color: Color(0xFF7A7A82),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F7FA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _buildTab(
                      'HARI INI',
                      selected: !_showAllTasks,
                      onTap: () {
                        setState(() => _showAllTasks = false);
                      },
                    ),
                    const SizedBox(width: 18),
                    _buildTab(
                      'SEMUA TUGAS',
                      selected: _showAllTasks,
                      onTap: () {
                        setState(() => _showAllTasks = true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 229,
                  child: _visibleTasks.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? 'Belum ada tugas di daftar ini.'
                                : 'Tugas tidak ditemukan.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.separated(
                          key: const ValueKey('focus-task-options'),
                          padding: EdgeInsets.zero,
                          itemCount: _visibleTasks.length,
                          itemBuilder: (context, index) {
                            final task = _visibleTasks[index];
                            final isSelected = task.id == _selectedTask?.id;
                            return InkWell(
                              key: ValueKey('focus-task-option-${task.id}'),
                              onTap: () => setState(() => _selectedTask = task),
                              child: SizedBox(
                                height: 62,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF141417),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                height: 1.6,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${task.label.name} · ${task.durationMinutes} menit',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF7A7A82),
                                                fontSize: 12,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SvgPicture.asset(
                                        isSelected
                                            ? 'assets/figma/focus-task-radio-selected.svg'
                                            : 'assets/figma/focus-task-radio-unselected.svg',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => SizedBox(
                            height: 12,
                            child: Center(
                              child: Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.5),
                                      AppColors.primary.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    key: const ValueKey('confirm-focus-task'),
                    onPressed: _selectedTask == null
                        ? null
                        : () => Navigator.pop(context, _selectedTask),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF141417),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF141417),
                      disabledForegroundColor: Colors.white54,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Pilih tugas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: ValueKey(
        label == 'HARI INI' ? 'focus-task-today-tab' : 'focus-task-all-tab',
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF09090B)
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              height: 2,
              width: label == 'HARI INI' ? 45 : 78,
              color: selected ? AppColors.primary : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseBar extends StatelessWidget {
  const _PauseBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF3F2409),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
