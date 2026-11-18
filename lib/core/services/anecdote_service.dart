import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Anecdotes « Le saviez-vous ? » de tous les modes de jeu.
///
/// Pour chaque capitale, on tire une anecdote jamais vue sur cet appareil.
/// Quand toutes ont été lues, le cycle recommence, sans jamais répéter deux
/// fois de suite la même.
class AnecdoteService {
  AnecdoteService._(this._data, this._prefs);

  static const String assetPath = 'assets/data/anecdotes.json';
  static const String _seenPrefix = 'anecdotes.seen.';
  static const String _lastPrefix = 'anecdotes.last.';
  static Future<AnecdoteService>? _instance;

  final Map<String, List<Map<String, String>>> _data;
  final SharedPreferences _prefs;
  final Random _random = Random();

  static Future<AnecdoteService> instance() {
    return _instance ??= () async {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final map = <String, List<Map<String, String>>>{};
      (json['anecdotes'] as Map<String, dynamic>).forEach((id, list) {
        map[id] = (list as List)
            .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))
            .toList(growable: false);
      });
      return AnecdoteService._(map, await SharedPreferences.getInstance());
    }();
  }

  /// Renvoie une anecdote inédite pour [cityId], dans la langue demandée
  /// (repli sur l'anglais, puis le français). `null` si aucune n'existe.
  Future<String?> next(String cityId, String languageCode) async {
    final list = _data[cityId];
    if (list == null || list.isEmpty) return null;

    final seenKey = '$_seenPrefix$cityId';
    final lastKey = '$_lastPrefix$cityId';
    final seen = (_prefs.getStringList(seenKey) ?? const <String>[]).map(int.tryParse).whereType<int>().toSet();
    final last = _prefs.getInt(lastKey);

    var candidates = <int>[for (var i = 0; i < list.length; i++) if (!seen.contains(i)) i];
    if (candidates.isEmpty) {
      // Cycle terminé : on repart de zéro, en évitant la dernière affichée.
      seen.clear();
      candidates = <int>[for (var i = 0; i < list.length; i++) if (i != last || list.length == 1) i];
    }
    final pick = candidates[_random.nextInt(candidates.length)];
    seen.add(pick);
    await _prefs.setStringList(seenKey, seen.map((e) => '$e').toList());
    await _prefs.setInt(lastKey, pick);

    final entry = list[pick];
    return entry[languageCode] ?? entry['en'] ?? entry['fr'];
  }
}
