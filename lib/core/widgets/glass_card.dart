import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Panel semi-transparan dengan border tipis dan highlight lembut.
/// Sengaja TANPA blur per-kartu agar ringan di perangkat kelas menengah.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final border = dark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.06);
    final top = dark ? Colors.white.withValues(alpha: 0.085) : Colors.white.withValues(alpha: 0.92);
    final bottom = dark ? Colors.white.withValues(alpha: 0.035) : Colors.white.withValues(alpha: 0.70);
    final shape = BorderRadius.circular(radius);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: shape,
          border: Border.all(color: border, width: 0.8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, bottom],
          ),
        ),
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
