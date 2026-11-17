import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Sfx { correct, partial, wrong, tap }

/// Boucle musicale Neo-Soul infinie + effets sonores, avec Mute persistant.
class AudioManager extends ChangeNotifier with WidgetsBindingObserver {
  AudioManager._(this._prefs);

  static const String _kMuted = 'audio.isMuted';
  static const String _musicAsset = 'audio/theme_loop.m4a'; // relatif à assets/
  static const double _musicVolume = 0.55;

  static const Map<Sfx, String> _sfxAssets = <Sfx, String>{
    Sfx.correct: 'audio/sfx/correct.m4a',
    Sfx.partial: 'audio/sfx/partial.m4a',
    Sfx.wrong: 'audio/sfx/wrong.m4a',
    Sfx.tap: 'audio/sfx/tap.m4a',
  };

  final SharedPreferences _prefs;
  final AudioPlayer _music = AudioPlayer(playerId: 'pixel_radius_music');
  final Map<Sfx, AudioPlayer> _sfxPlayers = <Sfx, AudioPlayer>{};
  final Set<String> _availableAssets = <String>{};

  bool _isMuted = false;
  bool _musicReady = false;
  bool _musicStarted = false;

  bool get isMuted => _isMuted;

  static Future<AudioManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    final manager = AudioManager._(prefs);
    manager._isMuted = prefs.getBool(_kMuted) ?? false;
    await manager._init();
    return manager;
  }

  Future<void> _init() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _availableAssets.addAll(manifest.listAssets());
    } catch (e) {
      debugPrint('[AudioManager] Manifest indisponible : $e');
    }

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
    } catch (e) {
      debugPrint('[AudioManager] AudioContext non appliqué : $e');
    }

    if (_availableAssets.contains('assets/$_musicAsset')) {
      try {
        await _music.setReleaseMode(ReleaseMode.loop);
        await _music.setVolume(_musicVolume);
        await _music.setSource(AssetSource(_musicAsset));
        _musicReady = true;
      } catch (e) {
        debugPrint('[AudioManager] Musique non chargée : $e');
      }
    }

    for (final entry in _sfxAssets.entries) {
      if (!_availableAssets.contains('assets/${entry.value}')) continue;
      try {
        final player = AudioPlayer(playerId: 'pixel_radius_sfx_${entry.key.name}');
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(entry.value));
        _sfxPlayers[entry.key] = player;
      } catch (e) {
        debugPrint('[AudioManager] SFX ${entry.key} non chargé : $e');
      }
    }
  }

  /// Démarre la boucle (à appeler après le premier frame).
  Future<void> startMusic() async {
    if (!_musicReady || _isMuted) return;
    try {
      await _music.resume();
      _musicStarted = true;
    } catch (e) {
      debugPrint('[AudioManager] Lecture impossible : $e');
    }
  }

  Future<void> toggleMute() => setMuted(!_isMuted);

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    notifyListeners();
    await _prefs.setBool(_kMuted, muted);
    if (!_musicReady) return;
    try {
      if (muted) {
        await _music.pause();
      } else {
        await startMusic();
      }
    } catch (e) {
      debugPrint('[AudioManager] Bascule mute : $e');
    }
  }

  Future<void> playSfx(Sfx sfx) async {
    // Retour haptique toujours actif (même si muet), utile sur mobile.
    switch (sfx) {
      case Sfx.correct:
        HapticFeedback.mediumImpact();
      case Sfx.partial:
        HapticFeedback.lightImpact();
      case Sfx.wrong:
        HapticFeedback.heavyImpact();
      case Sfx.tap:
        HapticFeedback.selectionClick();
    }
    if (_isMuted) return;
    final player = _sfxPlayers[sfx];
    if (player == null) {
      if (sfx == Sfx.tap) SystemSound.play(SystemSoundType.click);
      return;
    }
    try {
      await player.stop();
      await player.resume();
    } catch (e) {
      debugPrint('[AudioManager] SFX $sfx : $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_musicReady) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _music.pause();
    } else if (state == AppLifecycleState.resumed && !_isMuted && _musicStarted) {
      _music.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _music.dispose();
    for (final p in _sfxPlayers.values) {
      p.dispose();
    }
    super.dispose();
  }
}
