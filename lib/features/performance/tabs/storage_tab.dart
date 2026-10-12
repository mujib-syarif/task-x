import 'package:flutter/material.dart';

import '../../../core/services/metrics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/ring_gauge.dart';
import '../../storage/storage_page.dart';
import 'tab_common.dart';

class StorageTab extends StatelessWidget {
  const StorageTab({super.key, required this.snap});

  final MetricsSnapshot? snap;

  @override
  Widget build(BuildContext context) {
    final s = snap?.storage;
    final f = s?.usedFraction;

    return TabScaffold(
      snap: snap,
      children: [
        ChartCard(
          title: 'Penyimpanan internal',
          child: Row(
            children: [
              RingGauge(
                value: f,
                color: f == null ? AppColors.blue : AppColors.usage(f),
                size: 92,
                child: Text(formatPercent(f), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    InfoRow('Total', s == null ? kUnavailable : formatBytes(s.totalBytes)),
                    InfoRow('Terpakai', s == null ? kUnavailable : formatBytes(s.usedBytes)),
                    InfoRow('Tersedia', s == null ? kUnavailable : formatBytes(s.availBytes)),
                  ],
                ),
              ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StoragePage())),
          icon: const Icon(Icons.folder_open_rounded, size: 20),
          label: const Text('Buka Storage Analyzer'),
        ),
        const SizedBox(height: 12),
        const LimitationNotice(
          'Nilai ini adalah snapshot partisi data. Riwayat grafik tidak ditampilkan karena penyimpanan berubah lambat.',
        ),
      ],
    );
  }
}
