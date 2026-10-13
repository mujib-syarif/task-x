import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/device_models.dart';
import '../../core/services/metrics_service.dart';
import '../../core/services/native_bridge.dart';
import '../../core/services/report_service.dart';
import '../../core/services/services.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';

class SystemInfoPage extends StatefulWidget {
  const SystemInfoPage({super.key});

  @override
  State<SystemInfoPage> createState() => _SystemInfoPageState();
}

class _SystemInfoPageState extends State<SystemInfoPage> {
  late final Future<List<Object?>> _future = Future.wait<Object?>([
    NativeBridge.instance.deviceInfo(),
    NativeBridge.instance.sensors(),
  ]);

  @override
  void initState() {
    super.initState();
    Services.metrics.refresh();
  }

  Future<void> _copy(List<ReportSection> sections) async {
    final text = ReportService.toText(sections);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showMessage(context, 'Informasi sistem disalin');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object?>>(
      future: _future,
      builder: (context, fs) {
        final device = fs.data?[0] as DeviceInfo?;
        final sensors = (fs.data?[1] as List<SensorItem>?) ?? const <SensorItem>[];
        return ValueListenableBuilder<MetricsSnapshot?>(
          valueListenable: Services.metrics.snapshot,
          builder: (context, snap, _) {
            final sections = ReportService.sections(device, snap, sensors);
            return Scaffold(
              appBar: AppBar(
                title: const Text('System Inspector'),
                actions: [
                  IconButton(
                    tooltip: 'Salin semua',
                    icon: const Icon(Icons.copy_all_rounded),
                    onPressed: fs.hasData ? () => _copy(sections) : null,
                  ),
                ],
              ),
              body: SafeArea(
                top: false,
                child: !fs.hasData
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: DataBadge(DataKind.snapshot, detail: 'tekan lama untuk menyalin satu nilai'),
                            ),
                          ),
                          for (final s in sections) ...[
                            SectionTitle(s.title),
                            GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                children: [for (final r in s.rows) InfoRow(r.label, r.value)],
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
