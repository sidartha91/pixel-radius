import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_scope.dart';
import '../core/audio/audio_manager.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/capital_model.dart';
import '../core/settings/app_settings.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/focusable_tap.dart';
import '../core/services/anecdote_service.dart';
import 'night_lights_layer.dart';
import 'world_map_layer.dart';

/// Barème du mode Classique : distance (km) + temps restant.
class ClassicScoring {
  const ClassicScoring._();

  static const int maxDistancePoints = 1000;
  static const double decayKm = 1500;
  static const int speedBonusPerSecond = 20;

  /// Points de précision : 1000 à 0 km, ~513 à 1000 km, ~36 à 5000 km.
  static int distancePoints(double km) =>
      (maxDistancePoints * math.exp(-km / decayKm)).round().clamp(0, maxDistancePoints);

  /// Bonus rapidité pondéré par la précision (un clic rapide mais lointain rapporte peu).
  static int speedBonus(double km, int secondsRemaining) =>
      (secondsRemaining * speedBonusPerSecond * distancePoints(km) / maxDistancePoints).round();

  static int total(double km, int secondsRemaining) =>
      distancePoints(km) + speedBonus(km, secondsRemaining);
}

class ClassicGameScreen extends StatefulWidget {
  const ClassicGameScreen({super.key, required this.durationSeconds, this.rounds = 10});

  final int durationSeconds;
  final int rounds;

  @override
  State<ClassicGameScreen> createState() => _ClassicGameScreenState();
}

class _ClassicGameScreenState extends State<ClassicGameScreen> {
  static const Color _neonPink = Color(0xFFFF007F);
  static const LatLng _worldCenter = LatLng(20, 10);
  static const Distance _distance = Distance();

  final MapController _mapController = MapController();
  final FocusNode _mapFocus = FocusNode(debugLabel: 'classic_map');

  List<CapitalModel> _targets = const <CapitalModel>[];
  int _roundIndex = 0;
  bool _isGuessing = true;
  LatLng? _guess;
  double? _distanceKm;
  int _roundPoints = 0;

  /// Anecdote « Le saviez-vous ? » affichée après validation.
  String? _anecdote;
  int _total = 0;
  bool _finished = false;
  bool _newRecord = false;
  bool _mapHasFocus = false;

  Timer? _ticker;
  int _remainingMs = 0;
  bool _initialized = false;

  CapitalModel get _target => _targets[_roundIndex];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final scope = AppScope.of(context);
    _targets = scope.catalog.drawRounds(premium: scope.purchases.isPremium, count: widget.rounds);
    _mapFocus.addListener(() => setState(() => _mapHasFocus = _mapFocus.hasFocus));
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRound());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _mapFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ───────────────────────────── Logique ─────────────────────────────

  void _startRound() {
    if (!mounted || _targets.isEmpty) return;
    setState(() {
      _isGuessing = true;
      _guess = null;
      _distanceKm = null;
      _roundPoints = 0;
      _anecdote = null;
      _remainingMs = widget.durationSeconds * 1000;
    });
    _mapController.move(_worldCenter, 1.8);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !_isGuessing) return;
      setState(() => _remainingMs -= 100);
      if (_remainingMs <= 0) _reveal();
    });
  }

  void _onMapTap(TapPosition _, LatLng point) {
    if (!_isGuessing) return;
    AppScope.of(context).audio.playSfx(Sfx.tap);
    setState(() => _guess = point);
  }

  void _reveal() {
    if (!_isGuessing) return;
    _ticker?.cancel();
    if (_mapFocus.hasFocus) _mapFocus.unfocus();
    final audio = AppScope.of(context).audio;
    final seconds = (math.max(0, _remainingMs) / 1000).ceil();
    final target = _target.position;

    double? km;
    var points = 0;
    if (_guess != null) {
      km = _distance.as(LengthUnit.Kilometer, _guess!, target);
      points = ClassicScoring.total(km, seconds);
    }

    setState(() {
      _isGuessing = false; // → InteractiveFlag.none : la carte se fige
      _distanceKm = km;
      _roundPoints = points;
      _total += points;
    });

    audio.playSfx(points >= 700 ? Sfx.correct : (points >= 250 ? Sfx.partial : Sfx.wrong));

    // Anecdote inédite sur la capitale / le pays.
    final targetId = _target.id;
    final lang = AppScope.of(context).settings.languageCode;
    AnecdoteService.instance().then((svc) => svc.next(targetId, lang)).then((text) {
      if (mounted && !_isGuessing && _target.id == targetId) setState(() => _anecdote = text);
    }).catchError((Object e) => debugPrint('[Anecdote] $e'));

    // Cadre la carte sur le clic du joueur et la vraie capitale.
    if (_guess != null) {
      _mapController.fitCamera(CameraFit.coordinates(
        coordinates: <LatLng>[_guess!, target],
        padding: const EdgeInsets.fromLTRB(60, 200, 60, 360),
        maxZoom: 7,
      ));
    } else {
      _mapController.move(target, 4);
    }
  }

  Future<void> _next() async {
    if (_roundIndex + 1 < _targets.length) {
      setState(() => _roundIndex++);
      _startRound();
      return;
    }
    final settings = AppScope.of(context).settings;
    final record = await settings.submitScore(GameMode.classic, widget.durationSeconds, _total);
    if (!mounted) return;
    setState(() {
      _finished = true;
      _newRecord = record;
    });
  }

  void _restart() {
    final scope = AppScope.of(context);
    setState(() {
      _targets = scope.catalog.drawRounds(premium: scope.purchases.isPremium, count: widget.rounds);
      _roundIndex = 0;
      _total = 0;
      _finished = false;
      _newRecord = false;
    });
    _startRound();
  }

  /// Navigation D-Pad / clavier sur la carte : flèches = déplacement,
  /// +/- = zoom, Entrée/Select = poser l'épingle au centre (réticule).
  KeyEventResult _onMapKey(FocusNode node, KeyEvent event) {
    if (!_isGuessing || event is KeyUpEvent) return KeyEventResult.ignored;
    final camera = _mapController.camera;
    final step = 60 / math.pow(2, camera.zoom);
    final key = event.logicalKey;
    LatLng? center;
    if (key == LogicalKeyboardKey.arrowUp) {
      center = LatLng((camera.center.latitude + step).clamp(-80.0, 80.0), camera.center.longitude);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      center = LatLng((camera.center.latitude - step).clamp(-80.0, 80.0), camera.center.longitude);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      center = LatLng(camera.center.latitude, camera.center.longitude - step);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      center = LatLng(camera.center.latitude, camera.center.longitude + step);
    } else if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd ||
        key == LogicalKeyboardKey.channelUp) {
      _mapController.move(camera.center, math.min(camera.zoom + 1, 8));
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract ||
        key == LogicalKeyboardKey.channelDown) {
      _mapController.move(camera.center, math.max(camera.zoom - 1, 1.5));
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA) {
      if (_guess != null && _sameSpot(_guess!, camera.center)) {
        _reveal();
      } else {
        setState(() => _guess = camera.center);
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.tab) {
      return KeyEventResult.ignored;
    }
    if (center != null) {
      _mapController.move(center, camera.zoom);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static const double _minZoom = 1.5;
  static const double _maxZoom = 8;

  void _zoomBy(double delta) {
    if (!_isGuessing) return;
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + delta).clamp(_minZoom, _maxZoom));
  }

  /// Pincement du pavé tactile (Mac / web) : le navigateur l'envoie comme un
  /// évènement « scale ». On zoome la carte en gardant le point sous les doigts.
  void _onPointerSignal(PointerSignalEvent event) {
    if (!_isGuessing || event is! PointerScaleEvent) return;
    if (event.scale <= 0) return;
    final camera = _mapController.camera;
    final delta = math.log(event.scale) / math.ln2;
    final zoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    if (zoom == camera.zoom) return;
    final center = camera.focusedZoomCenter(event.localPosition, zoom);
    _mapController.move(center, zoom);
  }

  void _recenter() {
    if (!_isGuessing) return;
    _mapController.move(_worldCenter, 1.8);
  }

  bool _sameSpot(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < 1e-6 && (a.longitude - b.longitude).abs() < 1e-6;

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final dark = scope.settings.isDarkMode;
    final p = PixelPalette.of(context);
    final l = AppLocalizations.of(context);
    final lang = scope.settings.languageCode;

    if (_targets.isEmpty) {
      return Scaffold(body: Center(child: Text(l.t('catalogError'))));
    }

    final markers = <Marker>[
      if (_guess != null)
        Marker(
          point: _guess!,
          width: 44,
          height: 44,
          alignment: Alignment.topCenter,
          child: const Icon(Icons.location_on_rounded, color: _neonPink, size: 44),
        ),
      if (!_isGuessing)
        Marker(
          point: _target.position,
          width: 160,
          height: 64,
          child: _TargetMarker(label: _target.cityName(lang), color: p.accent, background: p.surface),
        ),
    ];

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Focus(
              focusNode: _mapFocus,
              autofocus: true,
              onKeyEvent: _onMapKey,
              child: AbsorbPointer(
                // Double sécurité : en plus d'InteractiveFlag.none, aucun geste n'atteint la carte.
                absorbing: !_isGuessing,
                child: Listener(
                  onPointerSignal: _onPointerSignal,
                  child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _worldCenter,
                    initialZoom: 1.8,
                    minZoom: _minZoom,
                    maxZoom: _maxZoom,
                    backgroundColor: dark ? const Color(0xFF060505) : PixelColors.lightBackground,
                    interactionOptions: InteractionOptions(
                      // Pas de zoom au double-tap : l'épingle est posée immédiatement au toucher.
                      flags: _isGuessing ? InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom : InteractiveFlag.none,
                    ),
                    onTap: _onMapTap,
                  ),
                  children: <Widget>[
                    // Mode sombre : « la Terre la nuit » (étoiles, terres brunes, lumières des villes).
                    // Mode clair : carte « vinyle » épurée avec méridiens.
                    if (dark) const NightLightsLayer(kind: NightLayerKind.stars),
                    if (!dark)
                      PolylineLayer(
                        polylines: WorldMapLayer.graticule(p.accent.withValues(alpha: 0.12)),
                      ),
                    WorldMapLayer(
                      landColor: dark ? const Color(0xFF26120A) : const Color(0xFFE2DACA),
                      borderColor: dark ? const Color(0xFF3A1E0E) : p.accent.withValues(alpha: 0.45),
                    ),
                    if (dark) const NightLightsLayer(kind: NightLayerKind.lights),
                    if (!_isGuessing && _guess != null)
                      PolylineLayer(
                        polylines: <Polyline>[
                          Polyline(
                            points: <LatLng>[_guess!, _target.position],
                            color: _neonPink,
                            strokeWidth: 3.5,
                            pattern: StrokePattern.dashed(segments: const <double>[12, 8]),
                          ),
                        ],
                      ),
                    MarkerLayer(markers: markers),
                  ],
                ),
                ),
              ),
            ),
          ),
          if (_mapHasFocus && _isGuessing && FocusManager.instance.highlightMode == FocusHighlightMode.traditional)
            IgnorePointer(
              child: Center(child: Icon(Icons.add_rounded, size: 36, color: _neonPink.withValues(alpha: 0.9))),
            ),
          if (_isGuessing && !_finished)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: Center(
                  child: _ZoomControls(
                    surface: p.surface,
                    color: p.accent,
                    onZoomIn: () => _zoomBy(1),
                    onZoomOut: () => _zoomBy(-1),
                    onRecenter: _recenter,
                  ),
                ),
              ),
            ),
          SafeArea(child: _buildTopPanel(l, p, lang)),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(top: false, child: _buildBottomPanel(l, p, lang)),
          ),
          if (_finished) _buildSummary(l, p),
        ],
      ),
    );
  }

  Widget _buildTopPanel(AppLocalizations l, PixelPalette p, String lang) {
    final total = widget.durationSeconds * 1000;
    final ratio = (_remainingMs / total).clamp(0.0, 1.0);
    final seconds = (math.max(0, _remainingMs) / 1000).ceil();
    final urgent = _isGuessing && seconds <= 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              FocusableTap(
                onTap: () => Navigator.of(context).maybePop(),
                semanticLabel: l.t('backToMenu'),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  color: p.surface.withValues(alpha: 0.92),
                  child: Icon(Icons.arrow_back_rounded, color: p.onSurface),
                ),
              ),
              const Spacer(),
              _Pill(
                text: l.tf('round', <String, Object>{'n': _roundIndex + 1, 'total': _targets.length}),
                color: p.onSurface,
                background: p.surface.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 8),
              _Pill(text: '$_total pts', color: p.accent, background: p.surface.withValues(alpha: 0.92), bold: true),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.accent.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.t('whereIs'), style: TextStyle(color: p.muted, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: <InlineSpan>[
                          TextSpan(
                            text: _target.cityName(lang).toUpperCase(),
                            style: TextStyle(color: p.accent, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1),
                          ),
                          TextSpan(
                            text: '  ${_target.countryName(lang)}',
                            style: TextStyle(color: p.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${seconds}s',
                      style: TextStyle(
                        color: urgent ? PixelColors.wrong : p.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: p.background,
                    color: urgent ? PixelColors.wrong : p.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(AppLocalizations l, PixelPalette p, String lang) {
    if (_finished) return const SizedBox.shrink();

    final Widget content;
    if (_isGuessing) {
      content = Row(
        children: <Widget>[
          Expanded(
            child: Text(
              l.t('tapToPlace'),
              style: TextStyle(color: p.muted, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          _PrimaryButton(
            label: l.t('validate'),
            enabled: _guess != null,
            color: p.accent,
            onColor: p.background,
            onTap: _reveal,
          ),
        ],
      );
    } else {
      final km = _distanceKm;
      final quality = _roundPoints >= 700
          ? PixelColors.correct
          : (_roundPoints >= 250 ? PixelColors.partial : PixelColors.wrong);
      final isLast = _roundIndex + 1 >= _targets.length;
      content = Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  km == null ? l.t('timeUp') : l.tf('distance', <String, Object>{'km': km.round()}),
                  style: TextStyle(color: p.onSurface, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  km == null
                      ? l.t('noGuess')
                      : l.tf('pointsGained', <String, Object>{'pts': _roundPoints}),
                  style: TextStyle(color: quality, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PrimaryButton(
            label: isLast ? l.t('seeResults') : l.t('next'),
            enabled: true,
            autofocus: true,
            color: p.accent,
            onColor: p.background,
            onTap: _next,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!_isGuessing && _anecdote != null) _AnecdoteBanner(text: _anecdote!, title: l.t('didYouKnow')),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(AppLocalizations l, PixelPalette p) {
    return Positioned.fill(
      child: ColoredBox(
        color: p.background.withValues(alpha: 0.88),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l.t('gameOver').toUpperCase(),
                      style: TextStyle(color: p.muted, letterSpacing: 3, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text('$_total',
                      style: TextStyle(color: p.accent, fontSize: 60, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Text(l.t('totalScore'), style: TextStyle(color: p.onSurface)),
                  if (_newRecord) ...<Widget>[
                    const SizedBox(height: 12),
                    Text('★ ${l.t('newRecord')}',
                        style: const TextStyle(color: PixelColors.correct, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      _PrimaryButton(
                        label: l.t('playAgain'),
                        enabled: true,
                        autofocus: true,
                        color: p.accent,
                        onColor: p.background,
                        onTap: _restart,
                      ),
                      _PrimaryButton(
                        label: l.t('backToMenu'),
                        enabled: true,
                        color: p.surface,
                        onColor: p.onSurface,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau « Le saviez-vous ? » sous la carte, après validation.
class _AnecdoteBanner extends StatelessWidget {
  const _AnecdoteBanner({required this.text, required this.title});

  final String text;
  final String title;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: p.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.lightbulb_rounded, color: p.accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title.toUpperCase(),
                          style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.4)),
                      const SizedBox(height: 3),
                      Text(text, style: TextStyle(color: p.onSurface, fontSize: 13.5, height: 1.35)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boutons de zoom visibles (web, mobile, TV / D-Pad).
class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.surface,
    required this.color,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  final Color surface;
  final Color color;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  Widget _button(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Tooltip(
        message: label,
        child: FocusableTap(
          onTap: onTap,
          semanticLabel: label,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: surface.withValues(alpha: 0.94),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10)],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _button(Icons.add_rounded, 'Zoom +', onZoomIn),
        _button(Icons.remove_rounded, 'Zoom −', onZoomOut),
        _button(Icons.public_rounded, 'Monde', onRecenter),
      ],
    );
  }
}

class _TargetMarker extends StatelessWidget {
  const _TargetMarker({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: PixelColors.correct,
            shape: BoxShape.circle,
            border: Border.all(color: background, width: 3),
            boxShadow: <BoxShadow>[BoxShadow(color: PixelColors.correct.withValues(alpha: 0.7), blurRadius: 14)],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, required this.background, this.bold = false});

  final String text;
  final Color color;
  final Color background;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.color,
    required this.onColor,
    required this.onTap,
    this.autofocus = false,
  });

  final String label;
  final bool enabled;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return FocusableTap(
      onTap: enabled ? onTap : null,
      autofocus: autofocus,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          color: color,
          child: Text(
            label,
            style: TextStyle(color: onColor, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }
}
