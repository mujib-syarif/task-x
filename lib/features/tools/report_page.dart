import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/device_models.dart';
import '../../core/services/metrics_service.dart';
import '../../core/services/native_bridge.dart';
import '../../core/services/report_service.dart';
import '../../core/services/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';

enum ReportFormat { txt, json }

/// System Report: pratinjau, salin, bagikan, dan simpan laporan sebagai TXT atau JSON.
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  ReportFormat _format = ReportFormat.txt;
  DeviceInfo? _device;
  MetricsSnapshot? _snap;
  List<SensorItem> _sensors = const [];
  DateTime _generated = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bridge = NativeBridge.instance;
    await Services.metrics.refresh();
    final device = await bridge.deviceInfo();
    final sensors = await bridge.sensors();
    if (!mounted) return;
    setState(() {
      _device = device;
      _sensors = sensors;
      _snap = Services.metrics.snapshot.value;
      _generated = DateTime.now();
      _loading = false;
    });
  }

  String get _text => _format == ReportFormat.json
      ? ReportService.toJson(_device, _snap, _sensors, now: _generated)
      : ReportService.toText(ReportService.sections(_device, _snap, _sensors), now: _generated);

  String get _ext => _format == ReportFormat.json ? 'json' : 'txt';
  String get _mime => _format == ReportFormat.json ? 'application/json' : 'text/plain';

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text));
    if (!mounted) return;
    showMessage(context, 'Laporan ${_ext.toUpperCase()} disalin');
  }

  Future<void> _share() async {
    final ok = await NativeBridge.instance.shareText('Laporan sistem Task X', _text);
    if (!mounted) return;
    if (!ok) showMessage(context, 'Tidak dapat membuka menu bagikan');
  }

  Future<void> _save() async {
    final name = ReportService.fileName(_ext, now: _generated);
    try {
      final uri = await NativeBridge.instance.saveTextFile(name, _text, mime: _mime);
      if (!mounted) return;
      showMessage(context, uri == null ? 'Penyimpanan dibatalkan' : 'Laporan disimpan: $name');
    } catch (_) {
      if (!mounted) return;
      showMessage(context, 'Gagal menyimpan laporan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan sistem'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang data',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ReportFormat>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ReportFormat.txt, label: Text('TXT')),
                  ButtonSegment(value: ReportFormat.json, label: Text('JSON')),
                ],
                selected: {_format},
                onSelectionChanged: (s) => setState(() => _format = s.first),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _loading ? null : _copy,
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: const Text('Salin'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _loading ? null : _share,
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                    label: const Text('Bagikan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: const Icon(Icons.save_alt_rounded, size: 20),
                    label: Text('Simpan .$_ext'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const LimitationNotice(
              'Laporan hanya memuat spesifikasi dan status perangkat. Tidak ada daftar aplikasi, nama Wi-Fi, '
              'alamat IP, atau ID perangkat. Laporan tidak dikirim ke mana pun kecuali Anda memilih Bagikan.',
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              GlassCard(
                child: SelectableText(
                  _text,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.45, color: context.fg),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
