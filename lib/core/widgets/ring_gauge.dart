import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Indikator lingkaran. `value` null berarti data tidak tersedia (hanya trek yang digambar).
class RingGauge extends StatelessWidget {
  const RingGauge({
    super.key,
    required this.value,
    required this.color,
    this.size = 76,
    this.stroke = 7,
    this.child,
  });

  final double? value;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value: value, color: color, track: track, stroke: stroke),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track, required this.stroke});

  final double? value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    final v = value;
    if (v == null) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * v.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track || old.stroke != stroke;
}
