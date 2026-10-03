import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_chrome_stub.dart'
    if (dart.library.html) 'app_chrome_web.dart' as platform;

/// Per-screen system chrome — do NOT freeze one color for the whole app.
/// Dark header screens (sign-in hero) need dark status + light icons;
/// light home/dashboard screens need light status + dark icons.
class AppChrome {
  static SystemUiOverlayStyle styleFor({
    required Color top,
    required Color bottom,
  }) {
    final topDark = top.computeLuminance() < 0.45;
    final bottomDark = bottom.computeLuminance() < 0.45;
    return SystemUiOverlayStyle(
      statusBarColor: top,
      statusBarIconBrightness:
          topDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: topDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: bottom,
      systemNavigationBarIconBrightness:
          bottomDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: const Color(0x00000000),
    );
  }

  static void apply({required Color top, required Color bottom}) {
    final style = styleFor(top: top, bottom: bottom);
    SystemChrome.setSystemUIOverlayStyle(style);
    platform.syncPreviewChrome(top, bottom);
  }
}

/// Wrap each route/screen so status + home-indicator bars match THAT screen.
class ChromeScope extends StatefulWidget {
  const ChromeScope({
    super.key,
    required this.top,
    required this.bottom,
    required this.child,
  });

  final Color top;
  final Color bottom;
  final Widget child;

  @override
  State<ChromeScope> createState() => _ChromeScopeState();
}

class _ChromeScopeState extends State<ChromeScope> {
  @override
  void initState() {
    super.initState();
    AppChrome.apply(top: widget.top, bottom: widget.bottom);
  }

  @override
  void didUpdateWidget(covariant ChromeScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.top != widget.top || oldWidget.bottom != widget.bottom) {
      AppChrome.apply(top: widget.top, bottom: widget.bottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppChrome.styleFor(top: widget.top, bottom: widget.bottom),
      child: widget.child,
    );
  }
}
