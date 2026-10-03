import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'motion/app_motion.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppMotion.personality = MotionPersonality.balanced;
  AppMotion.style = MotionStyle.springy;
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUi);
  runApp(const ProviderScope(child: FlutterGoApp()));
}

class FlutterGoApp extends ConsumerWidget {
  const FlutterGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUi,
      child: MaterialApp.router(
        title: 'Habits Demo',
        theme: AppTheme.light(),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
