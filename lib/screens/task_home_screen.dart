import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/task_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/collapsible_section.dart';
import '../widgets/progress_bar.dart';
import '../widgets/task_card.dart';
import '../widgets/task_section.dart';
import 'calendar_screen.dart';
import 'create_task_sheet.dart';
import 'focus_mode_screen.dart';

class TaskHomeScreen extends StatefulWidget {
  const TaskHomeScreen({super.key});

  @override
  State<TaskHomeScreen> createState() => _TaskHomeScreenState();
}

class _TaskHomeScreenState extends State<TaskHomeScreen> {
  static const _storageKey = 'make_it_tasks';
  static const _labelStorageKey = 'make_it_labels';

  int _currentNavIndex = 0;
  final List<Task> _tasks = [];
  final List<TaskLabel> _labels = [...CreateTaskSheet.defaultLabels];
  bool _isLoading = true;
  String? _loadError;
  bool _isFocusSessionStarted = false;
  bool _kapanSajaExpanded = false;
  bool _selesaiExpanded = false;
  final TaskApiService _api = TaskApiService();
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    final prefs = _prefs;
    if (prefs != null) return prefs;
    final newPrefs = await SharedPreferences.getInstance();
    _prefs = newPrefs;
    return newPrefs;
  }

  List<Task> get _todayTasks => _tasks
      .where((task) => task.schedule == TaskSchedule.today && !task.isCompleted)
      .toList();

  List<Task> get _upcomingTasks => _tasks
      .where(
        (task) => task.schedule == TaskSchedule.upcoming && !task.isCompleted,
      )
      .toList();

  List<Task> get _anytimeTasks => _tasks
      .where(
        (task) => task.schedule == TaskSchedule.anytime && !task.isCompleted,
      )
      .toList();

  List<Task> get _completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();

  double get _progress {
    final today = _tasks
        .where((task) => task.schedule == TaskSchedule.today)
        .toList();
    if (today.isEmpty) return 0;
    return today.where((task) => task.isCompleted).length / today.length;
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final loadedTasks = await _api.getTasks();
      final loadedLabels = await _api.getLabels();
      final labels = [...CreateTaskSheet.defaultLabels];
      for (final label in loadedLabels) {
        if (!labels.any(
          (existing) => existing.name.toLowerCase() == label.name.toLowerCase(),
        )) {
          labels.add(label);
        }
      }
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(loadedTasks);
        _labels
          ..clear()
          ..addAll(labels);
        _isLoading = false;
      });
    } catch (error) {
      await _loadFromLocalStorage();
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final preferences = await _getPrefs();
      final savedTasks = preferences.getString(_storageKey);
      final savedLabels = preferences.getString(_labelStorageKey);
      final loadedTasks = savedTasks == null
          ? <Task>[]
          : _decodeTasks(savedTasks);
      final loadedLabels = savedLabels == null
          ? CreateTaskSheet.defaultLabels
          : _decodeLabels(savedLabels);
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(loadedTasks);
        _labels
          ..clear()
          ..addAll(loadedLabels);
        _isLoading = false;
        _loadError = null;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Data lokal tidak valid: ${error.message}';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Gagal memuat tugas: $error';
        _isLoading = false;
      });
    }
  }

  List<Task> _decodeTasks(String data) {
    final decoded = jsonDecode(data);
    if (decoded is! List) {
      throw const FormatException('Format daftar tugas tidak dikenali.');
    }
    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Ada tugas dengan format yang tidak valid.',
        );
      }
      return Task.fromJson(item);
    }).toList();
  }

  List<TaskLabel> _decodeLabels(String data) {
    final decoded = jsonDecode(data);
    if (decoded is! List) {
      throw const FormatException('Format daftar label tidak dikenali.');
    }
    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Ada label dengan format yang tidak valid.',
        );
      }
      return TaskLabel.fromJson(item);
    }).toList();
  }

  Future<void> _saveTasks() async {
    final preferences = await _getPrefs();
    await preferences.setString(
      _storageKey,
      jsonEncode(_tasks.map((task) => task.toJson()).toList()),
    );
  }

  Future<void> _saveLabels() async {
    final preferences = await _getPrefs();
    await preferences.setString(
      _labelStorageKey,
      jsonEncode(_labels.map((label) => label.toJson()).toList()),
    );
  }

  Future<void> _addLabel(TaskLabel label) async {
    final alreadyExists = _labels.any(
      (item) => item.name.toLowerCase() == label.name.toLowerCase(),
    );
    if (alreadyExists) return;
    setState(() => _labels.add(label));
    try {
      await _api.createLabel(label);
    } catch (error) {
      await _saveLabels();
    }
  }

  Future<void> _toggleTask(Task task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;

    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    setState(() {
      _tasks[index] = updatedTask;
    });
    try {
      await _api.updateTask(updatedTask);
    } catch (error) {
      await _saveTasks();
    }
  }

  Future<void> _showAddTaskDialog() async {
    final task = await _showTaskDialog();
    if (task == null || !mounted) return;
    setState(() => _tasks.add(task));
    try {
      final savedTask = await _api.createTask(task);
      if (!mounted) return;
      final index = _tasks.indexWhere((item) => item.id == task.id);
      if (index != -1) {
        setState(() => _tasks[index] = savedTask);
      }
    } catch (error) {
      await _saveTasks();
    }
  }

  Future<Task?> _showTaskDialog({Task? initialTask}) {
    return showDialog<Task>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        final viewInsets = MediaQuery.viewInsetsOf(context);
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          constraints: const BoxConstraints(minWidth: 0),
          child: SizedBox(
            width: (size.width - 32).clamp(0, 720).toDouble(),
            height: (size.height - viewInsets.bottom - 32)
                .clamp(0, 820)
                .toDouble(),
            child: CreateTaskSheet(
              labels: _labels,
              onLabelCreated: _addLabel,
              initialTask: initialTask,
            ),
          ),
        );
      },
    );
  }

  Future<void> _editTask(Task task) async {
    final updatedTask = await _showTaskDialog(initialTask: task);
    if (updatedTask == null || !mounted) return;
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    setState(() => _tasks[index] = updatedTask);
    try {
      await _api.updateTask(updatedTask);
    } catch (error) {
      await _saveTasks();
    }
  }

  Future<void> _confirmDeleteTask(Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('Tugas "${task.title}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            key: ValueKey('confirm-delete-task-${task.id}'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    setState(() => _tasks.removeWhere((item) => item.id == task.id));
    try {
      await _api.deleteTask(task.id);
    } catch (error) {
      await _saveTasks();
    }
  }

  Widget _buildTaskCards(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Belum ada tugas.'),
        ),
      );
    }

    return Column(
      children: tasks
          .map(
            (task) => TaskCard(
              task: task,
              onToggle: () => _toggleTask(task),
              onEdit: () => _editTask(task),
              onDelete: () => _confirmDeleteTask(task),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundTop,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFFFEFA),
                          Color(0xFFFFE7B5),
                        ],
                        stops: [0, 0.5, 1],
                      ),
                      borderRadius: BorderRadius.circular(
                        constraints.maxWidth >= 768 ? 24 : 0,
                      ),
                      border: Border.all(color: const Color(0xFFD4D4D8)),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _loadError != null
                                ? _buildLoadError()
                                : IndexedStack(
                                    index: _currentNavIndex,
                                    children: [
                                      _buildTaskList(),
                                      FocusModeScreen(
                                        key: const ValueKey('focus-mode'),
                                        tasks: _tasks,
                                        onSessionStartedChanged: (started) {
                                          setState(() {
                                            _isFocusSessionStarted = started;
                                          });
                                        },
                                      ),
                                      CalendarScreen(
                                        tasks: _tasks,
                                        onTaskToggle: _toggleTask,
                                        onTaskEdit: _editTask,
                                        onTaskDelete: _confirmDeleteTask,
                                      ),
                                    ],
                                  ),
                          ),
                          if (!_isFocusSessionStarted)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: BottomNavBar(
                                currentIndex: _currentNavIndex,
                                onTap: (index) {
                                  setState(() => _currentNavIndex = index);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadTasks, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 20.0;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 12),
                ProgressBar(label: 'Fokus hari ini', progress: _progress),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTodaySection()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildUpcomingSection()),
                    ],
                  )
                else ...[
                  _buildTodaySection(),
                  const SizedBox(height: 12),
                  _buildUpcomingSection(),
                ],
                const SizedBox(height: 12),
                CollapsibleSection(
                  title: 'KAPAN SAJA',
                  count: _anytimeTasks.length,
                  isExpanded: _kapanSajaExpanded,
                  onToggle: () {
                    setState(() => _kapanSajaExpanded = !_kapanSajaExpanded);
                  },
                  child: _buildTaskCards(_anytimeTasks),
                ),
                CollapsibleSection(
                  title: 'SELESAI',
                  count: _completedTasks.length,
                  isExpanded: _selesaiExpanded,
                  onToggle: () {
                    setState(() => _selesaiExpanded = !_selesaiExpanded);
                  },
                  child: _buildTaskCards(_completedTasks),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaySection() {
    return TaskSection(
      title: 'HARI INI',
      count: _todayTasks.length,
      tasks: _todayTasks,
      showInput: true,
      onTaskToggle: _toggleTask,
      onTaskEdit: _editTask,
      onTaskDelete: _confirmDeleteTask,
      onAddTask: _showAddTaskDialog,
    );
  }

  Widget _buildUpcomingSection() {
    return TaskSection(
      title: 'MENDATANG',
      count: _upcomingTasks.length,
      tasks: _upcomingTasks,
      onTaskToggle: _toggleTask,
      onTaskEdit: _editTask,
      onTaskDelete: _confirmDeleteTask,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Make ', style: AppTextStyles.appTitle),
              TextSpan(text: 'it', style: AppTextStyles.appTitleLight),
            ],
          ),
        ),
      ],
    );
  }
}
