import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Élément tactile navigable au D-Pad / télécommande / clavier.
/// Focus : bordure lumineuse #E5A93C 2.5px + scale 1.03.
class FocusableTap extends StatefulWidget {
  const FocusableTap({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final bool selected;

  @override
  State<FocusableTap> createState() => _FocusableTapState();
}

class _FocusableTapState extends State<FocusableTap> {
  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;
  FocusNode? _ownNode;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'FocusableTap'));

  @override
  void dispose() {
    _ownNode?.dispose();
    super.dispose();
  }

  static final Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
  };

  void _activate() {
    if (widget.onTap == null) return;
    widget.onTap!();
  }

  /// Au toucher/clic, le focus suit l'élément touché : le cadre de focus ne
  /// reste jamais « collé » sur un autre bouton.
  void _tap() {
    if (widget.onTap == null) return;
    _node.requestFocus();
    _activate();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final highlight = _focused || _hovered;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        autofocus: widget.autofocus,
        focusNode: _node,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        shortcuts: _shortcuts,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _activate();
            return null;
          }),
        },
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: enabled ? _tap : null,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : (highlight ? PixelColors.focusScale : 1.0),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                border: Border.all(
                  color: _focused ? PixelColors.focusRing : Colors.transparent,
                  width: PixelColors.focusRingWidth,
                ),
                boxShadow: _focused
                    ? <BoxShadow>[
                        BoxShadow(
                          color: PixelColors.focusRing.withValues(alpha: 0.45),
                          blurRadius: 14,
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: ClipRRect(borderRadius: widget.borderRadius, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
