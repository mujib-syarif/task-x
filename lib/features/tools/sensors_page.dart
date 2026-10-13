import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/device_models.dart';
import '../../core/models/sensor_models.dart';
import '../../core/services/native_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';

/// Sensor Lab: pembacaan real-time sensor yang tersedia + daftar seluruh sensor.
/// Listener native hanya aktif saat halaman tampil di latar depan dan dilepas saat ditutup.
class SensorsPage extends StatefulWidget {
  const SensorsPage({super.key});

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> with WidgetsBindingObserver {
  List<SensorItem>? _all;
  List<SensorSpec> _live = const [];
  final Map<int, SensorReading> _latest = {};
  StreamSubscription<SensorReading>? _sub;
  Timer? _ui;
  Timer? _noData;
  bool _dirty = false;
  bool _waiting = true;
  bool _streamError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final list = await NativeBridge.instance.sensors();
    if (!mounted) return;
    final present = {for (final s in list) if (s.typeInt != null) s.typeInt!};
    setState(() {
      _all = list;
      _live = [for (final spec in SensorSpec.live) if (present.contains(spec.type)) spec];
    });
    _subscribe();
  }

  void _subscribe() {
    if (_sub != null || _live.isEmpty) return;
    _streamError = false;
    _waiting = true;
    _sub = NativeBridge.instance.sensorStream([for (final s in _live) s.type]).listen(
      (r) {
        _latest[r.type] = r;
        _dirty = true;
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() => _streamError = true);
      },
    );
    // Satu timer UI ringan (4x/detik) agar setState tidak dipanggil per event sensor.
    _ui = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_dirty && mounted) {
        _dirty = false;
        setState(() {});
      }
    });
    _noData = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _waiting = false);
    });
  }

  void _unsubscribe() {
    _sub?.cancel();
    _sub = null;
    _ui?.cancel();
    _ui = null;
    _noData?.cancel();
    _noData = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _subscribe();
    } else {
      _unsubscribe();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribe();
    super.dispose();
  }

  /// "android.sensor.accelerometer" -> "accelerometer"
  String _shortType(String t) => t.startsWith('android.sensor.') ? t.substring('android.sensor.'.length) : t;

  @override
  Widget build(BuildContext context) {
    final all = _all;
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Lab')),
      body: SafeArea(
        top: false,
        child: all == null
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (all.isEmpty)
                    const LimitationNotice('Tidak ada sensor yang dilaporkan oleh sistem.')
                  else ...[
                    Row(
                      children: [
                        Text('Pembacaan langsung', style: TextStyle(fontWeight: FontWeight.w600, color: context.fg)),
                        const Spacer(),
                        const DataBadge(DataKind.realtime),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_streamError)
                      const LimitationNotice('Pembacaan sensor gagal dimulai. Daftar sensor di bawah tetap tersedia.'),
                    if (_live.isEmpty)
                      const LimitationNotice('Perangkat ini tidak memiliki sensor yang dapat dibaca langsung tanpa izin khusus.'),
                    for (final spec in _live) _SensorCard(spec: spec, reading: _latest[spec.type], waiting: _waiting),
                    const LimitationNotice(
                      'Sensor cahaya dan jarak hanya mengirim data saat nilainya berubah; tutup/buka sensor atau ubah '
                      'pencahayaan untuk melihat nilai. Sensor langkah dan detak jantung tidak ditampilkan karena memerlukan izin.',
                    ),
                    SectionTitle('Semua sensor (${all.length})'),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Column(
                        children: [
                          for (var i = 0; i < all.length; i++) ...[
                            if (i > 0) const Divider(),
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.sensors_rounded, size: 22),
                              title: Text(all[i].name),
                              subtitle: Text(
                                '${_shortType(all[i].type)} · ${all[i].vendor}'
                                '${all[i].power == null ? '' : ' · ${all[i].power!.toStringAsFixed(2)} mA'}',
                                style: TextStyle(color: context.muted, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.spec, required this.reading, required this.waiting});

  final SensorSpec spec;
  final SensorReading? reading;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(spec.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
                if (r != null) const Icon(Icons.fiber_manual_record_rounded, size: 10, color: AppColors.green),
              ],
            ),
            const SizedBox(height: 6),
            if (r == null)
              Text(
                waiting ? 'Menunggu data…' : 'Tidak ada data dari sensor ini',
                style: TextStyle(fontSize: 12.5, color: context.muted),
              )
            else
              for (var i = 0; i < spec.axes.length && i < r.values.length; i++)
                InfoRow(spec.axes[i], '${r.values[i].toStringAsFixed(2)}${spec.unit.isEmpty ? '' : ' ${spec.unit}'}'),
          ],
        ),
      ),
    );
  }
}
