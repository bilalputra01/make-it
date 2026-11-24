import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task.dart';

class TaskApiService {
  static const _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api/make-it',
  );

  final http.Client _client;

  TaskApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri get _baseUri => Uri.parse(_configuredBaseUrl);

  Uri _uri(String path) {
    final base = _baseUri.toString().replaceFirst(RegExp(r'/+$'), '');
    final relativePath = path.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$base/$relativePath');
  }

  Future<List<Task>> getTasks() async {
    final response = await _client.get(_uri('/tasks'));
    _throwOnError(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Format daftar tugas tidak dikenali.');
    }
    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Ada tugas dengan format yang tidak valid.',
        );
      }
      return _taskFromApiJson(item);
    }).toList();
  }

  Future<List<TaskLabel>> getLabels() async {
    final response = await _client.get(_uri('/labels'));
    _throwOnError(response);
    final decoded = jsonDecode(response.body);
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

  Future<Task> createTask(Task task) async {
    final response = await _sendJson(
      _uri('/tasks'),
      'POST',
      _taskToApiJson(task),
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Respons tugas baru tidak valid.');
    }
    return _taskFromApiJson(decoded);
  }

  Future<void> updateTask(Task task) async {
    await _sendJson(
      _uri('/tasks/${Uri.encodeComponent(task.id)}'),
      'PATCH',
      _taskToApiJson(task),
    );
  }

  Future<void> deleteTask(String id) async {
    final response = await _client.delete(
      _uri('/tasks/${Uri.encodeComponent(id)}'),
    );
    _throwOnError(response);
  }

  Future<void> createLabel(TaskLabel label) async {
    await _sendJson(_uri('/labels'), 'POST', label.toJson());
  }

  Task _taskFromApiJson(Map<String, dynamic> json) {
    final label = json['label'];
    if (label is Map<String, dynamic>) {
      return Task.fromJson(json);
    }

    return Task.fromJson({
      ...json,
      'label': {
        'name': json['labelName'],
        'colorValue': json['labelColorValue'],
      },
    });
  }

  Map<String, dynamic> _taskToApiJson(Task task) {
    final json = task.toJson();
    json.remove('id');
    final label = json.remove('label') as Map<String, dynamic>;
    if (task.dueDate == null) json.remove('dueDate');
    return {
      ...json,
      'labelName': label['name'],
      'labelColorValue': label['colorValue'],
    };
  }

  Future<http.Response> _sendJson(
    Uri uri,
    String method,
    Map<String, dynamic> body,
  ) async {
    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _throwOnError(response);
    return response;
  }

  void _throwOnError(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Mock API gagal merespons (${response.statusCode}).');
    }
  }
}

class HttpException implements Exception {
  final String message;

  const HttpException(this.message);

  @override
  String toString() => message;
}
