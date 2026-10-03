import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Types [text] one character at a time with a blinking caret.
/// Use only to *demonstrate* input (onboarding, empty-state examples,
/// assistant replies) — never for text the user is waiting to read.
class AppTypewriter extends StatefulWidget {
  const AppTypewriter({
    super.key,
    required this.text,
    this.style,
    this.delay = Duration.zero,
    this.perChar = const Duration(milliseconds: 45),
    this.showCaret = true,
    this.onDone,
  });

  final String text;
  final TextStyle? style;
  final Duration delay;
  final Duration perChar;
  final bool showCaret;
  final VoidCallback? onDone;

  @override
  State<AppTypewriter> createState() => _AppTypewriterState();
}

class _AppTypewriterState extends State<AppTypewriter> {
  int _count = 0;
  bool _caret = true;
  Timer? _type;
  Timer? _blink;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _count = widget.text.length;
      _caret = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone?.call());
      return;
    }
    _type = Timer(widget.delay, () {
      _type = Timer.periodic(widget.perChar, (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _count++);
        if (_count >= widget.text.length) {
          t.cancel();
          _blink?.cancel();
          setState(() => _caret = false);
          widget.onDone?.call();
        }
      });
    });
    if (widget.showCaret) {
      _blink = Timer.periodic(const Duration(milliseconds: 530), (_) {
        if (mounted) setState(() => _caret = !_caret);
      });
    }
  }

  @override
  void dispose() {
    _type?.cancel();
    _blink?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.substring(0, _count.clamp(0, widget.text.length));
    final caret = widget.showCaret && _caret;
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: shown),
            if (widget.showCaret)
              TextSpan(
                text: '|',
                style: TextStyle(color: caret ? null : const Color(0x00000000)),
              ),
          ],
        ),
        style: widget.style,
      ),
    );
  }
}

/// A chat bubble that pops in from its own corner (user = bottom-right,
/// other = bottom-left). Pair with [AppTypewriter] for assistant replies.
class AppChatBubble extends StatefulWidget {
  const AppChatBubble({
    super.key,
    required this.child,
    this.fromMe = false,
    this.delay = Duration.zero,
    this.color = const Color(0xFFFFFFFF),
    this.maxWidth = 240,
  });

  final Widget child;
  final bool fromMe;
  final Duration delay;
  final Color color;
  final double maxWidth;

  @override
  State<AppChatBubble> createState() => _AppChatBubbleState();
}

class _AppChatBubbleState extends State<AppChatBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _t;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    _c.duration = AppMotion.xl;
    _t = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.fromMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          );
    return Align(
      alignment: widget.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          return Opacity(
            opacity: const Interval(0, 0.3).transform(t),
            child: Transform.scale(
              alignment: widget.fromMe ? Alignment.bottomRight : Alignment.bottomLeft,
              scale: 0.6 + 0.4 * AppMotion.pop.transform(t),
              child: child,
            ),
          );
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: r,
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
