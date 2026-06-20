import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class SettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;

  // Defaults
  ThemeMode _themeMode = ThemeMode.light;
  int _pomodoroDuration = 25; // in minutes
  int _shortBreakDuration = 5; // in minutes
  bool _hasSeenOnboarding = false;

  // Audio Player for ambient sounds
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _currentSound = 'none';

  final Map<String, String> _soundUrls = {
    'rain': 'sounds/rain.ogg',
    'nature': 'https://actions.google.com/sounds/v1/ambiences/jungle_ambience.ogg',
    'ocean': 'sounds/ocean.ogg',
    'thunder': 'sounds/thunder.ogg',
  };

  SettingsProvider(this._prefs) {
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _loadSettings();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  int get pomodoroDuration => _pomodoroDuration;
  int get shortBreakDuration => _shortBreakDuration;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String get currentSound => _currentSound;
  bool get isPlayingSound => _currentSound != 'none';

  void _loadSettings() {
    // Load theme
    final isDark = _prefs?.getBool('isDarkMode');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    // Load durations
    _pomodoroDuration = _prefs?.getInt('pomodoroDuration') ?? 25;
    _shortBreakDuration = _prefs?.getInt('shortBreakDuration') ?? 5;

    // Load onboarding
    _hasSeenOnboarding = _prefs?.getBool('hasSeenOnboarding') ?? false;

    // Load sound preference
    _currentSound = _prefs?.getString('currentSound') ?? 'none';
    if (_currentSound != 'none') {
      _playSound(_currentSound);
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _prefs?.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setPomodoroDuration(int minutes) async {
    _pomodoroDuration = minutes;
    await _prefs?.setInt('pomodoroDuration', minutes);
    notifyListeners();
  }

  Future<void> setShortBreakDuration(int minutes) async {
    _shortBreakDuration = minutes;
    await _prefs?.setInt('shortBreakDuration', minutes);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    await _prefs?.setBool('hasSeenOnboarding', true);
    notifyListeners();
  }

  Future<void> setAmbientSound(String soundKey) async {
    if (_currentSound == soundKey) return;
    
    _currentSound = soundKey;
    await _prefs?.setString('currentSound', soundKey);

    if (soundKey == 'none') {
      await _audioPlayer.stop();
    } else {
      await _playSound(soundKey);
    }
    notifyListeners();
  }

  Future<void> _playSound(String soundKey) async {
    final path = _soundUrls[soundKey];
    if (path != null) {
      try {
        if (path.startsWith('http')) {
          await _audioPlayer.play(UrlSource(path));
        } else {
          await _audioPlayer.play(AssetSource(path));
        }
      } catch (e) {
        print("Error playing ambient sound: $e");
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
