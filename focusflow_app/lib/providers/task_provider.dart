import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  List<Task> get pendingTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    _tasks = await _apiService.getTasks();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(String title, {String priority = 'medium'}) async {
    final task = await _apiService.createTask(title, priority: priority);
    if (task != null) {
      _tasks.insert(0, task);
      notifyListeners();
    }
  }

  Future<void> toggleTaskStatus(int id, bool currentStatus) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final updatedStatus = !currentStatus;
      final success = await _apiService.updateTask(id, {'isCompleted': updatedStatus});
      if (success) {
        final task = _tasks[index];
        _tasks[index] = Task(
          id: task.id,
          title: task.title,
          description: task.description,
          isCompleted: updatedStatus,
          priority: task.priority,
          category: task.category,
          createdAt: task.createdAt,
        );
        notifyListeners();
      }
    }
  }

  Future<void> deleteTask(int id) async {
    final success = await _apiService.deleteTask(id);
    if (success) {
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    }
  }
}
