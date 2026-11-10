import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:make_it/main.dart';
import 'package:make_it/widgets/task_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
