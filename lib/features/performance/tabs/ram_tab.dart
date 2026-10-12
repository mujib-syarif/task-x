import 'package:flutter/material.dart';

import '../../../core/models/device_models.dart';
import '../../../core/services/metrics_service.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/line_chart.dart';
import '../../../core/widgets/ring_gauge.dart';
import 'tab_common.dart';

class RamTab extends StatelessWidget {
  const RamTab({super.key, required this.snap});

  final MetricsSnapshot? snap;

  @override
  Widget build(BuildContext context) {
    final m = snap?.memory;
    final f = m?.usedFraction;
    final history = Services.metrics.history(Series.ram);

    return TabScaffold(
      snap: snap,
      children: [
        ChartCard(
          title: 'Memori sistem terpakai',
          footer: historyFooter(),
          child: Row(
            children: [
              RingGauge(
                value: f,
                color: f == null ? AppColors.blue : AppColors.usage(f),
                child: Text(formatPercent(f), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LineChart(
                  series: [ChartSeries(values: history, color: AppColors.purple)],
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
            InfoRow('Total (dilaporkan sistem)', m == null ? kUnavailable : formatBytes(m.totalBytes)),
            InfoRow('Digunakan', m == null ? kUnavailable : formatBytes(m.usedBytes)),
            InfoRow('Tersedia', m == null ? kUnavailable : formatBytes(m.availBytes)),
            InfoRow('Ambang memori rendah', m == null ? kUnavailable : formatBytes(m.thresholdBytes)),
            InfoRow('Status', m == null ? kUnavailable : (m.lowMemory ? 'Memori rendah' : 'Normal')),
          ],
        ),
        const SectionTitle('Memori proses Task X'),
        const _OwnProcessCard(),
        const LimitationNotice(
          'Android tidak mengizinkan aplikasi biasa membaca memori proses aplikasi lain. '
          'Hanya memori proses Task X sendiri yang ditampilkan.',
        ),
      ],
    );
  }
}

class _OwnProcessCard extends StatefulWidget {
  const _OwnProcessCard();

  @override
  State<_OwnProcessCard> createState() => _OwnProcessCardState();
}

class _OwnProcessCardState extends State<_OwnProcessCard> {
  late final Future<OwnProcessInfo?> _future = NativeBridge.instance.ownProcess();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OwnProcessInfo?>(
      future: _future,
      builder: (context, s) {
        final p = s.data;
        return RowsCard(
          rows: [
            InfoRow('PID', p == null ? kUnavailable : '${p.pid}'),
            InfoRow('PSS (snapshot)', p == null ? kUnavailable : formatBytes(p.pssKb * 1024)),
          ],
        );
      },
    );
  }
}
