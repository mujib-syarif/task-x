import 'package:flutter/material.dart';

import '../../../core/models/device_models.dart';
import '../../../core/services/metrics_service.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/line_chart.dart';
import '../../../core/widgets/ring_gauge.dart';
import 'tab_common.dart';

List<Widget> _coreRows(CpuInfo? cpu) {
  if (cpu == null || !cpu.hasFrequencies) {
    return const [InfoRow('Frekuensi per-core', kUnavailable)];
  }
  final rows = <Widget>[];
  for (var i = 0; i < cpu.curKhz.length; i++) {
    final cur = cpu.curKhz[i];
    final max = cpu.maxKhz.length > i ? cpu.maxKhz[i] : null;
    var text = cur == null ? 'Offline / tidak terbaca' : formatFrequency(cur);
    if (cur != null && max != null) {
      text = '$text / maks ${formatFrequency(max)}';
    }
    rows.add(InfoRow('Core $i', text));
  }
  return rows;
}

class CpuTab extends StatelessWidget {
  const CpuTab({super.key, required this.snap});

  final MetricsSnapshot? snap;

  @override
  Widget build(BuildContext context) {
    final s = snap;
    final cpu = s?.cpu;
    final supported = cpu?.stat != null;
    final usage = s?.cpuUsage;
    final history = Services.metrics.history(Series.cpu);

    return TabScaffold(
      snap: s,
      children: [
        if (!supported)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LimitationNotice(
              'Android modern (8+) tidak mengizinkan aplikasi biasa membaca penggunaan CPU total maupun per-core '
              '(/proc/stat dibatasi). Task X tidak menyimulasikan angka; hanya data yang benar-benar tersedia ditampilkan.',
            ),
          )
        else
          ChartCard(
            title: 'Penggunaan CPU total',
            footer: historyFooter(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RingGauge(
                  value: usage,
                  color: usage == null ? AppColors.blue : AppColors.usage(usage),
                  child: Text(formatPercent(usage), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LineChart(
                    series: [ChartSeries(values: history, color: AppColors.blue)],
                    maxY: 100,
                    unit: '%',
                    filled: Services.settings.filledCharts,
                    height: 100,
                  ),
                ),
              ],
            ),
          ),
        RowsCard(
          rows: [
            InfoRow('Jumlah core', cpu == null ? kUnavailable : '${cpu.cores}'),
            ..._coreRows(cpu),
          ],
        ),
        const LimitationNotice(
          'Frekuensi dibaca dari sysfs (cpufreq) dan bisa tidak tersedia di beberapa perangkat/versi sistem.',
        ),
      ],
    );
  }
}
