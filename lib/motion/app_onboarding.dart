import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_motion.dart';
import 'app_onboarding_parts.dart';
import 'app_pressable.dart';
import 'app_reveal.dart';

/// One onboarding step. [art] is the product-story moment for this step,
/// built from motion widgets (map pins dropping, a booking confirming, a
/// habit ticking off). It is rebuilt each time the step comes into view, so
/// its one-shot animations replay.
class AppOnboardingStep {
  const AppOnboardingStep({required this.art, required this.title, required this.body});

  final WidgetBuilder art;
  final String title;
  final String body;
}

/// How the step art and the text share the screen. Pick per app so every
/// onboarding does not look the same.
enum AppOnboardingLayout {
  /// Art fills the top, title and body below it (default).
  artTop,

  /// Title and body first, the scene fills the rest below.
  textTop,

  /// The scene fills the whole screen; text sits on a dark scrim at the bottom
  /// in light ink. Best for photo-led, premium and food apps.
  fullBleed,
}

/// The step indicator and call-to-action style.
enum AppOnboardingChrome {
  /// Dots that grow into a pill, a compact Next pill on the right (default).
  dotsPill,

  /// A short segmented bar at the top and a full-width button at the bottom —
  /// the calm, minimal style of many health / AI / finance apps.
  topBarFullButton,

  /// A rolling "01 / 04" counter on the left and a round arrow button whose
  /// ring fills with progress on the right — editorial, premium apps.
  ringCounter,
}

/// How one step hands over to the next.
enum AppOnboardingTransition {
  /// Pages slide sideways with the finger (art trails slightly).
  slide,

  /// Steps cross-fade in place — calm, soft apps.
  fade,

  /// The next step slides over the previous one, which sinks back and fades
  /// like a card in a stack — playful, springy apps.
  stack,

  /// The outgoing step zooms out and fades while the next settles from
  /// slightly zoomed in — cinematic, premium apps.
  zoom,
}

/// Onboarding shell with FlutterGo motion on a clean, plain background: swipe
/// follows the finger, the art trails it slightly (parallax), title and body
/// rise in, dots grow into a pill, Next turns into the final call to action.
///
/// The steps' [AppOnboardingStep.art] should *show the product working*
/// (see skills/fluttergo-motion-system/references/screen-recipes.md).
class AppOnboarding extends StatefulWidget {
  const AppOnboarding({
    super.key,
    required this.steps,
    required this.onDone,
    this.nextLabel = 'Next',
    this.doneLabel = 'Get started',
    this.skipLabel = 'Skip',
    this.accent,
    this.background,
    this.ink,
    this.muted,
    this.titleStyle,
    this.bodyStyle,
    this.layout = AppOnboardingLayout.artTop,
    this.chrome = AppOnboardingChrome.dotsPill,
    this.backdrop = false,
    this.artParallax = true,
    this.transition,
  });

  final List<AppOnboardingStep> steps;
  final VoidCallback onDone;
  final String nextLabel;
  final String doneLabel;
  final String skipLabel;
  final Color? accent;
  final Color? background;
  final Color? ink;
  final Color? muted;
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;
  final AppOnboardingLayout layout;
  final AppOnboardingChrome chrome;

  /// Soft accent glow drifting behind the pages. Off by default: FlutterGo
  /// onboarding keeps a clean, plain background.
  final bool backdrop;

  /// The art trails the swipe slightly (parallax) and the copy cross-fades —
  /// the "carousel of hero illustrations" feel.
  final bool artParallax;

  /// Step-to-step transition. Null picks one from [AppMotion.style]:
  /// soft → fade, springy → stack, cinematic → zoom, crisp → slide.
  final AppOnboardingTransition? transition;

  @override
  State<AppOnboarding> createState() => _AppOnboardingState();
}

class _AppOnboardingState extends State<AppOnboarding> {
  final _pages = PageController();
  int _index = 0;

  bool get _last => _index == widget.steps.length - 1;

  void _go(int i) => _pages.animateToPage(
        i,
        duration: AppMotion.resolve(context, AppMotion.lg, essential: true),
        curve: AppMotion.enter,
      );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = widget.accent ?? scheme.primary;
    final bg = widget.background ?? scheme.surface;
    final bleed = widget.layout == AppOnboardingLayout.fullBleed;
    final ink = bleed ? const Color(0xFFFFFFFF) : (widget.ink ?? scheme.onSurface);
    final muted = bleed ? const Color(0xD9FFFFFF) : (widget.muted ?? scheme.onSurfaceVariant);
    final pad = MediaQuery.paddingOf(context);
    final reduce = AppMotion.reduced(context);
    final handover = widget.transition ??
        switch (AppMotion.style) {
          MotionStyle.soft => AppOnboardingTransition.fade,
          MotionStyle.springy => AppOnboardingTransition.stack,
          MotionStyle.cinematic => AppOnboardingTransition.zoom,
          MotionStyle.crisp => AppOnboardingTransition.slide,
        };
    final width = MediaQuery.sizeOf(context).width;
    Widget handoff(int i, Widget page) {
      if (reduce || handover == AppOnboardingTransition.slide) return page;
      return AnimatedBuilder(
        animation: _pages,
        child: page,
        builder: (context, child) {
          final p = _pages.hasClients && _pages.position.haveDimensions
              ? (_pages.page ?? i.toDouble())
              : i.toDouble();
          final d = i - p; // > 0 incoming from the right, < 0 leaving left
          final fade = (1 - d.abs()).clamp(0.0, 1.0);
          switch (handover) {
            case AppOnboardingTransition.fade:
              return Opacity(
                opacity: fade,
                child: Transform.translate(offset: Offset(-d * width, 0), child: child),
              );
            case AppOnboardingTransition.stack:
              if (d >= 0) return child!;
              return Opacity(
                opacity: fade,
                child: Transform.translate(
                  offset: Offset(-d * width, 0),
                  child: Transform.scale(scale: 1 + 0.1 * d, child: child),
                ),
              );
            case AppOnboardingTransition.zoom:
              return Opacity(
                opacity: fade,
                child: Transform.translate(
                  offset: Offset(-d * width, 0),
                  child: Transform.scale(scale: 1 + 0.12 * d, child: child),
                ),
              );
            case AppOnboardingTransition.slide:
              return child!;
          }
        },
      );
    }

    // Material (not a bare ColoredBox) so text inside the steps gets the
    // app's text theme even when the route has no Scaffold — otherwise Flutter
    // draws its red, yellow-underlined "missing Material" debug text.
    return Material(
      color: bg,
      child: Stack(
        children: [
          if (widget.backdrop)
          AnimatedBuilder(
            animation: _pages,
            builder: (context, _) {
              final page = _pages.hasClients && _pages.position.haveDimensions
                  ? (_pages.page ?? 0)
                  : 0.0;
              return Positioned(
                top: -160,
                left: -80 - (reduce ? 0 : page * 60),
                child: IgnorePointer(
                  child: Container(
                    width: 460,
                    height: 460,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [accent.withAlpha(46), accent.withAlpha(0)],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          PageView.builder(
            controller: _pages,
            itemCount: widget.steps.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _index = i);
            },
            itemBuilder: (context, i) {
              final step = widget.steps[i];
              Widget art(BuildContext context) {
                final built = step.art(context);
                if (!widget.artParallax || reduce || handover != AppOnboardingTransition.slide) return built;
                return AnimatedBuilder(
                  animation: _pages,
                  builder: (context, child) {
                    final page = _pages.hasClients && _pages.position.haveDimensions
                        ? (_pages.page ?? i.toDouble())
                        : i.toDouble();
                    final d = i - page;
                    return Opacity(
                      opacity: (1 - d.abs() * 0.6).clamp(0.0, 1.0),
                      child: Transform.translate(offset: Offset(d * 90, 0), child: child),
                    );
                  },
                  child: built,
                );
              }
              final copy = Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  widget.layout == AppOnboardingLayout.textTop ? pad.top + 56 : 18,
                  24,
                  widget.layout == AppOnboardingLayout.textTop ? 12 : pad.bottom + 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppReveal(
                      delay: const Duration(milliseconds: 220),
                      child: Text(
                        step.title,
                        style: (widget.titleStyle ?? text.headlineSmall ?? const TextStyle())
                            .copyWith(color: ink, fontWeight: FontWeight.w700, height: 1.12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppReveal(
                      index: 1,
                      delay: const Duration(milliseconds: 220),
                      child: Text(
                        step.body,
                        style: (widget.bodyStyle ?? text.bodyLarge ?? const TextStyle())
                            .copyWith(color: muted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
              switch (widget.layout) {
                case AppOnboardingLayout.fullBleed:
                  return handoff(i, Stack(
                    key: ValueKey('onboarding-step-$i'),
                    fit: StackFit.expand,
                    children: [
                      art(context),
                      const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(0, 0.1),
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0xCC000000)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(left: 0, right: 0, bottom: 0, child: copy),
                    ],
                  ));
                case AppOnboardingLayout.textTop:
                  return handoff(i, Column(
                    key: ValueKey('onboarding-step-$i'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      copy,
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: pad.bottom + 88),
                          child: art(context),
                        ),
                      ),
                    ],
                  ));
                case AppOnboardingLayout.artTop:
                  return handoff(i, Column(
                    key: ValueKey('onboarding-step-$i'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: art(context)),
                      copy,
                    ],
                  ));
              }
            },
          ),
          Positioned(
            top: pad.top + 6,
            right: 14,
            child: AnimatedOpacity(
              opacity: _last ? 0 : 1,
              duration: AppMotion.md,
              child: TextButton(
                onPressed: _last ? null : () => _go(widget.steps.length - 1),
                child: Text(widget.skipLabel, style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          if (widget.chrome == AppOnboardingChrome.topBarFullButton) ...[
            Positioned(
              top: pad.top + 14,
              left: 0,
              right: 0,
              child: Semantics(
                label: 'Step ${_index + 1} of ${widget.steps.length}',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.steps.length; i++)
                      AnimatedContainer(
                        duration: AppMotion.md,
                        curve: AppMotion.standard,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: i == _index ? 18 : 8,
                        height: 3,
                        decoration: BoxDecoration(
                          color: i == _index ? ink : ink.withAlpha(46),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: pad.bottom + 20,
              child: AppPressable(
                onTap: () => _last ? widget.onDone() : _go(_index + 1),
                semanticLabel: _last ? widget.doneLabel : widget.nextLabel,
                child: AnimatedContainer(
                  duration: AppMotion.md,
                  curve: AppMotion.standard,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _last ? accent : (bleed ? const Color(0xFFFFFFFF) : ink),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.sm,
                    child: Text(
                      _last ? widget.doneLabel : widget.nextLabel,
                      key: ValueKey(_last),
                      style: TextStyle(
                        color: _last ? const Color(0xFFFFFFFF) : (bleed ? const Color(0xFF111418) : bg),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else if (widget.chrome == AppOnboardingChrome.ringCounter)
          Positioned(
            left: 24,
            right: 24,
            bottom: pad.bottom + 18,
            child: Row(
              children: [
                AppStepCounter(index: _index, total: widget.steps.length, color: ink, mutedColor: muted),
                const Spacer(),
                AppRingArrowButton(
                  progress: (_index + 1) / widget.steps.length,
                  color: accent,
                  done: _last,
                  semanticLabel: _last ? widget.doneLabel : widget.nextLabel,
                  onTap: () => _last ? widget.onDone() : _go(_index + 1),
                ),
              ],
            ),
          )
          else
          Positioned(
            left: 24,
            right: 24,
            bottom: pad.bottom + 22,
            child: Row(
              children: [
                Semantics(
                  label: 'Step ${_index + 1} of ${widget.steps.length}',
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.steps.length; i++)
                        AnimatedContainer(
                          duration: AppMotion.md,
                          curve: AppMotion.standard,
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _index ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _index ? accent : ink.withAlpha(46),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                AppPressable(
                  onTap: () {
                    if (_last) {
                      widget.onDone();
                    } else {
                      _go(_index + 1);
                    }
                  },
                  semanticLabel: _last ? widget.doneLabel : widget.nextLabel,
                  child: AnimatedContainer(
                    duration: AppMotion.md,
                    curve: AppMotion.standard,
                    height: 50,
                    width: _last ? 164 : 104,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _last ? accent : (bleed ? const Color(0xFFFFFFFF) : ink),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.sm,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, .5), end: Offset.zero).animate(a),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _last ? widget.doneLabel : widget.nextLabel,
                        key: ValueKey(_last),
                        style: TextStyle(
                          color: _last ? const Color(0xFFFFFFFF) : (bleed ? const Color(0xFF111418) : bg),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
