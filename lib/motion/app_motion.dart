// FlutterGo Motion System — tokens and page transitions.
//
// Feature code uses these tokens instead of hardcoded Duration(...) or
// Curves.* values, so every screen in the app moves the same way.
// See skills/fluttergo-motion-system/SKILL.md.

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App-wide motion personality, chosen once in docs/app-plan.md.
enum MotionPersonality { calm, balanced, expressive }

/// How things move — the app's motion signature, set once in main() from the
/// design direction. Personality changes speed; style changes the *feel*.
enum MotionStyle {
  /// Gentle fade with a short rise and a long soft landing (health, wellness,
  /// AI assistants, finance).
  soft,

  /// Bigger travel, overshoot and bounce (kids, pets, social, games, fun food).
  springy,

  /// Slow fades that settle from slightly zoomed in, never bounce (premium,
  /// fashion, travel, editorial, real estate).
  cinematic,

  /// Short, fast, precise moves with no overshoot (productivity, tools,
  /// fintech, B2B).
  crisp,
}

/// Intentional page transitions for go_router routes.
enum PageMotion { platform, sharedAxisX, sharedAxisY, fadeThrough, slideUp, fade }

abstract final class AppMotion {
  /// Set once in main() from the design direction.
  static MotionPersonality personality = MotionPersonality.balanced;

  /// The motion signature (see [MotionStyle]). Set in main() next to
  /// [personality].
  static MotionStyle style = MotionStyle.soft;

  /// Optional in-app "Reduce motion" setting; OR-ed with the OS flag.
  static bool appReduceMotion = false;

  static double get scale => switch (personality) {
        MotionPersonality.calm => 0.9,
        MotionPersonality.balanced => 1.0,
        MotionPersonality.expressive => 1.1,
      };

  static Duration _d(int ms) => Duration(milliseconds: (ms * scale).round());

  // ── Durations ──────────────────────────────────────────────────────────
  static const Duration instant = Duration.zero;
  static Duration get xs => _d(100);
  static Duration get sm => _d(150);
  static Duration get md => _d(250);
  static Duration get lg => _d(350);
  static Duration get xl => _d(500);
  static Duration get sheetDuration => _d(520);
  static const Duration stagger = Duration(milliseconds: 40);
  static const int maxStaggerItems = 8;
  static const Duration shimmer = Duration(milliseconds: 1300);
  static const Duration ambient = Duration(seconds: 6);

  /// Exits and reverse animations are ~25% shorter than enters.
  static Duration exit(Duration enter) => enter * 0.75;

  // ── Curves (Material 3 + two named extras) ─────────────────────────────
  static const Curve enter = Easing.emphasizedDecelerate;
  static const Curve exitCurve = Easing.emphasizedAccelerate;
  static const Curve standard = Easing.standard;
  static const Curve linear = Curves.linear;

  /// iOS-style sheet curve: fast start, long soft landing.
  static const Curve sheet = Cubic(0.32, 0.72, 0, 1);

  /// Small overshoot for pops (pins, badges, stars). Rare delight only.
  static const Curve pop = Curves.easeOutBack;

  // ── Style-driven entrance feel (used by AppReveal and AppOnboarding) ───
  static Curve get revealCurve => switch (style) {
        MotionStyle.soft => Easing.emphasizedDecelerate,
        MotionStyle.springy => const Cubic(0.34, 1.56, 0.64, 1),
        MotionStyle.cinematic => const Cubic(0.16, 1, 0.3, 1),
        MotionStyle.crisp => Curves.easeOutCubic,
      };

  static Curve get popCurve => switch (style) {
        MotionStyle.soft => Curves.easeOutBack,
        MotionStyle.springy => const ElasticOutCurve(0.75),
        MotionStyle.cinematic => const Cubic(0.16, 1, 0.3, 1),
        MotionStyle.crisp => Curves.easeOutCubic,
      };

  /// Rise travel in logical pixels.
  static double get revealDistance => switch (style) {
        MotionStyle.soft => 14,
        MotionStyle.springy => 30,
        MotionStyle.cinematic => 0,
        MotionStyle.crisp => 10,
      };

  /// Scale an entering element starts from (cinematic settles from > 1).
  static double get revealScaleFrom => switch (style) {
        MotionStyle.soft => 1,
        MotionStyle.springy => 0.9,
        MotionStyle.cinematic => 1.06,
        MotionStyle.crisp => 1,
      };

  /// Scale a popping element starts from.
  static double get popScaleFrom => switch (style) {
        MotionStyle.soft => 0.7,
        MotionStyle.springy => 0.4,
        MotionStyle.cinematic => 0.92,
        MotionStyle.crisp => 0.8,
      };

  /// Multiplier on entrance durations for the style.
  static double get revealDurationFactor => switch (style) {
        MotionStyle.soft => 1.15,
        MotionStyle.springy => 1.4,
        MotionStyle.cinematic => 1.9,
        MotionStyle.crisp => 0.75,
      };

  // ── Springs (gesture settle) ───────────────────────────────────────────
  static final SpringDescription springSnappy =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 600, ratio: 0.9);
  static final SpringDescription springSmooth =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 1.0);
  static final SpringDescription springBouncy =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 400, ratio: 0.6);

  // ── Distance and scale ─────────────────────────────────────────────────
  static const double riseDistance = 16;
  static const double slidePage = 0.08; // fractional offset for shared-axis pages
  static const double pressScale = 0.97;
  static const double pressScaleIcon = 0.92;

  // ── Reduced motion ─────────────────────────────────────────────────────
  static bool reduced(BuildContext context) =>
      appReduceMotion || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// Duration given reduced motion: essential motion (state that would
  /// otherwise teleport) shrinks to [sm]; decorative motion becomes 0.
  static Duration resolve(BuildContext context, Duration d, {bool essential = false}) {
    if (!reduced(context)) return d;
    return essential ? sm : instant;
  }

  /// Overshooting curves become [standard] under reduced motion.
  static Curve curve(BuildContext context, Curve c) => reduced(context) ? standard : c;

  /// Delay for item [index] in a staggered list (capped at [maxStaggerItems]).
  static Duration staggerDelay(int index) =>
      stagger * (index < maxStaggerItems ? index : maxStaggerItems);

  // ── Platform page transitions (set on ThemeData) ───────────────────────
  static const PageTransitionsTheme pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  // ── go_router page helper ──────────────────────────────────────────────
  /// `GoRoute(pageBuilder: (c, s) => AppMotion.page(state: s, child: ...))`.
  /// Use only when a route needs an intentional non-platform transition.
  static Page<void> page({
    required GoRouterState state,
    required Widget child,
    PageMotion motion = PageMotion.sharedAxisX,
    bool fullscreenDialog = false,
  }) {
    if (motion == PageMotion.platform) {
      return MaterialPage<void>(
        key: state.pageKey,
        fullscreenDialog: fullscreenDialog,
        child: child,
      );
    }
    return CustomTransitionPage<void>(
      key: state.pageKey,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: lg,
      reverseTransitionDuration: exit(lg),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          transition(context, motion, animation, secondaryAnimation, child),
    );
  }

  /// The transition used by [page]; also usable in a PageView or Navigator.
  static Widget transition(
    BuildContext context,
    PageMotion motion,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (reduced(context)) return FadeTransition(opacity: animation, child: child);
    return switch (motion) {
      PageMotion.sharedAxisX => _sharedAxis(animation, secondary, child, Axis.horizontal),
      PageMotion.sharedAxisY => _sharedAxis(animation, secondary, child, Axis.vertical),
      PageMotion.fadeThrough => FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: const Interval(0.35, 1.0, curve: Curves.easeOut)),
          ),
          child: ScaleTransition(
            scale: animation.drive(
              Tween<double>(begin: 0.92, end: 1.0).chain(CurveTween(curve: enter)),
            ),
            child: child,
          ),
        ),
      PageMotion.slideUp => SlideTransition(
          position: animation.drive(
            Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: sheet)),
          ),
          child: child,
        ),
      PageMotion.fade || PageMotion.platform =>
        FadeTransition(opacity: animation, child: child),
    };
  }

  static Widget _sharedAxis(
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
    Axis axis,
  ) {
    Offset off(double v) => axis == Axis.horizontal ? Offset(v, 0) : Offset(0, v);
    return SlideTransition(
      position: secondary.drive(
        Tween<Offset>(begin: Offset.zero, end: off(-slidePage))
            .chain(CurveTween(curve: standard)),
      ),
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: off(slidePage), end: Offset.zero)
              .chain(CurveTween(curve: enter)),
        ),
        child: FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
          ),
          child: child,
        ),
      ),
    );
  }
}
