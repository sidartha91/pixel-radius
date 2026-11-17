import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Couleurs de feedback (dupliquées ici pour garder le module autonome).
class QuizColors {
  QuizColors._();

  static const Color correct = Color(0xFF00FF66);
  static const Color partial = Color(0xFFFF9500);
  static const Color wrong = Color(0xFFFF3B3B);
  static const Color focus = Color(0xFFE5A93C);
}

enum OptionVisualState { idle, correct, partial, wrong, dimmed }

/// Bouton de proposition : VILLE en gras, PAYS en sous-titre.
/// Navigable au D-Pad / clavier (bordure #E5A93C 2.5px + scale 1.03).
class QuizOptionButton extends StatefulWidget {
  const QuizOptionButton({
    super.key,
    required this.city,
    required this.country,
    required this.state,
    required this.onPressed,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    this.caption,
    this.autofocus = false,
  });

  final String city;
  final String country;
  final OptionVisualState state;
  final VoidCallback? onPressed;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final String? caption;
  final bool autofocus;

  @override
  State<QuizOptionButton> createState() => _QuizOptionButtonState();
}

class _QuizOptionButtonState extends State<QuizOptionButton> {
  bool _focused = false;
  bool _hovered = false;

  static final Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
  };

  Color? get _stateColor => switch (widget.state) {
        OptionVisualState.correct => QuizColors.correct,
        OptionVisualState.partial => QuizColors.partial,
        OptionVisualState.wrong => QuizColors.wrong,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final stateColor = _stateColor;
    final dimmed = widget.state == OptionVisualState.dimmed;
    final bg = stateColor != null ? stateColor.withValues(alpha: 0.18) : widget.surfaceColor;
    final borderColor = _focused
        ? QuizColors.focus
        : (stateColor ?? widget.textColor.withValues(alpha: 0.08));
    final borderWidth = _focused ? 2.5 : (stateColor != null ? 2.0 : 1.0);
    // Le texte reste lisible dans les deux thèmes ; la couleur d'état est portée
    // par le fond teinté, la bordure et le halo.
    final cityColor = widget.textColor;

    return Semantics(
      button: true,
      label: '${widget.city}, ${widget.country}',
      child: FocusableActionDetector(
        autofocus: widget.autofocus,
        enabled: widget.onPressed != null,
        shortcuts: _shortcuts,
        mouseCursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          }),
        },
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        child: AnimatedScale(
          scale: (_focused || _hovered) && widget.onPressed != null ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: AnimatedOpacity(
            opacity: dimmed ? 0.38 : 1,
            duration: const Duration(milliseconds: 220),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                canRequestFocus: false,
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: borderWidth),
                    boxShadow: _focused
                        ? <BoxShadow>[BoxShadow(color: QuizColors.focus.withValues(alpha: 0.4), blurRadius: 12)]
                        : (stateColor != null
                            ? <BoxShadow>[BoxShadow(color: stateColor.withValues(alpha: 0.35), blurRadius: 10)]
                            : const <BoxShadow>[]),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.city.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cityColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.caption ?? widget.country,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.caption != null ? (stateColor ?? widget.mutedColor) : widget.mutedColor,
                          fontWeight: widget.caption != null ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
