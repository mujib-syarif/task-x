import 'package:flutter/material.dart';

import '../../core/models/device_models.dart';
import '../../core/services/native_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class SensorsPage extends StatefulWidget {
  const SensorsPage({super.key});

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> {
  late final Future<List<SensorItem>> _future = NativeBridge.instance.sensors();

  /// "android.sensor.accelerometer" -> "accelerometer"
  String _shortType(String t) => t.startsWith('android.sensor.') ? t.substring('android.sensor.'.length) : t;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar sensor')),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<SensorItem>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            final list = snap.data!;
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: LimitationNotice('Tidak ada sensor yang dilaporkan oleh sistem.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: list.length + 1,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        Text('${list.length} sensor', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const DataBadge(DataKind.snapshot),
                      ],
                    ),
                  );
                }
                final s = list[i - 1];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(Icons.sensors_rounded, size: 22),
                  title: Text(s.name),
                  subtitle: Text(
                    '${_shortType(s.type)} · ${s.vendor}'
                    '${s.power == null ? '' : ' · ${s.power!.toStringAsFixed(2)} mA'}',
                    style: TextStyle(color: context.muted, fontSize: 12.5),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
