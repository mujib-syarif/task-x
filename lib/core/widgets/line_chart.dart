import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ChartSeries {
  const ChartSeries({required this.values, required this.color, this.label});

  final List<double> values;
  final Color color;
  final String? label;
}

/// Grafik garis ringan berbasis CustomPainter (tanpa dependency).
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.series,
    this.minY = 0,
    this.maxY,
    this.height = 130,
    this.filled = true,
    this.unit = '',
    this.decimals = 0,
  });

  final List<ChartSeries> series;
  final double minY;
  final double? maxY;
  final double height;
  final bool filled;
  final String unit;
  final int decimals;

  double _resolvedMax() {
    if (maxY != null) return maxY!;
    var m = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        m = math.max(m, v);
      }
    }
    return m <= 0 ? 1 : m * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = series.any((s) => s.values.length >= 2);
    final top = _resolvedMax();
    final grid = context.fg.withValues(alpha: 0.08);
    final labelStyle = TextStyle(fontSize: 10.5, color: context.muted);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _LinePainter(series: series, minY: minY, maxY: top, filled: filled, grid: grid),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Text('${top.toStringAsFixed(decimals)}$unit', style: labelStyle),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Text('${minY.toStringAsFixed(decimals)}$unit', style: labelStyle),
          ),
          if (!hasData)
            Center(
              child: Text('Mengumpulkan data…', style: labelStyle),
            ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.series,
    required this.minY,
    required this.maxY,
    required this.filled,
    required this.grid,
  });

  final List<ChartSeries> series;
  final double minY;
  final double maxY;
  final bool filled;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 0.6;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final range = maxY - minY;
    if (range <= 0) return;

    for (var si = 0; si < series.length; si++) {
      final s = series[si];
      final n = s.values.length;
      if (n < 2) continue;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final x = size.width * i / (n - 1);
        final norm = ((s.values[i] - minY) / range).clamp(0.0, 1.0);
        final y = size.height * (1 - norm);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      if (filled && si == 0) {
        final fill = Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [s.color.withValues(alpha: 0.28), s.color.withValues(alpha: 0.0)],
          ).createShader(Offset.zero & size);
        canvas.drawPath(fill, paint);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = s.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
