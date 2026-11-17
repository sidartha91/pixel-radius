import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'logic/quiz_models.dart';
import 'logic/quiz_strings.dart';
import 'logic/score_calculator.dart';
import 'widgets/procedural_skyline_widget.dart';
import 'widgets/quiz_option_button.dart';

export 'logic/score_calculator.dart' show AnswerOutcome, ScoreResult;

/// Mode Ombre Chinoise — widget d'entrée strictement autonome et réutilisable.
///
/// Aucune dépendance vers `lib/core` : il suffit de fournir le thème, la durée
/// et la langue. Les callbacks optionnels permettent à l'hôte de brancher sons,
/// sauvegarde des records et navigation.
class ShadowQuizGame extends StatefulWidget {
  const ShadowQuizGame({
    super.key,
    required this.isDarkMode,
    required this.durationSeconds,
    required this.languageCode,
    this.rounds = 10,
    this.catalogAssetPath = 'assets/data/capitals_catalog.json',
    this.allowedCityIds,
    this.onAnswer,
    this.onFinished,
    this.onExit,
  });

  final bool isDarkMode;
  final int durationSeconds;
  final String languageCode;
  final int rounds;
  final String catalogAssetPath;

  /// Villes cibles autorisées (ex. offre gratuite). `null` = toutes.
  final Set<String>? allowedCityIds;

  /// Appelé après chaque réponse (pour jouer un son, vibrer…).
  final void Function(ScoreResult result)? onAnswer;

  /// Appelé en fin de partie ; renvoie `true` si c'est un nouveau record.
  final Future<bool> Function(int totalScore)? onFinished;

  /// Sortie du jeu ; par défaut `Navigator.maybePop`.
  final VoidCallback? onExit;

  @override
  State<ShadowQuizGame> createState() => _ShadowQuizGameState();
}

class _QuizPalette {
  const _QuizPalette({
    required this.background,
    required this.surface,
    required this.silhouette,
    required this.secondary,
    required this.text,
    required this.muted,
  });

  final Color background;
  final Color surface;
  final Color silhouette;
  final Color secondary;
  final Color text;
  final Color muted;

  static const _QuizPalette dark = _QuizPalette(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    silhouette: Color(0xFFE5A93C),
    secondary: Color(0xFFFF007F),
    text: Color(0xFFF2EDE4),
    muted: Color(0xFF8A8478),
  );

  static const _QuizPalette light = _QuizPalette(
    background: Color(0xFFF5F2EB),
    surface: Color(0xFFEAE5D9),
    silhouette: Color(0xFF000000),
    secondary: Color(0xFFC86446),
    text: Color(0xFF111111),
    muted: Color(0xFF6E665A),
  );
}

class _ShadowQuizGameState extends State<ShadowQuizGame> {
  final math.Random _random = math.Random();

  ShadowQuizData? _data;
  SkylineComposer? _composer;
  Object? _loadError;

  List<QuizCity> _targets = const <QuizCity>[];
  int _roundIndex = 0;
  QuizRound? _round;
  SkylineComposition? _composition;

  Timer? _ticker;
  int _remainingMs = 0;
  bool _revealed = false;
  String? _selectedKey;
  ScoreResult? _result;

  int _total = 0;
  int _exactCount = 0;
  int _partialCount = 0;
  bool _finished = false;
  bool _isNewRecord = false;

  QuizStrings get _s => QuizStrings(widget.languageCode);
  _QuizPalette get _p => widget.isDarkMode ? _QuizPalette.dark : _QuizPalette.light;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        ShadowQuizData.load(widget.catalogAssetPath),
        SilhouetteAssetRegistry.load(),
      ]);
      if (!mounted) return;
      _data = results[0] as ShadowQuizData;
      _composer = SkylineComposer(results[1] as SilhouetteAssetRegistry);
      _startGame();
    } catch (e) {
      debugPrint('[ShadowQuiz] Chargement : $e');
      if (mounted) setState(() => _loadError = e);
    }
  }

  void _startGame() {
    final all = _data!.cities;
    var pool = widget.allowedCityIds == null
        ? List<QuizCity>.of(all)
        : all.where((c) => widget.allowedCityIds!.contains(c.id)).toList();
    if (pool.isEmpty) pool = List<QuizCity>.of(all);
    pool.shuffle(_random);
    setState(() {
      _targets = pool.take(math.min(widget.rounds, pool.length)).toList();
      _roundIndex = 0;
      _total = 0;
      _exactCount = 0;
      _partialCount = 0;
      _finished = false;
      _isNewRecord = false;
    });
    _startRound();
  }

  void _startRound() {
    final target = _targets[_roundIndex];
    final round = QuizRoundBuilder.build(
      target: target,
      allCities: _data!.cities,
      languageCode: widget.languageCode,
      random: _random,
    );
    setState(() {
      _round = round;
      _composition = _composer!.compose(target, _random);
      _revealed = false;
      _selectedKey = null;
      _result = null;
      _remainingMs = widget.durationSeconds * 1000;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _revealed) return;
      setState(() => _remainingMs -= 100);
      if (_remainingMs <= 0) _answer(null);
    });
  }

  void _answer(QuizOption? option) {
    if (_revealed || _round == null) return;
    _ticker?.cancel();
    final target = _round!.target;
    final result = ScoreCalculator.evaluate(
      selectedCityId: option?.cityId,
      selectedCountryCode: option?.countryCode,
      targetCityId: target.id,
      targetCountryCode: target.countryCode,
      secondsRemaining: (math.max(0, _remainingMs) / 1000).ceil(),
    );
    setState(() {
      _revealed = true;
      _selectedKey = option?.key;
      _result = result;
      _total += result.total;
      if (result.isExact) _exactCount++;
      if (result.isPartial) _partialCount++;
    });
    widget.onAnswer?.call(result);
  }

  Future<void> _next() async {
    if (_roundIndex + 1 < _targets.length) {
      _roundIndex++;
      _startRound();
      return;
    }
    setState(() => _finished = true);
    final record = await widget.onFinished?.call(_total) ?? false;
    if (mounted) setState(() => _isNewRecord = record);
  }

  void _exit() {
    _ticker?.cancel();
    if (widget.onExit != null) {
      widget.onExit!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: widget.isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.background,
        body: _loadError != null
            ? _buildMessage(_s.loadError, isError: true)
            : (_round == null || _composition == null)
                ? _buildMessage(_s.loading)
                : _buildGame(context),
      ),
    );
  }

  Widget _buildMessage(String text, {bool isError = false}) {
    final p = _p;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isError)
              const Icon(Icons.error_outline, color: QuizColors.wrong, size: 40)
            else
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(color: p.silhouette, strokeWidth: 2.5),
              ),
            const SizedBox(height: 16),
            Text(text, style: TextStyle(color: p.text, fontSize: 16)),
            if (isError) ...<Widget>[
              const SizedBox(height: 16),
              _ActionButton(label: _s.menu, color: p.silhouette, onPressed: _exit, autofocus: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGame(BuildContext context) {
    final p = _p;
    final size = MediaQuery.sizeOf(context);
    final bannerHeight = size.height * 0.40;

    return Column(
      children: <Widget>[
        SizedBox(
          height: bannerHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: ProceduralSkylineWidget(
                  key: ValueKey<String>(_composition!.signature),
                  composition: _composition!,
                  silhouetteColor: p.silhouette,
                  backgroundColor: p.background,
                  glowColor: p.secondary,
                ),
              ),
              SafeArea(bottom: false, child: _buildTopBar()),
            ],
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: _finished ? _buildSummary() : _buildRoundBody(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    final p = _p;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: <Widget>[
          _IconAction(icon: Icons.arrow_back_rounded, color: p.text, background: p.surface, onPressed: _exit),
          const Spacer(),
          _Chip(
            text: _s.round(math.min(_roundIndex + 1, _targets.length), _targets.length),
            color: p.text,
            background: p.surface.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 8),
          _Chip(
            text: '$_total pts',
            color: p.silhouette == const Color(0xFF000000) ? p.secondary : p.silhouette,
            background: p.surface.withValues(alpha: 0.85),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRoundBody() {
    return Column(
      children: <Widget>[
        _revealed ? _buildResultRow() : _buildTimerRow(),
        const SizedBox(height: 10),
        Expanded(child: _buildGrid()),
      ],
    );
  }

  Widget _buildTimerRow() {
    final p = _p;
    final total = widget.durationSeconds * 1000;
    final ratio = (_remainingMs / total).clamp(0.0, 1.0);
    final seconds = (math.max(0, _remainingMs) / 1000).ceil();
    final urgent = seconds <= 5;
    return SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _s.question,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: p.surface,
                    color: urgent ? QuizColors.wrong : (widget.isDarkMode ? p.silhouette : p.secondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 52,
            child: Text(
              '${seconds}s',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: urgent ? QuizColors.wrong : p.text,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow() {
    final p = _p;
    final r = _result!;
    final target = _round!.target;
    final (String label, Color color) = switch (r.outcome) {
      AnswerOutcome.exact => (_s.exact, QuizColors.correct),
      AnswerOutcome.sameCountry => (_s.rightCountry, QuizColors.partial),
      AnswerOutcome.wrong => (_s.wrong, QuizColors.wrong),
      AnswerOutcome.timeout => (_s.timeUp, QuizColors.wrong),
    };
    final isLast = _roundIndex + 1 >= _targets.length;
    return SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  r.total > 0 ? '$label  ${_s.points(r.total)}' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  _s.answerWas(target.name(widget.languageCode), target.country(widget.languageCode)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            label: isLast ? _s.results : _s.next,
            color: widget.isDarkMode ? p.silhouette : p.text,
            onPressed: _next,
            autofocus: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final p = _p;
    final options = _round!.options;
    final rows = (options.length / 2).ceil();
    const spacing = 8.0;

    return LayoutBuilder(builder: (context, constraints) {
      final extent = math.max(52.0, (constraints.maxHeight - spacing * (rows - 1)) / rows);
      return FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: GridView.builder(
          key: ValueKey<int>(_roundIndex),
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: extent,
          ),
          itemBuilder: (context, i) {
            final option = options[i];
            var state = OptionVisualState.idle;
            String? caption;
            if (_revealed) {
              final selected = option.key == _selectedKey;
              if (option.kind == QuizOptionKind.correct) {
                state = OptionVisualState.correct;
              } else if (selected && _result!.outcome == AnswerOutcome.sameCountry) {
                state = OptionVisualState.partial;
                caption = _s.rightCountry;
              } else if (selected) {
                state = OptionVisualState.wrong;
              } else {
                state = OptionVisualState.dimmed;
              }
            }
            return QuizOptionButton(
              city: option.cityLabel,
              country: option.countryLabel,
              caption: caption,
              state: state,
              autofocus: i == 0 && !_revealed,
              surfaceColor: p.surface,
              textColor: p.text,
              mutedColor: p.muted,
              onPressed: _revealed ? null : () => _answer(option),
            );
          },
        ),
      );
    });
  }

  Widget _buildSummary() {
    final p = _p;
    final accent = widget.isDarkMode ? p.silhouette : p.text;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_s.gameOver.toUpperCase(),
                style: TextStyle(color: p.muted, letterSpacing: 3, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              '$_total',
              style: TextStyle(color: accent, fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            Text(_s.totalScore, style: TextStyle(color: p.text, fontSize: 14)),
            const SizedBox(height: 10),
            Text(
              _s.summary(_exactCount, _partialCount, _targets.length),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted, fontSize: 13),
            ),
            if (_isNewRecord) ...<Widget>[
              const SizedBox(height: 12),
              Text('★ ${_s.newRecord}',
                  style: const TextStyle(color: QuizColors.correct, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: <Widget>[
                _ActionButton(label: _s.playAgain, color: accent, onPressed: _startGame, autofocus: true),
                _ActionButton(label: _s.menu, color: p.muted, onPressed: _exit, outlined: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Petits widgets internes ─────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, required this.background, this.bold = false});

  final String text;
  final Color color;
  final Color background;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

/// Bouton focusable générique (bordure #E5A93C 2.5px + scale 1.03 au focus).
class _Focusable extends StatefulWidget {
  const _Focusable({required this.builder, required this.onPressed, this.autofocus = false});

  final Widget Function(bool focused) builder;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_Focusable> createState() => _FocusableState();
}

class _FocusableState extends State<_Focusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: widget.autofocus,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onPressed();
          return null;
        }),
      },
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _focused ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: widget.builder(_focused),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.autofocus = false,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool autofocus;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black;
    return _Focusable(
      autofocus: autofocus,
      onPressed: onPressed,
      builder: (focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: focused ? QuizColors.focus : (outlined ? color : Colors.transparent),
            width: focused ? 2.5 : 1.2,
          ),
          boxShadow: focused
              ? <BoxShadow>[BoxShadow(color: QuizColors.focus.withValues(alpha: 0.45), blurRadius: 14)]
              : const <BoxShadow>[],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: outlined ? color : onColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.color, required this.background, required this.onPressed});

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _Focusable(
      onPressed: onPressed,
      builder: (focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: background.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: focused ? QuizColors.focus : Colors.transparent, width: 2.5),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
