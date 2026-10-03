import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_reveal.dart';

/// Size of the drawn neighbourhood, in logical pixels. Pins and routes on an
/// [AppStreetMap] are positioned in this coordinate space.
const Size kAppMapWorldSize = Size(420, 520);

/// A detailed street map drawn in code (scene world for onboarding, map and
/// tracking screens): blocks with building footprints, a park,
/// a creek, a main road, street names and a few shops. Real apps swap this
/// for flutter_map / Google Maps tiles; the motion around it stays the same.
class AppStreetMapPainter extends CustomPainter {
  const AppStreetMapPainter({this.places = const []});

  /// Landmarks from the app's own data (the real café, gym, clinic…), drawn
  /// as small labelled dots. Empty by default: never fill the map with
  /// generic filler places.
  final List<AppMapPlace> places;

  static const _land = Color(0xFFF3F0EA);
  static const _block = Color(0xFFECE7DE);
  static const _building = Color(0xFFE3DCD0);
  static const _buildingAlt = Color(0xFFDED6C8);
  static const _buildingEdge = Color(0xFFD6CDBD);
  static const _park = Color(0xFFCDE8C1);
  static const _parkTree = Color(0xFFB9DEAA);
  static const _water = Color(0xFFAED3EA);
  static const _road = Color(0xFFFFFFFF);
  static const _roadEdge = Color(0xFFDCD5C8);
  static const _main = Color(0xFFFDE6A2);
  static const _mainEdge = Color(0xFFE9C76B);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    canvas.drawRect(Offset.zero & kAppMapWorldSize, Paint()..color = _land);

    // Creek.
    final creek = Path()
      ..moveTo(-20, 450)
      ..cubicTo(90, 410, 160, 500, 260, 462)
      ..cubicTo(330, 436, 380, 470, 450, 450);
    canvas.drawPath(
      creek,
      Paint()
        ..color = _water
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round,
    );

    // Blocks, park and building footprints.
    const xs = <double>[0, 60, 150, 230, 330, 420];
    const ys = <double>[0, 60, 150, 250, 340, 420];
    for (var i = 0; i < xs.length - 1; i++) {
      for (var j = 0; j < ys.length - 1; j++) {
        final x0 = xs[i] + 7, x1 = xs[i + 1] - 7, y0 = ys[j] + 7, y1 = ys[j + 1] - 7;
        final rect = Rect.fromLTRB(x0, y0, x1, y1);
        if (i == 3 && j == 2) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8)),
            Paint()..color = _park,
          );
          final tree = Paint()..color = _parkTree;
          for (var k = 0; k < 14; k++) {
            canvas.drawCircle(
              Offset(x0 + 8 + rnd.nextDouble() * (rect.width - 16),
                  y0 + 8 + rnd.nextDouble() * (rect.height - 16)),
              3 + rnd.nextDouble() * 4,
              tree,
            );
          }
          continue;
        }
        canvas.drawRect(rect, Paint()..color = _block);
        var y = y0 + 3;
        while (y < y1 - 8) {
          final h = 12 + rnd.nextDouble() * 16;
          var x = x0 + 3;
          while (x < x1 - 8) {
            final w = 10 + rnd.nextDouble() * 22;
            final ww = math.min(w, x1 - 3 - x), hh = math.min(h, y1 - 3 - y);
            if (ww > 6 && hh > 6) {
              final r = Rect.fromLTWH(x, y, ww, hh);
              canvas.drawRect(r, Paint()..color = rnd.nextDouble() > .85 ? _buildingAlt : _building);
              canvas.drawRect(
                r.deflate(.3),
                Paint()
                  ..color = _buildingEdge
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = .6,
              );
            }
            x += w + 2.5;
          }
          y += h + 2.5;
        }
      }
    }

    // Roads: casing first, then fill.
    void road(Offset a, Offset b, double w, Color fill, Color edge) {
      canvas.drawLine(a, b, Paint()
        ..color = edge
        ..strokeWidth = w + 2);
      canvas.drawLine(a, b, Paint()
        ..color = fill
        ..strokeWidth = w);
    }

    for (final y in const <double>[60, 150, 340]) {
      road(Offset(0, y), Offset(420, y), 8, _road, _roadEdge);
    }
    for (final x in const <double>[60, 230, 330]) {
      road(Offset(x, 0), Offset(x, 520), 8, _road, _roadEdge);
    }
    road(const Offset(150, 0), const Offset(150, 520), 11, _road, const Color(0xFFD2CABB));
    road(const Offset(0, 250), const Offset(420, 250), 13, _main, _mainEdge);

    // Street names and places.
    _label(canvas, 'Market St', const Offset(380, 250), color: const Color(0xFF7A6430), size: 9, bold: true);
    _label(canvas, 'Market St', const Offset(95, 250), color: const Color(0xFF7A6430), size: 9, bold: true);
    _label(canvas, 'Oak Ave', const Offset(150, 100), rotate: -math.pi / 2);
    _label(canvas, 'Oak Ave', const Offset(150, 395), rotate: -math.pi / 2);
    _label(canvas, 'Elm St', const Offset(105, 60));
    _label(canvas, 'Elm St', const Offset(280, 60));
    _label(canvas, 'Birch St', const Offset(280, 340));
    _label(canvas, 'Linden Rd', const Offset(60, 200), rotate: -math.pi / 2);
    _label(canvas, 'Cedar Ln', const Offset(330, 110), rotate: -math.pi / 2);
    _label(canvas, 'Linden Park', const Offset(280, 200), color: const Color(0xFF4F7F42), size: 9.5, bold: true);
    _label(canvas, 'Mill Creek', const Offset(300, 452), color: const Color(0xFF4E86A8), size: 9, rotate: -.12, italic: true);

    for (final p in places) {
      canvas.drawCircle(p.at, 6.5, Paint()..color = Colors.white);
      canvas.drawCircle(p.at, 5, Paint()..color = p.color);
      _label(canvas, p.name, p.at + const Offset(0, 12), color: p.color, size: 7.5, bold: true);
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    Color color = const Color(0xFF6E6A63),
    double size = 8.5,
    double rotate = 0,
    bool bold = false,
    bool italic = false,
  }) {
    TextPainter make(Paint? stroke) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              color: stroke == null ? color : null,
              foreground: stroke,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    final halo = make(Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white);
    final fill = make(null);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(rotate);
    final o = Offset(-fill.width / 2, -fill.height / 2);
    halo.paint(canvas, o);
    fill.paint(canvas, o);
    canvas.restore();
    halo.dispose();
    fill.dispose();
  }

  @override
  bool shouldRepaint(AppStreetMapPainter oldDelegate) => oldDelegate.places != places;
}

/// A named landmark painted on [AppStreetMap] (world coordinates).
class AppMapPlace {
  const AppMapPlace({required this.name, required this.at, this.color = const Color(0xFF6E6A63)});

  final String name;
  final Offset at;
  final Color color;
}

/// The map viewport: a camera over the neighbourhood that eases in from a
/// slightly zoomed-in position (map apps do this when they open). [children]
/// are positioned in world coordinates, so pins and routes move with the map.
class AppStreetMap extends StatelessWidget {
  const AppStreetMap({
    super.key,
    this.camera = const Offset(-24, -40),
    this.zoom = 1,
    this.places = const [],
    this.children = const [],
  });

  /// Top-left offset of the world inside the viewport (usually negative).
  /// Clamped so the map always covers the whole stage — no blank bands.
  final Offset camera;
  final double zoom;

  /// Real landmarks from the app's data (see [AppMapPlace]); none by default.
  final List<AppMapPlace> places;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : kAppMapWorldSize.width;
          final h = box.maxHeight.isFinite ? box.maxHeight : kAppMapWorldSize.height;
          // Never smaller than the stage: scale up until the world covers it.
          final cover = math.max(w / kAppMapWorldSize.width, h / kAppMapWorldSize.height);
          final base = math.max(zoom, cover);
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: AppMotion.resolve(context, const Duration(milliseconds: 1100)),
            curve: AppMotion.enter,
            child: SizedBox.fromSize(
              size: kAppMapWorldSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(child: CustomPaint(painter: AppStreetMapPainter(places: places))),
                  ),
                  ...children,
                ],
              ),
            ),
            builder: (context, t, world) {
              final settle = 1 - t;
              final scale = base * (1 + 0.12 * settle);
              final minX = w - kAppMapWorldSize.width * scale;
              final minY = h - kAppMapWorldSize.height * scale;
              final want = camera + Offset(-30 * settle, -20 * settle);
              final offset = Offset(
                want.dx.clamp(math.min(minX, 0.0), 0.0),
                want.dy.clamp(math.min(minY, 0.0), 0.0),
              );
              return OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: 0,
                minHeight: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.translate(
                  offset: offset,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: world,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// A map-app style pin on a short stem; its tip sits on [at] (world
/// coordinates). For people, pets, pros, dishes or places pass a real
/// [photo] (e.g. `AssetImage(AppAssets.petChili)`) — the pin then shows that
/// face in a white ring. [icon] is for categories only (a fuel stop, a
/// charger), never a stand-in for a real person or thing.
class AppMapPin extends StatelessWidget {
  const AppMapPin({
    super.key,
    required this.at,
    this.photo,
    this.icon,
    this.color = const Color(0xFF111418),
    this.label,
    this.selected = false,
    this.revealDelay = Duration.zero,
  });

  final Offset at;
  final ImageProvider? photo;
  final IconData? icon;
  final Color color;
  final String? label;
  final bool selected;
  final Duration revealDelay;

  @override
  Widget build(BuildContext context) {
    final d = photo != null ? (selected ? 50.0 : 42.0) : (selected ? 42.0 : 34.0);
    final initial = (label ?? '').trim();
    return Positioned(
      left: at.dx - d / 2,
      top: at.dy - d - 12,
      child: AppReveal.pop(
        delay: revealDelay,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: d,
                  height: d,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? color : Colors.white, width: photo != null ? 3 : 2.5),
                    image: photo != null ? DecorationImage(image: photo!, fit: BoxFit.cover) : null,
                    boxShadow: [
                      const BoxShadow(color: Color(0x47000000), blurRadius: 8, offset: Offset(0, 3)),
                      if (selected) BoxShadow(color: color.withAlpha(60), spreadRadius: 6),
                    ],
                  ),
                  child: photo != null
                      ? null
                      : icon != null
                          ? Icon(icon, color: Colors.white, size: d * 0.5)
                          : Center(
                              child: Text(
                                initial.isEmpty ? '' : initial.substring(0, 1).toUpperCase(),
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: d * 0.42),
                              ),
                            ),
                ),
                Container(width: 3, height: 10, color: selected ? color : Colors.white),
              ],
            ),
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 7),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))],
                  ),
                  child: Text(
                    label!,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111418),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
