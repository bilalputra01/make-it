import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:make_it/models/task.dart';
import 'package:make_it/services/task_api_service.dart';

void main() {
  test('reads flattened label fields into a task label', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/make-it/tasks');
      return http.Response(
        jsonEncode([
          {
            'id': 42,
            'title': 'Belajar',
            'labelName': 'Biologi',
            'labelColorValue': 0xFFA67DD1,
            'durationMinutes': 25,
            'priority': 'high',
            'isCompleted': false,
            'schedule': 'today',
            'dueDate': null,
            'repeatDays': <int>[],
          },
        ]),
        200,
      );
    });

    final tasks = await TaskApiService(client: client).getTasks();

    expect(tasks.single.label.name, 'Biologi');
    expect(tasks.single.label.colorValue, 0xFFA67DD1);
  });

  test('sends flattened label fields when creating a task', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['labelName'], 'Biologi');
      expect(body['labelColorValue'], 0xFFA67DD1);
      expect(body.containsKey('id'), isFalse);
      expect(body.containsKey('label'), isFalse);
      expect(body.containsKey('dueDate'), isFalse);
      return http.Response(jsonEncode({...body, 'id': 42}), 201);
    });

    final created = await TaskApiService(client: client).createTask(
      const Task(
        id: 'task-1',
        title: 'Belajar',
        label: TaskLabel(name: 'Biologi', colorValue: 0xFFA67DD1),
        durationMinutes: 25,
        priority: TaskPriority.high,
      ),
    );
    expect(created.id, '42');
  });

  test(
    'patches a task by its generated ID without sending the ID field',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/make-it/tasks/42');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('id'), isFalse);
        return http.Response('', 200);
      });

      await TaskApiService(client: client).updateTask(
        const Task(
          id: '42',
          title: 'Belajar',
          label: TaskLabel(name: 'Biologi', colorValue: 0xFFA67DD1),
          durationMinutes: 25,
          priority: TaskPriority.high,
        ),
      );
    },
  );
}
