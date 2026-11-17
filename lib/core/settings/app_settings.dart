import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_localizations.dart';

enum GameMode { classic, shadow }

/// Préférences persistées : thème, langue, timer, mode, meilleurs scores.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  static const List<int> timerOptions = <int>[15, 20, 25, 30];

  static const String _kDark = 'settings.isDarkMode';
  static const String _kLang = 'settings.languageCode';
  static const String _kTimer = 'settings.timerSeconds';
  static const String _kMode = 'settings.gameMode';
  static const String _kBestPrefix = 'scores.best.';

  final SharedPreferences _prefs;

  late bool _isDarkMode;
  late String _languageCode;
  late int _timerSeconds;
  late GameMode _gameMode;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings._(prefs);
    settings._isDarkMode = prefs.getBool(_kDark) ?? true;
    settings._languageCode = prefs.getString(_kLang) ?? _deviceLanguage();
    final storedTimer = prefs.getInt(_kTimer) ?? 20;
    settings._timerSeconds = timerOptions.contains(storedTimer) ? storedTimer : 20;
    settings._gameMode = (prefs.getString(_kMode) ?? 'classic') == 'shadow' ? GameMode.shadow : GameMode.classic;
    return settings;
  }

  static String _deviceLanguage() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return AppLocalizations.supportedLanguageCodes.contains(code) ? code : 'fr';
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);
  int get timerSeconds => _timerSeconds;
  GameMode get gameMode => _gameMode;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _prefs.setBool(_kDark, _isDarkMode);
  }

  Future<void> setLanguage(String code) async {
    if (!AppLocalizations.supportedLanguageCodes.contains(code) || code == _languageCode) return;
    _languageCode = code;
    notifyListeners();
    await _prefs.setString(_kLang, code);
  }

  Future<void> setTimer(int seconds) async {
    if (!timerOptions.contains(seconds) || seconds == _timerSeconds) return;
    _timerSeconds = seconds;
    notifyListeners();
    await _prefs.setInt(_kTimer, seconds);
  }

  Future<void> setGameMode(GameMode mode) async {
    if (mode == _gameMode) return;
    _gameMode = mode;
    notifyListeners();
    await _prefs.setString(_kMode, mode == GameMode.shadow ? 'shadow' : 'classic');
  }

  String _bestKey(GameMode mode, int timer) => '$_kBestPrefix${mode.name}.$timer';

  int bestScore(GameMode mode, int timer) => _prefs.getInt(_bestKey(mode, timer)) ?? 0;

  /// Enregistre le score s'il bat le record. Retourne true si nouveau record.
  Future<bool> submitScore(GameMode mode, int timer, int score) async {
    if (score <= bestScore(mode, timer)) return false;
    await _prefs.setInt(_bestKey(mode, timer), score);
    notifyListeners();
    return true;
  }
}
