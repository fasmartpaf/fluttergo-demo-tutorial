import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Press feedback for any custom tappable (cards, tiles, chips, custom buttons).
///
/// Scales to 0.97 while pressed (opacity 0.7 under reduced motion) and
/// reacts within 100 ms. Material buttons already have feedback; use this
/// for everything else.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = AppMotion.pressScale,
    this.haptic = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  /// Plays `HapticFeedback.selectionClick()` on tap.
  final bool haptic;
  final String? semanticLabel;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap == null || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final enabled = widget.onTap != null;
    final Widget body = reduce
        ? AnimatedOpacity(
            opacity: _pressed ? 0.7 : 1,
            duration: AppMotion.xs,
            curve: AppMotion.standard,
            child: widget.child,
          )
        : AnimatedScale(
            scale: _pressed ? widget.scale : 1,
            duration: AppMotion.xs,
            curve: AppMotion.standard,
            child: widget.child,
          );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: enabled
            ? () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: body,
      ),
    );
  }
}
