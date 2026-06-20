import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/task.dart';

class TimerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  int _remainingSeconds = 25 * 60; // Default, will be overridden by settings
  bool _isRunning = false;
  bool _isBreak = false;
  Timer? _timer;
  DateTime? _sessionStartTime;
  
  Task? _currentTask;
  
  bool _needsFeedback = false;
  int? _pendingPDuration;
  int? _pendingBDuration;
  DateTime? _pendingSessionStartTime;
  DateTime? _pendingSessionEndTime;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isBreak => _isBreak;
  Task? get currentTask => _currentTask;
  bool get needsFeedback => _needsFeedback;

  void setCurrentTask(Task? task) {
    _currentTask = task;
    notifyListeners();
  }

  /// Called to sync remaining seconds with settings when not running
  void syncWithSettings(int workMinutes, int breakMinutes) {
    if (!_isRunning) {
      _remainingSeconds = _isBreak ? breakMinutes * 60 : workMinutes * 60;
      notifyListeners();
    }
  }

  void startTimer(int pDuration, int bDuration) {
    if (_timer != null && _timer!.isActive) return;
    _isRunning = true;
    _sessionStartTime ??= DateTime.now();
    
    // Set initial remaining seconds if timer was reset
    if (_remainingSeconds == 0) {
        _remainingSeconds = _isBreak ? bDuration * 60 : pDuration * 60;
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stopTimer(pDuration, bDuration);
        _handleSessionComplete(pDuration, bDuration);
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void stopTimer(int pDuration, int bDuration) {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = _isBreak ? bDuration * 60 : pDuration * 60;
    _sessionStartTime = null;
    _sessionStartTime = null;
    notifyListeners();
  }

  void finishEarly(int pDuration, int bDuration) {
    if (!_isRunning && _sessionStartTime == null) return;
    _timer?.cancel();
    _isRunning = false;
    _handleSessionComplete(pDuration, bDuration);
  }

  Future<void> _handleSessionComplete(int pDuration, int bDuration) async {
    if (!_isBreak && _sessionStartTime != null) {
      if (_currentTask != null) {
        // Stop and wait for feedback
        _needsFeedback = true;
        _pendingPDuration = pDuration;
        _pendingBDuration = bDuration;
        _pendingSessionStartTime = _sessionStartTime;
        _pendingSessionEndTime = DateTime.now();
        _sessionStartTime = null;
        notifyListeners();
        return;
      } else {
        // Free session, save automatically as completed
        final endTime = DateTime.now();
        final durationMs = endTime.difference(_sessionStartTime!).inMilliseconds;
        await _apiService.createSession(
          durationMs, 
          _sessionStartTime!, 
          endTime, 
        );
      }
    }

    _proceedToNextPhase(pDuration, bDuration);
  }

  void _proceedToNextPhase(int pDuration, int bDuration) {
    // Switch mode
    _isBreak = !_isBreak;
    _remainingSeconds = _isBreak ? bDuration * 60 : pDuration * 60;
    _sessionStartTime = null;
    notifyListeners();
  }

  Future<void> submitFeedback(String status) async {
    if (!_needsFeedback || _pendingSessionStartTime == null || _pendingSessionEndTime == null) return;

    final durationMs = _pendingSessionEndTime!.difference(_pendingSessionStartTime!).inMilliseconds;
    
    await _apiService.createSession(
      durationMs, 
      _pendingSessionStartTime!, 
      _pendingSessionEndTime!, 
      taskId: _currentTask?.id,
      status: status,
    );

    _needsFeedback = false;
    _pendingSessionStartTime = null;
    _pendingSessionEndTime = null;

    if (_pendingPDuration != null && _pendingBDuration != null) {
      _proceedToNextPhase(_pendingPDuration!, _pendingBDuration!);
    }
  }
  
  String get timeFormatted {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

