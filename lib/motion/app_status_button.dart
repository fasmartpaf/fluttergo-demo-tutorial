import 'package:flutter/material.dart';

import 'app_draw_check.dart';
import 'app_motion.dart';

enum ActionStatus { idle, loading, done }

/// Primary action that shows its own result: idle → spinner → done.
///
/// Keeps its height, swaps its label with a short slide, and on success
/// shrinks to a pill in [doneColor] with a check that draws itself.
/// Booking, paying, saving, sending, joining.
///
/// ```dart
/// AppStatusButton(
///   status: status, label: 'Confirm · \$45', doneLabel: 'Booked',
///   onPressed: () async { setState(() => status = ActionStatus.loading); ... },
/// )
/// ```
class AppStatusButton extends StatelessWidget {
  const AppStatusButton({
    super.key,
    required this.status,
    required this.label,
    required this.onPressed,
    this.doneLabel = 'Done',
    this.color,
    this.doneColor = const Color(0xFF1E8E4E),
    this.foreground = const Color(0xFFFFFFFF),
    this.height = 48,
    this.radius,
    this.doneWidthFactor = 0.66,
    this.textStyle,
  });

  final ActionStatus status;
  final String label;
  final String doneLabel;
  final VoidCallback? onPressed;
  final Color? color;
  final Color doneColor;
  final Color foreground;
  final double height;

  /// Corner radius; defaults to a full pill.
  final double? radius;

  /// Width of the done pill relative to the idle width.
  final double doneWidthFactor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.primary;
    final style = (textStyle ?? Theme.of(context).textTheme.labelLarge ?? const TextStyle())
        .copyWith(color: foreground, fontWeight: FontWeight.w600);
    final r = BorderRadius.circular(radius ?? height / 2);
    final done = status == ActionStatus.done;

    final Widget content = switch (status) {
      ActionStatus.idle => Text(label, key: const ValueKey('idle'), style: style),
      ActionStatus.loading => SizedBox.square(
          key: const ValueKey('loading'),
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
        ),
      ActionStatus.done => Row(
          key: const ValueKey('done'),
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDrawCheck(size: 20, color: foreground, delay: AppMotion.sm),
            const SizedBox(width: 8),
            Text(doneLabel, style: style),
          ],
        ),
    };

    return LayoutBuilder(
      builder: (context, box) {
        final full = box.hasBoundedWidth ? box.maxWidth : 240.0;
        return Center(
          child: Semantics(
            button: true,
            liveRegion: true,
            label: switch (status) {
              ActionStatus.idle => label,
              ActionStatus.loading => '$label, in progress',
              ActionStatus.done => doneLabel,
            },
            child: AnimatedContainer(
              duration: AppMotion.resolve(context, AppMotion.xl, essential: true),
              curve: AppMotion.curve(context, AppMotion.pop),
              width: done ? full * doneWidthFactor : full,
              height: height,
              decoration: BoxDecoration(color: done ? doneColor : bg, borderRadius: r),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: r,
                  onTap: status == ActionStatus.idle ? onPressed : null,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: AppMotion.resolve(context, AppMotion.md, essential: true),
                      switchInCurve: AppMotion.enter,
                      switchOutCurve: AppMotion.exitCurve,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
                              .animate(a),
                          child: child,
                        ),
                      ),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
