import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// PLACEHOLDER card: a plain outlined box. Give it the surface treatment,
/// shape and depth from the design direction (flat, tinted, outlined,
/// lifted, glass… or no cards at all). The name is historical, not a look.
class PaperCard extends StatelessWidget {
  const PaperCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}
