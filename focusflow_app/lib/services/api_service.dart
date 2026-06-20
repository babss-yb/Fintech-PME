import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/session.dart';

class ApiService {
  // Utilisation de l'IP locale pour que le téléphone puisse se connecter au backend du PC
  static const String baseUrl = 'http://192.168.1.5:3000/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── TASKS ────────────────────────────────────────────────────────
  Future<List<Task>> getTasks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/tasks'), headers: headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      }
    } catch (e) {
      print('Erreur getTasks: $e');
    }
    return [];
  }

  Future<Task?> createTask(String title, {String priority = 'medium', String? category}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'priority': priority,
          'category': category,
        }),
      );
      if (response.statusCode == 201) {
        return Task.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Erreur createTask: $e');
    }
    return null;
  }

  Future<bool> updateTask(int id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur updateTask: $e');
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/tasks/$id'), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur deleteTask: $e');
      return false;
    }
  }

  // ─── POMODORO SESSIONS ────────────────────────────────────────────
  Future<List<PomodoroSession>> getSessions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/sessions'), headers: headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => PomodoroSession.fromJson(json)).toList();
      }
    } catch (e) {
      print('Erreur getSessions: $e');
    }
    return [];
  }

    Future<PomodoroSession?> createSession(int durationMs, DateTime startTime, DateTime endTime, {int? taskId, String status = 'completed'}) async {
      try {
        final headers = await _getHeaders();
        final response = await http.post(
          Uri.parse('$baseUrl/sessions'),
          headers: headers,
          body: jsonEncode({
            'durationMs': durationMs,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'taskId': taskId,
            'status': status,
          }),
        );
      if (response.statusCode == 201) {
        return PomodoroSession.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Erreur createSession: $e');
    }
    return null;
  }
}
