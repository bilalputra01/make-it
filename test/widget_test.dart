import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:make_it/main.dart';
import 'package:make_it/models/task.dart';
import 'package:make_it/screens/calendar_screen.dart';
import 'package:make_it/widgets/task_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('calendar reflects completed user tasks across periods', (
    WidgetTester tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final calendarTask = Task(
      id: 'calendar-task',
      title: 'Tugas kalender',
      label: const TaskLabel(name: 'Kuliah', colorValue: 0xFF6F9A7E),
      durationMinutes: 45,
      priority: TaskPriority.medium,
      isCompleted: true,
      dueDate: today,
    );
    SharedPreferences.setMockInitialValues({
      'make_it_tasks': jsonEncode([calendarTask.toJson()]),
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);

    await tester.pumpWidget(const MakeItApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Kalender').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-month-heading')),
      findsOneWidget,
    );
    expect(
      find.text('Estimasi durasi tugas yang selesai minggu ini'),
      findsOneWidget,
    );
    expect(find.text('45 m'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('calendar-view-month')));
    await tester.pumpAndSettle();
    expect(
      find.text('Estimasi durasi tugas yang selesai bulan ini'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-month-heatmap')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-month-week-labels')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey(
          'calendar-heatmap-day-${today.year}-${today.month}-${today.day}',
        ),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('calendar-month-log')), findsOneWidget);
    expect(find.text('Total 45 m'), findsOneWidget);

    final firstOfMonth = DateTime(today.year, today.month);
    await tester.tap(
      find.byKey(
        ValueKey(
          'calendar-heatmap-day-${firstOfMonth.year}-'
          '${firstOfMonth.month}-${firstOfMonth.day}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    const weekdayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const monthNames = [
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
    expect(
      find.text(
        '${weekdayNames[firstOfMonth.weekday - 1]}, '
        '1 ${monthNames[firstOfMonth.month - 1]}',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        ValueKey(
          'calendar-heatmap-day-${today.year}-${today.month}-${today.day}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tugas kalender'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-view-year')));
    await tester.pumpAndSettle();
    expect(
      find.text('Estimasi durasi tugas yang selesai tahun ini'),
      findsOneWidget,
    );
    expect(
      find.text('1 hari aktif lebih banyak dari periode sama tahun lalu'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-year-heatmaps')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('calendar-year-month-${today.month}')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-year-best-month')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        ValueKey(
          'calendar-year-heatmap-day-${today.year}-${today.month}-${today.day}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Estimasi durasi tugas yang selesai bulan ini'),
      findsOneWidget,
    );
    expect(find.text('Tugas kalender'), findsOneWidget);

    await tester.ensureVisible(find.text('Tugas kalender'));
    expect(find.text('Tugas kalender'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final size in [
      const Size(360, 800),
      const Size(280, 640),
      const Size(568, 320),
      const Size(768, 1024),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarScreen(
              tasks: [calendarTask],
              onTaskToggle: (_) {},
              onTaskEdit: (_) {},
              onTaskDelete: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-view-month')));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Monthly layout failed at $size',
      );
      await tester.tap(find.byKey(const ValueKey('calendar-view-year')));
      await tester.pumpAndSettle();
      final layoutException = tester.takeException();
      expect(layoutException, isNull, reason: 'Yearly layout failed at $size');
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('calendar label filter uses the requested colors', (
    WidgetTester tester,
  ) async {
    final task = Task(
      id: 'filter-task',
      title: 'Tugas filter',
      label: const TaskLabel(name: 'Kuliah', colorValue: 0xFF6F9A7E),
      durationMinutes: 30,
      priority: TaskPriority.medium,
      dueDate: DateUtils.dateOnly(DateTime.now()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarScreen(
            tasks: [task],
            onTaskToggle: (_) {},
            onTaskEdit: (_) {},
            onTaskDelete: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('calendar-filter')));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.backgroundColor, Colors.white);
    expect(dialog.surfaceTintColor, Colors.white);

    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.activeColor, Colors.black);
    expect(checkbox.checkColor, Colors.white);

    final allButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Semua'),
    );
    expect(allButton.style!.backgroundColor!.resolve({}), Colors.black);
    expect(allButton.style!.foregroundColor!.resolve({}), Colors.white);
    final applyButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Terapkan'),
    );
    expect(applyButton.style!.backgroundColor!.resolve({}), Colors.black);
    expect(applyButton.style!.foregroundColor!.resolve({}), Colors.white);
  });

  testWidgets('focus mode starts and lets the user switch tasks', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpWidget(const MakeItApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tulis tugas baru'));
    await tester.tap(find.text('Tulis tugas baru'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('new-task-title')),
      'Tugas fokus',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-task')));
    await tester.tap(find.byKey(const ValueKey('save-task')));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Fokus'));
    await tester.pumpAndSettle();
    expect(find.text('Dengan tugas'), findsOneWidget);
    expect(find.text('Fokus bebas'), findsOneWidget);
    expect(find.text('Tugas fokus'), findsOneWidget);
    expect(find.byKey(const ValueKey('focus-minutes')), findsOneWidget);
    expect(find.text('Ganti tugas'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('focus-task-selector')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('focus-task-picker-title')),
      findsOneWidget,
    );
    expect(find.text('Tugas fokus'), findsWidgets);

    final taskId = tester
        .widget<TaskCard>(find.byType(TaskCard, skipOffstage: false).first)
        .task
        .id;
    await tester.enterText(
      find.byKey(const ValueKey('focus-task-search')),
      'Tugas fokus',
    );
    await tester.tap(find.byKey(ValueKey('focus-task-option-$taskId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('confirm-focus-task')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-focus-task')));
    await tester.pumpAndSettle();
    expect(find.text('Tugas fokus'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('focus-duration-10')));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('focus-free-mode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-task-selector')), findsNothing);
    expect(find.byKey(const ValueKey('change-focus-task')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('focus-with-task-mode')));

    await tester.tap(find.byKey(const ValueKey('focus-start')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-running-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('focus-pause-action')), findsNothing);
    expect(find.bySemanticsLabel('Tugas'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('focus-timer-display')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-timer-paused')), findsOneWidget);
    expect(find.byKey(const ValueKey('focus-pause-action')), findsOneWidget);
    final pausedSeconds = tester
        .widget<Text>(find.byKey(const ValueKey('focus-running-seconds')))
        .data;
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('focus-running-seconds')))
          .data,
      pausedSeconds,
    );

    await tester.tap(find.byKey(const ValueKey('focus-pause-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-timer-running')), findsOneWidget);
    expect(find.byKey(const ValueKey('focus-pause-action')), findsNothing);

    final timerDisplay = find.byKey(const ValueKey('focus-timer-display'));
    final timerPosition = tester.getCenter(timerDisplay);
    final firstTap = await tester.startGesture(timerPosition);
    await firstTap.up();
    await tester.pump(const Duration(milliseconds: 50));
    final secondTap = await tester.startGesture(timerPosition);
    await secondTap.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-running-screen')), findsNothing);
    expect(find.byKey(const ValueKey('focus-paused-minutes')), findsOneWidget);
    expect(find.byKey(const ValueKey('focus-paused-seconds')), findsOneWidget);
    expect(find.byKey(const ValueKey('focus-resume-action')), findsOneWidget);
    expect(find.bySemanticsLabel('Tugas'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('focus-resume-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-running-screen')), findsOneWidget);
    expect(find.bySemanticsLabel('Tugas'), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('edits and deletes tasks from the task menu', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MakeItApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tulis tugas baru'));
    await tester.tap(find.text('Tulis tugas baru'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('new-task-title')),
      'Tugas awal',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-task')));
    await tester.tap(find.byKey(const ValueKey('save-task')));
    await tester.pumpAndSettle();

    final taskId = tester.widget<TaskCard>(find.byType(TaskCard).first).task.id;

    expect(
      tester
          .widget<PopupMenuButton<String>>(
            find.byKey(ValueKey('task-menu-$taskId')),
          )
          .color,
      Colors.white,
    );
    await tester.ensureVisible(find.byKey(ValueKey('task-menu-$taskId')));
    await tester.tap(find.byKey(ValueKey('task-menu-$taskId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-task-action')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('new-task-title')))
          .controller
          ?.text,
      'Tugas awal',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-task-title')),
      'Tugas diperbarui',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-task')));
    await tester.tap(find.byKey(const ValueKey('save-task')));
    await tester.pumpAndSettle();
    expect(find.text('Tugas diperbarui'), findsOneWidget);
    expect(find.text('Tugas awal'), findsNothing);

    await tester.ensureVisible(find.byKey(ValueKey('task-menu-$taskId')));
    await tester.tap(find.byKey(ValueKey('task-menu-$taskId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-task-action')));
    await tester.pumpAndSettle();
    expect(find.text('Hapus tugas?'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('confirm-delete-task-$taskId')));
    await tester.pumpAndSettle();
    expect(find.text('Tugas diperbarui'), findsNothing);
  });

  testWidgets('keeps new label form above the keyboard', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);

    await tester.pumpWidget(const MakeItApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tulis tugas baru'));
    await tester.tap(find.text('Tulis tugas baru'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Buat label baru'));
    await tester.tap(find.text('Buat label baru'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('label-swatch-purple-selected')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('label-color-3')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('label-swatch-purple-unselected')),
      findsOneWidget,
    );

    final nameField = find.byKey(const ValueKey('new-label-name'));
    await tester.tap(nameField);
    await tester.showKeyboard(nameField);
    tester.view.viewInsets = const FakeViewPadding(bottom: 270);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Terlihat');
    await tester.ensureVisible(find.byKey(const ValueKey('save-label')));
    expect(
      tester.getBottomRight(find.byKey(const ValueKey('save-label'))).dy,
      lessThanOrEqualTo(370),
    );

    tester.view.resetViewInsets();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('layouts adapt to phone, tablet, and desktop sizes', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;

    for (final size in [
      const Size(280, 640),
      const Size(320, 568),
      const Size(568, 320),
      const Size(768, 1024),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const MakeItApp());
      await tester.pumpAndSettle();
      expect(find.text('MENDATANG'), findsOneWidget);
      expect(find.text('Bales dosen pembimbing'), findsNothing);

      final addTaskButton = find.text('Tulis tugas baru');
      await tester.ensureVisible(addTaskButton);
      await tester.tap(addTaskButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('save-task')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('task-date')));
      await tester.tap(find.byKey(const ValueKey('task-date')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('use-selected-date')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Buat label baru'));
      await tester.tap(find.text('Buat label baru'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('save-label')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('adds, completes, and saves tasks', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MakeItApp());
    await tester.pumpAndSettle();

    expect(find.text('MENDATANG'), findsOneWidget);
    expect(find.text('Bales dosen pembimbing'), findsNothing);
    expect(find.text('Belum ada tugas.'), findsOneWidget);

    await tester.tap(find.text('Tulis tugas baru'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<Text>(find.text('Tinggi')).style?.color,
      const Color(0xFF09090B),
    );
    await tester.ensureVisible(find.text('Buat label baru'));
    await tester.tap(find.text('Buat label baru'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('save-label')));
    await tester.tap(find.byKey(const ValueKey('save-label')));
    await tester.pumpAndSettle();
    expect(find.text('Nama label wajib diisi.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('new-label-name')),
      'Biologi',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-label')));
    await tester.tap(find.byKey(const ValueKey('save-label')));
    await tester.pumpAndSettle();
    expect(find.text('Label dengan nama itu sudah ada.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('new-label-name')),
      'Olahraga',
    );
    await tester.tap(find.byKey(const ValueKey('label-color-3')));
    await tester.ensureVisible(find.byKey(const ValueKey('save-label')));
    await tester.tap(find.byKey(const ValueKey('save-label')));
    await tester.pumpAndSettle();
    expect(find.text('Olahraga'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('task-date')));
    await tester.tap(find.byKey(const ValueKey('task-date')));
    await tester.pumpAndSettle();
    expect(find.text('Pilih tanggal'), findsOneWidget);
    expect(find.text('Gunakan tanggal'), findsOneWidget);
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDate = today;
    await tester.tap(
      find.byKey(
        ValueKey(
          'calendar-day-${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('use-selected-date')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('new-task-title')),
      'Tes tugas baru',
    );
    await tester.tap(find.byKey(const ValueKey('label-Pribadi')));
    await tester.ensureVisible(find.byKey(const ValueKey('repeat-Sen')));
    await tester.tap(find.byKey(const ValueKey('repeat-Sen')));
    await tester.ensureVisible(find.byKey(const ValueKey('save-task')));
    await tester.tap(find.byKey(const ValueKey('save-task')));
    await tester.pumpAndSettle();

    expect(find.text('Tes tugas baru'), findsOneWidget);

    final createdTask = tester.widgetList<TaskCard>(find.byType(TaskCard)).last;
    final taskToggle = find.byKey(
      ValueKey('task-toggle-${createdTask.task.id}'),
    );
    await tester.ensureVisible(taskToggle);
    await tester.tap(taskToggle);
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    final savedTasks = preferences.getString('make_it_tasks');
    expect(savedTasks, contains('Tes tugas baru'));
    expect(savedTasks, contains('"name":"Pribadi"'));
    expect(savedTasks, contains('"repeatDays":[1]'));
    expect(savedTasks, contains('"isCompleted":true'));
    expect(
      savedTasks,
      contains(
        '"dueDate":"${today.toIso8601String().split('T').first}T00:00:00.000"',
      ),
    );
    final savedLabels = preferences.getString('make_it_labels');
    expect(savedLabels, contains('"name":"Olahraga"'));
    expect(savedLabels, contains('"colorValue":4285240521'));
  });
}
