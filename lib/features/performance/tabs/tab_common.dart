import 'package:flutter/material.dart';

import '../../../core/services/metrics_service.dart';
import '../../../core/services/services.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/glass_card.dart';

/// Kerangka halaman tab: daftar bergulir dengan waktu pembaruan terakhir.
class TabScaffold extends StatelessWidget {
  const TabScaffold({super.key, required this.snap, required this.children});

  final MetricsSnapshot? snap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = snap;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (s == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                DataBadge(DataKind.periodic, detail: '${Services.settings.intervalSeconds} dtk'),
                const Spacer(),
                Text(
                  'Diperbarui ${formatClock(s.time)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ],
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.child, this.footer});

  final String title;
  final Widget child;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            child,
            if (footer != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(footer!, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
              ),
          ],
        ),
      ),
    );
  }
}

class RowsCard extends StatelessWidget {
  const RowsCard({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: rows),
      ),
    );
  }
}

String historyFooter() =>
    'Riwayat selama aplikasi aktif · maks ${Services.settings.historyPoints} titik · interval ${Services.settings.intervalSeconds} dtk';
