import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_motion.dart';
import 'app_pressable.dart';
import 'app_reveal.dart';

// Two more onboarding skeletons (see onboarding-scenes.md):
//   welcome → AppWelcomeAuth        one screen: hero stage + device mockup +
//                                   toast stack, mixed headline, auth buttons
//   fan     → AppCardFanOnboarding  a fan of tilted photo cards that deals and
//                                   re-deals per step, centred headline with
//                                   an accent word, full-width Next

// ─────────────────────────────────────────────────────────────────────────
// Mixed headline — muted / strong / accent words and inline marks per line.
// ─────────────────────────────────────────────────────────────────────────

/// How a headline part is coloured.
enum AppHeadlineTone { strong, muted, accent }

/// One piece of an [AppMixedHeadline] line: text, or an inline widget such as
/// the app's logo mark sitting between two words.
class AppHeadlinePart {
  const AppHeadlinePart(String this.text, {this.tone = AppHeadlineTone.strong, this.style}) : inline = null;

  /// An inline mark (logo, emoji, small photo) sized to the line height.
  const AppHeadlinePart.inline(Widget this.inline)
      : text = null,
        tone = AppHeadlineTone.strong,
        style = null;

  final String? text;
  final AppHeadlineTone tone;

  /// Extra style for this part only — e.g. a serif italic accent word.
  final TextStyle? style;
  final Widget? inline;
}

/// Big headline built from explicit lines; each line rises out of a mask in
/// turn and inline marks pop. "Turn your / ideas [logo] apps / in seconds".
class AppMixedHeadline extends StatefulWidget {
  const AppMixedHeadline({
    super.key,
    required this.lines,
    this.style,
    this.mutedColor,
    this.accentColor,
    this.textAlign = TextAlign.start,
    this.delay = Duration.zero,
  });

  final List<List<AppHeadlinePart>> lines;
  final TextStyle? style;
  final Color? mutedColor;
  final Color? accentColor;
  final TextAlign textAlign;
  final Duration delay;

  @override
  State<AppMixedHeadline> createState() => _AppMixedHeadlineState();
}

class _AppMixedHeadlineState extends State<AppMixedHeadline> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _wait;
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
    _c.duration = AppMotion.xl + Duration(milliseconds: 110 * widget.lines.length);
    _wait = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  List<Widget> _parts(
    List<AppHeadlinePart> parts,
    TextStyle base,
    Color strong,
    Color muted,
    Color accent,
    double size,
  ) {
    final out = <Widget>[];
    for (var k = 0; k < parts.length; k++) {
      final part = parts[k];
      if (part.inline != null) {
        out.add(Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.14),
          child: SizedBox.square(dimension: size * 1.05, child: part.inline),
        ));
        continue;
      }
      // A word gap between two text parts.
      if (k > 0 && parts[k - 1].inline == null) out.add(SizedBox(width: size * 0.26));
      out.add(Text(
        part.text!,
        style: base
            .copyWith(
              color: switch (part.tone) {
                AppHeadlineTone.strong => strong,
                AppHeadlineTone.muted => muted,
                AppHeadlineTone.accent => accent,
              },
            )
            .merge(part.style),
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = (widget.style ?? Theme.of(context).textTheme.displaySmall ?? const TextStyle())
        .copyWith(height: 1.05, fontWeight: FontWeight.w700, letterSpacing: -0.8);
    final strong = base.color ?? scheme.onSurface;
    final muted = widget.mutedColor ?? strong.withAlpha(110);
    final accent = widget.accentColor ?? scheme.primary;
    final size = base.fontSize ?? 36;
    final n = widget.lines.length;
    final cross = switch (widget.textAlign) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.end || TextAlign.right => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
    final label = widget.lines.map((l) => l.map((p) => p.text ?? '').join(' ')).join(' ');
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: cross,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < n; i++)
              AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  final start = n <= 1 ? 0.0 : (i / n) * 0.45;
                  final v = Interval(start, start + 0.55, curve: AppMotion.enter).transform(_c.value);
                  return ClipRect(
                    child: FractionalTranslation(
                      translation: Offset(0, 1 - v),
                      child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
                    ),
                  );
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _parts(widget.lines[i], base, strong, muted, accent, size),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Toast stack — product messages drop in; the older one sinks behind.
// ─────────────────────────────────────────────────────────────────────────

/// One message in [AppToastStack].
class AppToast {
  const AppToast({required this.text, this.leading});

  final String text;

  /// A small mark (22 dp): the app icon, a feature icon, an avatar photo.
  final Widget? leading;
}

/// Notification-style chips that drop in one after another; the previous one
/// sinks behind (smaller, lower, dimmer). Loops through [toasts] while
/// visible. Reduced motion shows the first two, still.
class AppToastStack extends StatefulWidget {
  const AppToastStack({
    super.key,
    required this.toasts,
    this.interval = const Duration(milliseconds: 2600),
    this.loop = true,
    this.maxWidth = 290,
  });

  final List<AppToast> toasts;
  final Duration interval;
  final bool loop;
  final double maxWidth;

  @override
  State<AppToastStack> createState() => _AppToastStackState();
}

class _AppToastStackState extends State<AppToastStack> {
  Timer? _t;
  int _count = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || widget.toasts.isEmpty) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _count = math.min(2, widget.toasts.length);
      return;
    }
    _t = Timer(const Duration(milliseconds: 500), _tick);
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _count++);
    if (widget.loop || _count < widget.toasts.length) {
      _t = Timer(widget.interval, _tick);
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.toasts.length;
    final layers = <Widget>[];
    for (var depth = 2; depth >= 0; depth--) {
      final k = _count - 1 - depth;
      if (k < 0 || n == 0) continue;
      final toast = widget.toasts[k % n];
      layers.add(
        AnimatedSlide(
          key: ValueKey('toast-$k'),
          offset: Offset(0, depth * 0.38),
          duration: AppMotion.lg,
          curve: AppMotion.enter,
          child: AnimatedScale(
            scale: 1 - 0.06 * depth,
            duration: AppMotion.lg,
            curve: AppMotion.enter,
            child: AnimatedOpacity(
              opacity: depth == 0 ? 1 : (depth == 1 ? 0.78 : 0),
              duration: AppMotion.lg,
              child: AppReveal.drop(child: _ToastChip(toast: toast, maxWidth: widget.maxWidth)),
            ),
          ),
        ),
      );
    }
    return Semantics(
      liveRegion: true,
      child: Stack(alignment: Alignment.topCenter, clipBehavior: Clip.none, children: layers),
    );
  }
}

class _ToastChip extends StatelessWidget {
  const _ToastChip({required this.toast, required this.maxWidth});

  final AppToast toast;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (toast.leading != null) ...[
              SizedBox.square(dimension: 22, child: toast.leading),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                toast.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Color(0xFF16181D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Device frame — the app's own screen inside a phone, for welcome heroes.
// ─────────────────────────────────────────────────────────────────────────

/// A phone mockup (rounded frame + island) around [child] — show the app's
/// real Home (its own cards, names and photos), never a grey placeholder.
class AppDeviceFrame extends StatelessWidget {
  const AppDeviceFrame({
    super.key,
    required this.child,
    this.width = 230,
    this.frameColor = const Color(0xFF111418),
  });

  final Widget child;
  final double width;
  final Color frameColor;

  @override
  Widget build(BuildContext context) {
    final w = width;
    return Container(
      width: w,
      height: w * 2.05,
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(w * 0.16),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(w * 0.13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaQuery.removePadding(context: context, removeTop: true, removeBottom: true, child: child),
            Positioned(
              top: w * 0.03,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: w * 0.3,
                  height: w * 0.085,
                  decoration: BoxDecoration(color: frameColor, borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// WELCOME — one screen: hero stage, mixed headline, auth / start buttons.
// ─────────────────────────────────────────────────────────────────────────

/// The hero stage for [AppWelcomeAuth]: a photo (slow settle), the app's own
/// Home rising inside a phone from the bottom edge, and product toasts
/// dropping in above it.
class AppWelcomeHero extends StatelessWidget {
  const AppWelcomeHero({
    super.key,
    required this.background,
    required this.screen,
    this.toasts = const [],
    this.deviceWidth = 230,
    this.radius = 28,
  });

  /// Usually `Image.asset(..., fit: BoxFit.cover)` — a real photo or texture.
  final Widget background;

  /// The app's own Home in miniature (real names, photos, numbers).
  final Widget screen;
  final List<AppToast> toasts;
  final double deviceWidth;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: LayoutBuilder(
        builder: (context, box) {
          final h = box.maxHeight.isFinite ? box.maxHeight : 420.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: reduce ? 1 : 1.1, end: 1),
                duration: AppMotion.resolve(context, const Duration(milliseconds: 2400)),
                curve: AppMotion.enter,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: background,
              ),
              Positioned(
                top: h * 0.24,
                left: 0,
                right: 0,
                child: Center(
                  child: AppReveal(
                    delay: const Duration(milliseconds: 180),
                    distance: 90,
                    child: AppDeviceFrame(width: deviceWidth, child: screen),
                  ),
                ),
              ),
              if (toasts.isNotEmpty)
                Positioned(
                  top: 18,
                  left: 16,
                  right: 16,
                  child: Center(child: AppToastStack(toasts: toasts)),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Button style for [AppWelcomeOption].
enum AppWelcomeOptionKind { primary, secondary, text }

/// One button on [AppWelcomeAuth] ("Continue with Google", "Get started",
/// "I already have an account").
class AppWelcomeOption {
  const AppWelcomeOption({
    required this.label,
    required this.onTap,
    this.leading,
    this.kind = AppWelcomeOptionKind.primary,
  });

  final String label;
  final VoidCallback onTap;

  /// A real brand / feature mark (sourced SVG), 20 dp.
  final Widget? leading;
  final AppWelcomeOptionKind kind;
}

/// Welcome skeleton: hero stage on top, a mixed headline, then a stack of
/// start / sign-in buttons that rise in turn. Only offer sign-in options the
/// app really has; without auth use "Get started" / "Explore first".
class AppWelcomeAuth extends StatelessWidget {
  const AppWelcomeAuth({
    super.key,
    required this.hero,
    required this.headline,
    required this.options,
    this.footer,
    this.background,
    this.headlineStyle,
    this.heroFlex = 11,
  });

  final Widget hero;
  final List<List<AppHeadlinePart>> headline;
  final List<AppWelcomeOption> options;

  /// Small print under the buttons (terms, "No account needed").
  final Widget? footer;
  final Color? background;
  final TextStyle? headlineStyle;
  final int heroFlex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pad = MediaQuery.paddingOf(context);
    return Material(
      color: background ?? scheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, pad.top + 8, 16, pad.bottom + 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: heroFlex, child: AppReveal.fade(child: hero)),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AppMixedHeadline(
                lines: headline,
                style: headlineStyle,
                delay: const Duration(milliseconds: 260),
              ),
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppReveal(
                  index: i,
                  delay: const Duration(milliseconds: 520),
                  child: _WelcomeButton(option: options[i]),
                ),
              ),
            if (footer != null)
              AppReveal.fade(delay: const Duration(milliseconds: 760), child: Center(child: footer)),
          ],
        ),
      ),
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({required this.option});

  final AppWelcomeOption option;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface;
    final (Color bg, Color fg) = switch (option.kind) {
      AppWelcomeOptionKind.primary => (ink, scheme.surface),
      AppWelcomeOptionKind.secondary => (ink.withAlpha(16), ink),
      AppWelcomeOptionKind.text => (const Color(0x00000000), ink),
    };
    return AppPressable(
      onTap: option.onTap,
      semanticLabel: option.label,
      child: Container(
        height: option.kind == AppWelcomeOptionKind.text ? 44 : 54,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (option.leading != null) ...[
              SizedBox.square(dimension: 20, child: option.leading),
              const SizedBox(width: 10),
            ],
            Text(option.label, style: TextStyle(color: fg, fontSize: 15.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// FAN — tilted photo cards deal out per step.
// ─────────────────────────────────────────────────────────────────────────

/// One card in an [AppFanStep].
class AppFanCard {
  const AppFanCard({required this.title, required this.image, required this.color, this.accent});

  final String title;

  /// Second title line in the accent style (e.g. serif italic "Gallery").
  final String? accent;

  /// A real photo of the thing this card stands for.
  final ImageProvider image;
  final Color color;
}

/// One step of [AppCardFanOnboarding]: 1–3 cards (the middle one sits in
/// front) and a centred headline.
class AppFanStep {
  const AppFanStep({required this.cards, required this.headline});

  final List<AppFanCard> cards;
  final List<List<AppHeadlinePart>> headline;
}

/// Card-fan onboarding: the step's cards deal out from a stack into a tilted
/// fan with a little overshoot and float gently; Next gathers them and deals
/// the next set. Centred headline (one accent word), slim step bars, a
/// full-width Next. Works on a dark or light plain background.
class AppCardFanOnboarding extends StatefulWidget {
  const AppCardFanOnboarding({
    super.key,
    required this.steps,
    required this.onDone,
    this.nextLabel = 'Next',
    this.doneLabel = 'Get started',
    this.skipLabel = 'Skip',
    this.background,
    this.foreground,
    this.accentStyle,
    this.headlineStyle,
  });

  final List<AppFanStep> steps;
  final VoidCallback onDone;
  final String nextLabel;
  final String doneLabel;
  final String skipLabel;
  final Color? background;
  final Color? foreground;

  /// Style for card accent lines (pair with the headline's accent parts).
  final TextStyle? accentStyle;
  final TextStyle? headlineStyle;

  @override
  State<AppCardFanOnboarding> createState() => _AppCardFanOnboardingState();
}

class _AppCardFanOnboardingState extends State<AppCardFanOnboarding> with TickerProviderStateMixin {
  late final AnimationController _deal = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _float = AnimationController(vsync: this, duration: AppMotion.ambient);
  int _index = 0;
  bool _busy = false;
  bool _started = false;

  bool get _last => _index == widget.steps.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _deal.value = 1;
    } else {
      _deal.forward();
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _deal.dispose();
    _float.dispose();
    super.dispose();
  }

  Future<void> _goTo(int i) async {
    if (_busy || i < 0 || i >= widget.steps.length || i == _index) return;
    _busy = true;
    HapticFeedback.selectionClick();
    final reduce = AppMotion.reduced(context);
    if (!reduce) {
      await _deal.animateBack(0, duration: AppMotion.md, curve: AppMotion.exitCurve);
    }
    if (!mounted) return;
    setState(() => _index = i);
    if (reduce) {
      _deal.value = 1;
    } else {
      await _deal.forward(from: 0);
    }
    _busy = false;
  }

  // Slots: left, front, right.
  static const _slots = <({double x, double y, double rot, double scale})>[
    (x: -0.56, y: 0.10, rot: -0.17, scale: 0.86),
    (x: 0.0, y: 0.0, rot: -0.05, scale: 1.0),
    (x: 0.54, y: -0.16, rot: 0.13, scale: 0.86),
  ];

  List<int> _slotsFor(int count) => switch (count) {
        1 => const [1],
        2 => const [0, 1],
        _ => const [0, 1, 2],
      };

  Widget _card(AppFanCard card, double w, Color fg) {
    final titleStyle = TextStyle(color: const Color(0xFFFFFFFF), fontSize: w * 0.11, fontWeight: FontWeight.w800, height: 1.05);
    return Container(
      width: w,
      height: w * 1.12,
      padding: EdgeInsets.all(w * 0.06),
      decoration: BoxDecoration(
        color: card.color,
        borderRadius: BorderRadius.circular(w * 0.12),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 26, offset: Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle),
          if (card.accent != null)
            Text(
              card.accent!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle.copyWith(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic).merge(widget.accentStyle),
            ),
          SizedBox(height: w * 0.05),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(w * 0.08),
              child: Image(image: card.image, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.background ?? const Color(0xFF121316);
    final fg = widget.foreground ?? const Color(0xFFFFFFFF);
    final pad = MediaQuery.paddingOf(context);
    final reduce = AppMotion.reduced(context);
    final step = widget.steps[_index];
    final popCurve = AppMotion.curve(context, AppMotion.pop);
    return Material(
      color: bg,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -250) _goTo(_index + 1);
          if (v > 250) _goTo(_index - 1);
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, pad.top + 4, 24, pad.bottom + 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _last ? 0 : 1,
                  duration: AppMotion.md,
                  child: TextButton(
                    onPressed: _last ? null : widget.onDone,
                    child: Text(widget.skipLabel, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final w = math.min(box.maxWidth * 0.46, 200.0);
                    final slots = _slotsFor(step.cards.length);
                    // Paint back cards first, the front card last.
                    final order = [for (var j = 0; j < step.cards.length; j++) j]
                      ..sort((a, b) => (slots[a] == 1 ? 1 : 0).compareTo(slots[b] == 1 ? 1 : 0));
                    return AnimatedBuilder(
                      animation: Listenable.merge([_deal, _float]),
                      builder: (context, _) => Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          for (final j in order)
                            Builder(
                              builder: (context) {
                                final s = _slots[slots[j]];
                                final start = 0.12 * j;
                                final t = Interval(start, math.min(1.0, start + 0.76), curve: popCurve).transform(_deal.value);
                                final bob = reduce ? 0.0 : math.sin((_float.value + j / 3) * math.pi * 2) * 4;
                                return Opacity(
                                  opacity: Interval(start, math.min(1.0, start + 0.3)).transform(_deal.value),
                                  child: Transform.translate(
                                    offset: Offset(s.x * w * t, (s.y * w + 0.18 * w * (1 - t)) + bob),
                                    child: Transform.rotate(
                                      angle: s.rot * t,
                                      child: Transform.scale(
                                        scale: 0.82 + (s.scale - 0.82) * t,
                                        child: _card(step.cards[j], w, fg),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Semantics(
                label: 'Step ${_index + 1} of ${widget.steps.length}',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.steps.length; i++)
                      AnimatedContainer(
                        duration: AppMotion.md,
                        curve: AppMotion.standard,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: i == _index ? 16 : 6,
                        height: 5,
                        decoration: BoxDecoration(
                          color: i == _index ? fg : fg.withAlpha(70),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              AppMixedHeadline(
                key: ValueKey('fan-headline-$_index'),
                lines: step.headline,
                textAlign: TextAlign.center,
                style: (widget.headlineStyle ?? Theme.of(context).textTheme.headlineMedium ?? const TextStyle())
                    .copyWith(color: fg),
                mutedColor: fg.withAlpha(150),
                accentColor: fg,
                delay: const Duration(milliseconds: 120),
              ),
              const SizedBox(height: 26),
              AppPressable(
                onTap: () => _last ? widget.onDone() : _goTo(_index + 1),
                semanticLabel: _last ? widget.doneLabel : widget.nextLabel,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: fg,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: fg.withAlpha(40), blurRadius: 24, offset: const Offset(0, 6))],
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.sm,
                    child: Row(
                      key: ValueKey(_last),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _last ? widget.doneLabel : widget.nextLabel,
                          style: TextStyle(color: bg, fontSize: 15.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, color: bg, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
