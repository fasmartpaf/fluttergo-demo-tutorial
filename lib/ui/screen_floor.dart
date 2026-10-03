import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One player per screen. Home may use [FloorKind.tideWave]. The next screen
/// must pick a different kind after MOTION_DISCOVERY.
enum FloorKind {
  /// No ambient layer: the background colour only. A valid, often best, choice.
  none,
  tideWave,
  meshOrbs,
  parallaxBands,
  sheenSweep,
  orbitDots,
  pathRing,
  foamDrift,
  gridPulse,
}

/// Optional ambient background per screen. Use a player only where the
/// screen earns it; `FloorKind.none` is the plain background.
class ScreenFloor extends StatelessWidget {
  const ScreenFloor({
    super.key,
    required this.child,
    this.kind = FloorKind.none,
    this.title,
    this.waveColor,
    this.waveHeight = 72,
  });

  final Widget child;
  final FloorKind kind;
  final String? title;
  final Color? waveColor;
  final double waveHeight;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    final color = waveColor ?? colors.secondary.withValues(alpha: 0.45);
    return Material(
      color: colors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FloorPlayer(kind: kind, color: color, waveHeight: waveHeight),
          child,
        ],
      ),
    );
  }
}

class FloorPlayer extends StatelessWidget {
  const FloorPlayer({
    super.key,
    required this.kind,
    required this.color,
    this.waveHeight = 72,
  });

  final FloorKind kind;
  final Color color;
  final double waveHeight;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case FloorKind.none:
        return const SizedBox.shrink();
      case FloorKind.tideWave:
        return Align(
          alignment: Alignment.bottomCenter,
          child: TideWave(height: waveHeight, color: color),
        );
      case FloorKind.meshOrbs:
      case FloorKind.parallaxBands:
      case FloorKind.sheenSweep:
      case FloorKind.orbitDots:
      case FloorKind.pathRing:
      case FloorKind.foamDrift:
      case FloorKind.gridPulse:
        return SizedBox.expand(
          child: _LoopingFloor(kind: kind, color: color),
        );
    }
  }
}

/// Animated sine tide. Empty-project / home default only.
class TideWave extends StatefulWidget {
  const TideWave({super.key, this.height = 156, required this.color});

  final double height;
  final Color color;

  @override
  State<TideWave> createState() => _TideWaveState();
}

class _TideWaveState extends State<TideWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            painter: _TidePainter(
              t: reduced ? 0.18 : _c.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _LoopingFloor extends StatefulWidget {
  const _LoopingFloor({required this.kind, required this.color});

  final FloorKind kind;
  final Color color;

  @override
  State<_LoopingFloor> createState() => _LoopingFloorState();
}

class _LoopingFloorState extends State<_LoopingFloor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          painter: _CatalogPainter(
            kind: widget.kind,
            t: reduced ? 0.2 : _c.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _TidePainter extends CustomPainter {
  _TidePainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    Path crest(double amp1, double amp2, double phase) {
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 3) {
        final y = size.height * 0.58 +
            math.sin((x / size.width * math.pi * 2) + phase) * amp1 +
            math.sin((x / size.width * math.pi * 4) + phase * 1.5) * amp2;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    final fill = crest(18, 7, t * math.pi * 2);
    fill
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawPath(
      crest(18, 7, t * math.pi * 2),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TidePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}

class _CatalogPainter extends CustomPainter {
  _CatalogPainter({required this.kind, required this.t, required this.color});

  final FloorKind kind;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.28);
    final phase = t * math.pi * 2;
    switch (kind) {
      case FloorKind.none:
      case FloorKind.tideWave:
        return;
      case FloorKind.meshOrbs:
        for (var i = 0; i < 5; i++) {
          final x = size.width * (0.12 + (i * 0.18)) + math.sin(phase + i) * 16;
          final y = size.height * (0.22 + (i.isOdd ? 0.18 : 0.08)) +
              math.cos(phase * 0.8 + i) * 14;
          canvas.drawCircle(Offset(x, y), 18 + i * 3.0, paint);
        }
      case FloorKind.parallaxBands:
        for (var i = 0; i < 3; i++) {
          final y = size.height * (0.62 + i * 0.1) + math.sin(phase + i) * 8;
          canvas.drawRRect(
            RRect.fromLTRBR(0, y, size.width, y + 28, const Radius.circular(20)),
            paint..color = color.withValues(alpha: 0.12 + i * 0.05),
          );
        }
      case FloorKind.sheenSweep:
        final x = (t * (size.width + 160)) - 80;
        canvas.drawRect(
          Rect.fromLTWH(x, 0, 72, size.height),
          Paint()
            ..shader = LinearGradient(
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromLTWH(x, 0, 72, size.height)),
        );
      case FloorKind.orbitDots:
        final c = Offset(size.width * 0.82, size.height * 0.18);
        for (var i = 0; i < 6; i++) {
          final a = phase + i * math.pi / 3;
          canvas.drawCircle(
            c + Offset(math.cos(a) * 36, math.sin(a) * 22),
            4,
            paint,
          );
        }
      case FloorKind.pathRing:
        final rect = Rect.fromCircle(
          center: Offset(size.width * 0.86, size.height * 0.16),
          radius: 28,
        );
        canvas.drawArc(
          rect,
          phase,
          math.pi * 1.3,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      case FloorKind.foamDrift:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              size.width * 0.2 + math.sin(phase) * 20,
              size.height * 0.78,
            ),
            width: 160,
            height: 70,
          ),
          paint..color = color.withValues(alpha: 0.16),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              size.width * 0.7 + math.cos(phase) * 16,
              size.height * 0.86,
            ),
            width: 200,
            height: 80,
          ),
          paint..color = color.withValues(alpha: 0.12),
        );
      case FloorKind.gridPulse:
        final step = 36.0;
        final grid = Paint()
          ..color = color.withValues(alpha: 0.08)
          ..strokeWidth = 1;
        for (var x = 0.0; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
        }
        for (var y = 0.0; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
        }
        canvas.drawCircle(
          Offset(size.width * 0.78, size.height * 0.22),
          5 + math.sin(phase) * 2,
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CatalogPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.kind != kind ||
      oldDelegate.color != color;
}
