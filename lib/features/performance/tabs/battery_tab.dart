import 'package:flutter/material.dart';

import '../../../core/services/metrics_service.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/line_chart.dart';
import '../../../core/widgets/ring_gauge.dart';
import 'tab_common.dart';

class BatteryTab extends StatelessWidget {
  const BatteryTab({super.key, required this.snap});

  final MetricsSnapshot? snap;

  @override
  Widget build(BuildContext context) {
    final b = snap?.battery;
    final p = b?.percent;
    final f = p == null ? null : p / 100;
    final level = Services.metrics.history(Series.batteryLevel);
    final temp = Services.metrics.history(Series.batteryTemp);
    final filled = Services.settings.filledCharts;
    final current = b?.currentNowUa;

    return TabScaffold(
      snap: snap,
      children: [
        ChartCard(
          title: 'Level baterai',
          footer: historyFooter(),
          child: Row(
            children: [
              RingGauge(
                value: f,
                color: f == null
                    ? AppColors.blue
                    : (b!.isCharging ? AppColors.green : (f < 0.2 ? AppColors.red : AppColors.blue)),
                child: Text(p == null ? '—' : '$p%', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LineChart(
                  series: [ChartSeries(values: level, color: AppColors.green)],
                  maxY: 100,
                  unit: '%',
                  filled: filled,
                  height: 100,
                ),
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Suhu baterai',
          footer: 'Hanya suhu baterai yang tersedia; suhu CPU/komponen lain tidak dapat dibaca aplikasi biasa.',
          child: LineChart(
            series: [ChartSeries(values: temp, color: AppColors.orange)],
            minY: 20,
            maxY: 60,
            unit: '°C',
            filled: filled,
            height: 100,
          ),
        ),
        RowsCard(
          rows: [
            InfoRow('Status', b?.statusLabel ?? kUnavailable),
            InfoRow('Sumber daya', b?.pluggedLabel ?? kUnavailable),
            InfoRow('Suhu baterai', b?.temperatureC == null ? kUnavailable : '${b!.temperatureC!.toStringAsFixed(1)} °C'),
            InfoRow('Tegangan', b?.voltageMv == null ? kUnavailable : '${b!.voltageMv} mV'),
            InfoRow('Kondisi', b?.healthLabel ?? kUnavailable),
            InfoRow('Teknologi', b?.technology ?? kUnavailable),
            InfoRow(
              'Arus saat ini',
              current == null ? kUnavailable : '${(current / 1000).toStringAsFixed(0)} mA',
            ),
          ],
        ),
        const LimitationNotice(
          'Nilai arus bergantung pada driver perangkat dan dapat memakai satuan/tanda yang berbeda antar produsen.',
        ),
      ],
    );
  }
}
