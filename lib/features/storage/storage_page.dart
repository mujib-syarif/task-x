import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/models/storage_models.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/services/metrics_service.dart';
import '../../core/services/native_bridge.dart';
import '../../core/services/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_icon_view.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/ring_gauge.dart';

/// Storage Analyzer. Pemindaian folder memakai Storage Access Framework:
/// pengguna memilih folder sendiri; Task X tidak meminta akses seluruh file dan tidak menghapus apa pun.
class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  String? _uri;
  ScanResult? _result;
  bool _scanning = false;
  bool _failed = false;
  bool _sortByName = false;
  List<AppInfo> _topApps = const [];

  @override
  void initState() {
    super.initState();
    _uri = Services.settings.lastScanUri;
    Services.metrics.refresh();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await AppRepository.instance.load();
    final sorted = [...apps]..sort((a, b) => b.apkSize.compareTo(a.apkSize));
    if (!mounted) return;
    setState(() => _topApps = sorted.take(10).toList());
  }

  Future<void> _pick() async {
    final uri = await NativeBridge.instance.pickDirectory();
    if (uri == null || !mounted) return;
    Services.settings.setLastScanUri(uri);
    setState(() => _uri = uri);
    await _scan();
  }

  Future<void> _scan() async {
    final uri = _uri;
    if (uri == null) return;
    setState(() {
      _scanning = true;
      _failed = false;
    });
    final r = await NativeBridge.instance.scanDirectory(uri);
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _result = r;
      _failed = r == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final files = <LargeFile>[...?result?.files];
    if (_sortByName) {
      files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      files.sort((a, b) => b.size.compareTo(a.size));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Storage Analyzer')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ValueListenableBuilder<MetricsSnapshot?>(
              valueListenable: Services.metrics.snapshot,
              builder: (context, snap, _) {
                final s = snap?.storage;
                final f = s?.usedFraction;
                return GlassCard(
                  child: Row(
                    children: [
                      RingGauge(
                        value: f,
                        color: f == null ? AppColors.blue : AppColors.usage(f),
                        size: 84,
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
                );
              },
            ),
            const SectionTitle('Analisis folder'),
            const LimitationNotice(
              'Pilih folder yang ingin dianalisis. Android memberi akses hanya ke folder itu (Storage Access Framework); '
              'Task X tidak meminta akses ke seluruh penyimpanan dan tidak menghapus file apa pun.',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _scanning ? null : _pick,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('Pilih folder'),
                  ),
                ),
                if (_uri != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _scanning ? null : _scan,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Pindai ulang'),
                    ),
                  ),
                ],
              ],
            ),
            if (_scanning)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(height: 10),
                    Text('Memindai folder…'),
                  ],
                ),
              ),
            if (_failed)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LimitationNotice('Folder tidak dapat dipindai. Coba pilih folder lain.'),
              ),
            if (result != null && !_scanning) ...[
              SectionTitle('Kategori · ${result.fileCount} berkas · ${formatBytes(result.totalBytes)}'),
              if (result.truncated)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LimitationNotice('Folder sangat besar: pemindaian dihentikan pada batas 200.000 berkas.'),
                ),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    for (final c in result.categories.where((c) => c.count > 0))
                      _CategoryBar(usage: c, total: result.totalBytes),
                    if (result.categories.every((c) => c.count == 0))
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Folder kosong'),
                      ),
                  ],
                ),
              ),
              SectionTitle(
                'Berkas terbesar',
                trailing: TextButton(
                  onPressed: () => setState(() => _sortByName = !_sortByName),
                  child: Text(_sortByName ? 'Urut: nama' : 'Urut: ukuran'),
                ),
              ),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final f in files)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.insert_drive_file_outlined, size: 22),
                        title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(f.mime, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(formatBytes(f.size), style: const TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () async {
                          final ok = await NativeBridge.instance.openDocument(f.uri, f.mime);
                          if (!context.mounted) return;
                          if (!ok) showMessage(context, 'Tidak ada aplikasi untuk membuka berkas ini');
                        },
                      ),
                  ],
                ),
              ),
            ],
            const SectionTitle('Aplikasi terbesar (ukuran APK)'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final a in _topApps)
                    ListTile(
                      dense: true,
                      leading: AppIconView(packageName: a.packageName, size: 34),
                      title: Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(formatBytes(a.apkSize), style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () => NativeBridge.instance.openAppInfo(a.packageName),
                    ),
                  if (_topApps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(kUnavailable),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const LimitationNotice(
              'Ukuran aplikasi di sini adalah ukuran berkas APK. Total data dan cache aplikasi lain tidak dapat '
              'dibaca tanpa izin khusus. Ketuk aplikasi untuk membuka halaman Info aplikasi Android.',
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.usage, required this.total});

  final CategoryUsage usage;
  final int total;

  @override
  Widget build(BuildContext context) {
    final f = total <= 0 ? 0.0 : (usage.bytes / total).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(usage.name, style: const TextStyle(fontSize: 13.5))),
              Text(
                '${formatBytes(usage.bytes)} · ${usage.count}',
                style: TextStyle(fontSize: 12.5, color: context.muted),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: f,
              minHeight: 6,
              backgroundColor: context.fg.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
