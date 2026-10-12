import 'package:flutter/material.dart';

import '../../../core/services/metrics_service.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/line_chart.dart';
import 'tab_common.dart';

class NetworkTab extends StatelessWidget {
  const NetworkTab({super.key, required this.snap});

  final MetricsSnapshot? snap;

  @override
  Widget build(BuildContext context) {
    final n = snap?.network;
    final down = Services.metrics.history(Series.netDown);
    final up = Services.metrics.history(Series.netUp);

    return TabScaffold(
      snap: snap,
      children: [
        ChartCard(
          title: 'Lalu lintas jaringan seluruh sistem',
          footer: 'Biru: unduh · Hijau: unggah · satuan KB/s. ${historyFooter()}',
          child: LineChart(
            series: [
              ChartSeries(values: down.map((e) => e / 1024).toList(), color: AppColors.blue, label: 'Unduh'),
              ChartSeries(values: up.map((e) => e / 1024).toList(), color: AppColors.green, label: 'Unggah'),
            ],
            unit: ' KB/s',
            filled: Services.settings.filledCharts,
            height: 110,
          ),
        ),
        RowsCard(
          rows: [
            InfoRow('Koneksi aktif', n?.typeLabel ?? kUnavailable),
            InfoRow('VPN aktif', n == null ? kUnavailable : (n.vpn ? 'Ya' : 'Tidak')),
            InfoRow('Internet tervalidasi', n == null ? kUnavailable : (n.validated ? 'Ya' : 'Tidak')),
            InfoRow('Jaringan berbayar (metered)', n == null ? kUnavailable : (n.metered ? 'Ya' : 'Tidak')),
            InfoRow('Kecepatan unduh saat ini', formatRate(snap?.netDownBps)),
            InfoRow('Kecepatan unggah saat ini', formatRate(snap?.netUpBps)),
            InfoRow('Total diterima (sejak boot)', n?.rxBytes == null ? kUnavailable : formatBytes(n!.rxBytes)),
            InfoRow('Total dikirim (sejak boot)', n?.txBytes == null ? kUnavailable : formatBytes(n!.txBytes)),
            InfoRow('Seluler diterima', n?.mobileRxBytes == null ? kUnavailable : formatBytes(n!.mobileRxBytes)),
            InfoRow('Seluler dikirim', n?.mobileTxBytes == null ? kUnavailable : formatBytes(n!.mobileTxBytes)),
            InfoRow(
              'Estimasi kapasitas link (unduh/unggah)',
              n?.downKbps == null ? kUnavailable : '${n!.downKbps} / ${n.upKbps ?? '—'} Kbps',
            ),
          ],
        ),
        const LimitationNotice(
          'Kecepatan dihitung dari selisih penghitung lalu lintas sistem, bukan per aplikasi. '
          'Android tidak menyediakan kecepatan jaringan per aplikasi secara real-time. '
          'Estimasi kapasitas link adalah perkiraan sistem, bukan hasil uji kecepatan.',
        ),
      ],
    );
  }
}
