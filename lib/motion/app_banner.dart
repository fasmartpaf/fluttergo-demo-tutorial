import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_reveal.dart';

/// System-style notification card (frosted, rounded, app icon + title + text).
class AppBannerCard extends StatelessWidget {
  const AppBannerCard({
    super.key,
    required this.title,
    required this.message,
    this.leading,
    this.trailing = 'now',
  });

  final String title;
  final String message;
  final Widget? leading;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Transparent Material: banners are shown in the Overlay, above any
    // Scaffold, where text would otherwise get the debug red/yellow style.
    return Material(
      type: MaterialType.transparency,
      child: Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 11),
            decoration: BoxDecoration(
              color: const Color(0xE6F6F6F8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  SizedBox.square(dimension: 34, child: leading),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: text.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111418),
                              ),
                            ),
                          ),
                          if (trailing != null)
                            Text(
                              trailing!,
                              style: text.labelSmall?.copyWith(color: const Color(0xFF6B7280)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        message,
                        style: text.bodySmall?.copyWith(
                          color: const Color(0xFF1F2328),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Shows [AppBannerCard] dropping in from the top of the screen.
/// Swipe up or wait [visibleFor] to dismiss.
void showAppBanner(
  BuildContext context, {
  required String title,
  required String message,
  Widget? leading,
  Duration visibleFor = const Duration(seconds: 4),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  var removed = false;
  void remove() {
    if (removed) return;
    removed = true;
    entry
      ..remove()
      ..dispose();
  }

  entry = OverlayEntry(
    builder: (context) => _BannerHost(
      visibleFor: visibleFor,
      onDone: remove,
      child: AppBannerCard(title: title, message: message, leading: leading),
    ),
  );
  overlay.insert(entry);
}

class _BannerHost extends StatefulWidget {
  const _BannerHost({required this.child, required this.visibleFor, required this.onDone});

  final Widget child;
  final Duration visibleFor;
  final VoidCallback onDone;

  @override
  State<_BannerHost> createState() => _BannerHostState();
}

class _BannerHostState extends State<_BannerHost> {
  Timer? _timer;
  Timer? _exitTimer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.visibleFor, _leave);
  }

  void _leave() {
    if (!mounted || _leaving) return;
    setState(() => _leaving = true);
    _exitTimer = Timer(AppMotion.exit(AppMotion.lg), widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _exitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      right: 8,
      top: MediaQuery.paddingOf(context).top + 6,
      child: GestureDetector(
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < 0) _leave();
        },
        child: AnimatedSlide(
          offset: _leaving ? const Offset(0, -1.4) : Offset.zero,
          duration: AppMotion.resolve(context, AppMotion.exit(AppMotion.lg)),
          curve: AppMotion.exitCurve,
          child: AppReveal.drop(child: widget.child),
        ),
      ),
    );
  }
}
