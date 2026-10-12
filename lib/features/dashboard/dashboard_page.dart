import 'package:flutter/material.dart';

import '../../core/services/app_settings.dart';
import '../../core/services/metrics_service.dart';
import '../../core/services/services.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/common_widgets.dart';
import 'dashboard_cards.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Services.settings;
    final metrics = Services.metrics;

    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ValueListenableBuilder<MetricsSnapshot?>(
            valueListenable: metrics.snapshot,
            builder: (context, snap, _) {
              final modules = settings.modules;
              final interval = '${settings.intervalSeconds} dtk';
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
                    child: Row(
                      children: [
                        const BrandMark(),
                        const Spacer(),
                        if (snap != null)
                          Text(
                            formatClock(snap.time),
                            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                          ),
                      ],
                    ),
                  ),
                  if (snap == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else ...[
                    if (modules.contains(DashboardModule.ram)) RamCard(snap: snap, interval: interval),
                    if (modules.contains(DashboardModule.cpu)) CpuCard(snap: snap, interval: interval),
                    if (modules.contains(DashboardModule.storage)) StorageCard(snap: snap),
                    if (modules.contains(DashboardModule.battery)) BatteryCard(snap: snap, interval: interval),
                    if (modules.contains(DashboardModule.network)) NetworkCard(snap: snap, interval: interval),
                    if (modules.contains(DashboardModule.system)) SystemCard(snap: snap),
                    const SizedBox(height: 8),
                    const Center(child: DataBadge(DataKind.periodic, detail: 'pembaruan tiap interval pengaturan')),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
