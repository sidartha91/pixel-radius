import 'dart:async';

import 'package:flutter/material.dart';

import '../classic_mode/classic_game_screen.dart';
import '../core/app_scope.dart';
import '../core/audio/audio_manager.dart';
import '../core/localization/app_localizations.dart';
import '../core/monetization/purchase_manager.dart';
import '../core/settings/app_settings.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/focusable_tap.dart';
import '../shadow_quiz/shadow_quiz_game.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  StreamSubscription<PurchaseEvent>? _purchaseSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _purchaseSub ??= AppScope.of(context).purchases.events.listen(_onPurchaseEvent);
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  void _onPurchaseEvent(PurchaseEvent event) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final key = switch (event) {
      PurchaseEvent.purchased => 'purchaseSuccess',
      PurchaseEvent.restored => 'restoreDone',
      PurchaseEvent.nothingToRestore => 'restoreNothing',
      PurchaseEvent.error => 'purchaseError',
      PurchaseEvent.storeUnavailable => 'storeUnavailable',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.t(key))));
  }

  Future<void> _play() async {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final audio = scope.audio;
    final premium = scope.purchases.isPremium;
    unawaited(audio.playSfx(Sfx.tap));

    final Widget screen;
    if (settings.gameMode == GameMode.classic) {
      screen = ClassicGameScreen(durationSeconds: settings.timerSeconds);
    } else {
      final timer = settings.timerSeconds;
      screen = ShadowQuizGame(
        isDarkMode: settings.isDarkMode,
        durationSeconds: timer,
        languageCode: settings.languageCode,
        allowedCityIds: premium
            ? null
            : scope.catalog.playable(premium: false).map((c) => c.id).toSet(),
        onAnswer: (result) => audio.playSfx(switch (result.outcome) {
          AnswerOutcome.exact => Sfx.correct,
          AnswerOutcome.sameCountry => Sfx.partial,
          _ => Sfx.wrong,
        }),
        onFinished: (score) => settings.submitScore(GameMode.shadow, timer, score),
      );
    }
    await Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    ));
  }

  Future<void> _pickLanguage() async {
    final settings = AppScope.of(context).settings;
    final p = PixelPalette.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: p.surface,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final code in AppLocalizations.supportedLanguageCodes)
                FocusableTap(
                  autofocus: code == settings.languageCode,
                  selected: code == settings.languageCode,
                  semanticLabel: AppLocalizations.nativeName(code),
                  onTap: () => Navigator.of(ctx).pop(code),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: code == settings.languageCode ? p.accent.withValues(alpha: 0.18) : p.background,
                    child: Column(
                      children: <Widget>[
                        Text(AppLocalizations.shortLabel(code),
                            style: TextStyle(color: p.accent, fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(AppLocalizations.nativeName(code), style: TextStyle(color: p.onSurface)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await settings.setLanguage(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final audio = scope.audio;
    final purchases = scope.purchases;
    final l = AppLocalizations.of(context);
    final p = PixelPalette.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.2,
            colors: <Color>[
              Color.lerp(p.background, p.secondary, settings.isDarkMode ? 0.10 : 0.06)!,
              p.background,
            ],
          ),
        ),
        child: SafeArea(
          child: FocusTraversalGroup(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            _TopBar(
                              languageCode: settings.languageCode,
                              isMuted: audio.isMuted,
                              isDark: settings.isDarkMode,
                              onLanguage: _pickLanguage,
                              onMusic: audio.toggleMute,
                              onTheme: settings.toggleTheme,
                            ),
                            const SizedBox(height: 18),
                            _Title(
                              best: settings.bestScore(settings.gameMode, settings.timerSeconds),
                            ),
                            const SizedBox(height: 26),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _ModeCard(
                                    icon: Icons.place_rounded,
                                    title: l.modeClassic,
                                    subtitle: l.modeClassicDesc,
                                    selected: settings.gameMode == GameMode.classic,
                                    onTap: () => settings.setGameMode(GameMode.classic),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ModeCard(
                                    icon: Icons.visibility_rounded,
                                    title: l.modeShadow,
                                    subtitle: l.modeShadowDesc,
                                    selected: settings.gameMode == GameMode.shadow,
                                    onTap: () => settings.setGameMode(GameMode.shadow),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            _TimerSelector(
                              label: l.timer,
                              value: settings.timerSeconds,
                              onChanged: settings.setTimer,
                            ),
                            const SizedBox(height: 14),
                            _PlayButton(label: l.play, onTap: _play),
                            const SizedBox(height: 22),
                            _Footer(
                              purchases: purchases,
                              freeCount: scope.catalog.freeCount,
                              totalCount: scope.catalog.capitals.length,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Barre supérieure ─────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.languageCode,
    required this.isMuted,
    required this.isDark,
    required this.onLanguage,
    required this.onMusic,
    required this.onTheme,
  });

  final String languageCode;
  final bool isMuted;
  final bool isDark;
  final VoidCallback onLanguage;
  final VoidCallback onMusic;
  final VoidCallback onTheme;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        FocusableTap(
          onTap: onLanguage,
          semanticLabel: l.t('language'),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: p.surface,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.translate_rounded, size: 18, color: p.accent),
                const SizedBox(width: 6),
                Text(AppLocalizations.shortLabel(languageCode),
                    style: TextStyle(color: p.onSurface, fontWeight: FontWeight.w800, letterSpacing: 1)),
                Icon(Icons.arrow_drop_down_rounded, color: p.muted),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundIconButton(
          icon: isMuted ? Icons.music_off_rounded : Icons.music_note_rounded,
          tooltip: l.t(isMuted ? 'musicOff' : 'musicOn'),
          onTap: onMusic,
        ),
        const SizedBox(width: 10),
        _RoundIconButton(
          icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          tooltip: l.t('themeToggle'),
          onTap: onTheme,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: FocusableTap(
        onTap: onTap,
        semanticLabel: tooltip,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          color: p.surface,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(icon, key: ValueKey<IconData>(icon), color: p.accent, size: 22),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Titre ─────────────────────────────

class _Title extends StatelessWidget {
  const _Title({required this.best});

  final int best;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'PIXEL RADIUS',
            style: TextStyle(
              color: p.accent,
              fontSize: 46,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              height: 1,
              shadows: dark
                  ? <Shadow>[
                      Shadow(color: p.accent.withValues(alpha: 0.55), blurRadius: 18),
                      Shadow(color: p.secondary.withValues(alpha: 0.35), blurRadius: 32, offset: const Offset(0, 4)),
                    ]
                  : <Shadow>[Shadow(color: p.secondary.withValues(alpha: 0.35), offset: const Offset(3, 3))],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(width: 22, height: 1.5, color: p.secondary),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                l.appSubtitle,
                style: TextStyle(
                  color: p.secondary,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
            ),
            Container(width: 22, height: 1.5, color: p.secondary),
          ],
        ),
        const SizedBox(height: 8),
        Text(l.t('tagline'), style: TextStyle(color: p.muted, fontSize: 13, letterSpacing: 0.5)),
        if (best > 0) ...<Widget>[
          const SizedBox(height: 10),
          Text('${l.t('bestScore')} · $best',
              style: TextStyle(color: p.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ],
    );
  }
}

// ───────────────────────────── Cartes de mode ─────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return FocusableTap(
      onTap: onTap,
      selected: selected,
      semanticLabel: '$title — $subtitle',
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // Carte choisie : fond plein couleur d'accent, texte inversé.
          color: selected ? p.accent : p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? p.accent : p.onSurface.withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: selected
              ? <BoxShadow>[BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 18)]
              : const <BoxShadow>[],
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 36, color: selected ? p.background : p.muted),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: selected ? p.background : p.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? p.background.withValues(alpha: 0.8) : p.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.check_circle_rounded, size: 22, color: p.background),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Timer ─────────────────────────────

class _TimerSelector extends StatelessWidget {
  const _TimerSelector({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.timer_outlined, size: 16, color: p.muted),
            const SizedBox(width: 6),
            Text(label.toUpperCase(),
                style: TextStyle(color: p.muted, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: <Widget>[
              for (final s in AppSettings.timerOptions)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: FocusableTap(
                      onTap: () => onChanged(s),
                      selected: s == value,
                      semanticLabel: '$s s',
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: s == value ? p.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${s}s',
                          style: TextStyle(
                            color: s == value ? p.background : p.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── Bouton JOUER ─────────────────────────────

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return FocusableTap(
      onTap: onTap,
      autofocus: true,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 60,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: <BoxShadow>[
            BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.play_arrow_rounded, color: p.background, size: 30),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: p.background, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 4),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Pied de page ─────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.purchases, required this.freeCount, required this.totalCount});

  final PurchaseManager purchases;
  final int freeCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final l = AppLocalizations.of(context);
    final busy = purchases.isBusy;

    return Column(
      children: <Widget>[
        if (purchases.isPremium)
          Text(l.premiumActive, style: TextStyle(color: p.accent, fontWeight: FontWeight.w700, fontSize: 13))
        else ...<Widget>[
          Text(
            l.tf('freeCitiesInfo', <String, Object>{'free': freeCount, 'total': totalCount}),
            style: TextStyle(color: p.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          FocusableTap(
            onTap: busy ? null : purchases.buyPremium,
            semanticLabel: l.unlockWorld,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: p.secondary.withValues(alpha: 0.7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.public_rounded, size: 16, color: p.secondary),
                  const SizedBox(width: 6),
                  Text(
                    purchases.premiumPrice != null
                        ? '${l.unlockWorld} · ${purchases.premiumPrice}'
                        : l.unlockWorld,
                    style: TextStyle(color: p.secondary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        FocusableTap(
          onTap: busy ? null : purchases.restorePurchases,
          semanticLabel: l.restorePurchases,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: p.muted),
                  )
                : Text(
                    l.restorePurchases,
                    style: TextStyle(
                      color: p.muted,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: p.muted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
