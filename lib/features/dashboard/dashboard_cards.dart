import 'package:flutter/material.dart';

import '../../core/services/metrics_service.dart';
import '../../core/services/native_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/ring_gauge.dart';
import '../performance/performance_page.dart';

void _openPerformance(BuildContext context, PerfTab tab) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PerformancePage(initialTab: tab)));
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.title,
    required this.ring,
    required this.badge,
    required this.lines,
    this.onTap,
  });

  final String title;
  final Widget ring;
  final Widget badge;
  final List<Widget> lines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            ring,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.fg),
                        ),
                      ),
                      badge,
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...lines,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: context.muted))),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: context.fg)),
        ],
      ),
    );
  }
}

Widget _pct(BuildContext context, double? f) => Text(
      f == null ? '—' : '${(f * 100).round()}%',
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.fg),
    );

class RamCard extends StatelessWidget {
  const RamCard({super.key, required this.snap, required this.interval});

  final MetricsSnapshot snap;
  final String interval;

  @override
  Widget build(BuildContext context) {
    final m = snap.memory;
    final f = m?.usedFraction;
    return _CardShell(
      title: 'Memori (RAM)',
      onTap: () => _openPerformance(context, PerfTab.ram),
      ring: RingGauge(
        value: f,
        color: f == null ? AppColors.blue : AppColors.usage(f),
        child: _pct(context, f),
      ),
      badge: m == null ? const DataBadge(DataKind.unavailable) : DataBadge(DataKind.periodic, detail: interval),
      lines: m == null
          ? const [_Line('Status', kUnavailable)]
          : [
              _Line('Digunakan', formatBytes(m.usedBytes)),
              _Line('Tersedia', formatBytes(m.availBytes)),
              _Line('Total dilaporkan sistem', formatBytes(m.totalBytes)),
              if (m.lowMemory) const _Line('Peringatan', 'Memori rendah'),
            ],
    );
  }
}

class CpuCard extends StatelessWidget {
  const CpuCard({super.key, required this.snap, required this.interval});

  final MetricsSnapshot snap;
  final String interval;

  @override
  Widget build(BuildContext context) {
    final cpu = snap.cpu;
    final usage = snap.cpuUsage;
    final supported = cpu?.stat != null;
    final freqs = cpu?.curKhz.whereType<int>().toList() ?? const <int>[];
    final avg = freqs.isEmpty ? null : freqs.reduce((a, b) => a + b) ~/ freqs.length;
    return _CardShell(
      title: 'CPU',
      onTap: () => _openPerformance(context, PerfTab.cpu),
      ring: RingGauge(
        value: usage,
        color: usage == null ? AppColors.blue : AppColors.usage(usage),
        child: _pct(context, usage),
      ),
      badge: supported ? DataBadge(DataKind.periodic, detail: interval) : const DataBadge(DataKind.unavailable),
      lines: [
        _Line('Penggunaan total', supported ? formatPercent(usage) : 'Dibatasi Android'),
        _Line('Jumlah core', cpu == null ? kUnavailable : '${cpu.cores}'),
        _Line('Frekuensi rata-rata', avg == null ? kUnavailable : formatFrequency(avg)),
      ],
    );
  }
}

class StorageCard extends StatelessWidget {
  const StorageCard({super.key, required this.snap});

  final MetricsSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final s = snap.storage;
    final f = s?.usedFraction;
    return _CardShell(
      title: 'Penyimpanan',
      onTap: () => _openPerformance(context, PerfTab.storage),
      ring: RingGauge(
        value: f,
        color: f == null ? AppColors.blue : AppColors.usage(f),
        child: _pct(context, f),
      ),
      badge: s == null ? const DataBadge(DataKind.unavailable) : const DataBadge(DataKind.snapshot),
      lines: s == null
          ? const [_Line('Status', kUnavailable)]
          : [
              _Line('Terpakai', formatBytes(s.usedBytes)),
              _Line('Tersedia', formatBytes(s.availBytes)),
              _Line('Total', formatBytes(s.totalBytes)),
            ],
    );
  }
}

class BatteryCard extends StatelessWidget {
  const BatteryCard({super.key, required this.snap, required this.interval});

  final MetricsSnapshot snap;
  final String interval;

  @override
  Widget build(BuildContext context) {
    final b = snap.battery;
    final p = b?.percent;
    final f = p == null ? null : p / 100;
    return _CardShell(
      title: 'Baterai',
      onTap: () => _openPerformance(context, PerfTab.battery),
      ring: RingGauge(
        value: f,
        color: f == null
            ? AppColors.blue
            : (b!.isCharging ? AppColors.green : (f < 0.2 ? AppColors.red : AppColors.blue)),
        child: _pct(context, f),
      ),
      badge: b == null ? const DataBadge(DataKind.unavailable) : DataBadge(DataKind.periodic, detail: interval),
      lines: b == null
          ? const [_Line('Status', kUnavailable)]
          : [
              _Line('Status', b.statusLabel),
              _Line('Suhu baterai', b.temperatureC == null ? kUnavailable : '${b.temperatureC!.toStringAsFixed(1)} °C'),
              _Line('Tegangan', b.voltageMv == null ? kUnavailable : '${b.voltageMv} mV'),
            ],
    );
  }
}

class NetworkCard extends StatelessWidget {
  const NetworkCard({super.key, required this.snap, required this.interval});

  final MetricsSnapshot snap;
  final String interval;

  @override
  Widget build(BuildContext context) {
    final n = snap.network;
    return _CardShell(
      title: 'Jaringan',
      onTap: () => _openPerformance(context, PerfTab.network),
      ring: RingGauge(
        value: n == null ? null : (n.connected ? 1.0 : 0.0),
        color: n != null && n.connected && n.validated ? AppColors.green : AppColors.orange,
        child: Icon(
          n == null || !n.connected
              ? Icons.signal_wifi_off_rounded
              : (n.type == 'cellular' ? Icons.signal_cellular_alt_rounded : Icons.wifi_rounded),
          size: 24,
        ),
      ),
      badge: n == null ? const DataBadge(DataKind.unavailable) : DataBadge(DataKind.periodic, detail: interval),
      lines: n == null
          ? const [_Line('Status', kUnavailable)]
          : [
              _Line('Koneksi', n.typeLabel),
              _Line('Unduh (sistem)', formatRate(snap.netDownBps)),
              _Line('Unggah (sistem)', formatRate(snap.netUpBps)),
            ],
    );
  }
}

class SystemCard extends StatefulWidget {
  const SystemCard({super.key, required this.snap});

  final MetricsSnapshot snap;

  @override
  State<SystemCard> createState() => _SystemCardState();
}

class _SystemCardState extends State<SystemCard> {
  late final Future<int?> _count = NativeBridge.instance.appCount();

  @override
  Widget build(BuildContext context) {
    final uptime = widget.snap.uptimeMs;
    return _CardShell(
      title: 'Sistem',
      ring: RingGauge(
        value: null,
        color: AppColors.blue,
        child: const Icon(Icons.timer_outlined, size: 24),
      ),
      badge: const DataBadge(DataKind.periodic),
      lines: [
        _Line('Uptime', uptime == null ? kUnavailable : formatDuration(Duration(milliseconds: uptime))),
        FutureBuilder<int?>(
          future: _count,
          builder: (context, s) => _Line('Aplikasi terinstal', s.data == null ? '…' : '${s.data}'),
        ),
      ],
    );
  }
}
