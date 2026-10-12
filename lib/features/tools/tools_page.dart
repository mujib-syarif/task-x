import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/native_bridge.dart';
import '../../core/services/report_service.dart';
import '../../core/services/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../performance/performance_page.dart';
import '../storage/storage_page.dart';
import '../system_info/system_info_page.dart';
import 'sensors_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<String> _buildReport() async {
    final bridge = NativeBridge.instance;
    final device = await bridge.deviceInfo();
    final sensors = await bridge.sensors();
    return ReportService.toText(ReportService.sections(device, Services.metrics.snapshot.value, sensors));
  }

  Future<void> _copySummary(BuildContext context) async {
    final text = await _buildReport();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showMessage(context, 'Ringkasan sistem disalin');
  }

  Future<void> _exportReport(BuildContext context) async {
    final text = await _buildReport();
    final t = DateTime.now();
    final name = 'taskx_laporan_${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}.txt';
    try {
      final uri = await NativeBridge.instance.saveTextFile(name, text);
      if (!context.mounted) return;
      showMessage(context, uri == null ? 'Ekspor dibatalkan' : 'Laporan disimpan: $name');
    } catch (_) {
      if (!context.mounted) return;
      showMessage(context, 'Gagal menyimpan laporan');
    }
  }

  Future<void> _cleanOwnFiles(BuildContext context) async {
    final own = await NativeBridge.instance.ownProcess();
    if (!context.mounted) return;
    final cache = own?.cacheBytes ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bersihkan cache Task X?'),
        content: Text(
          'Hanya cache milik Task X sendiri (${formatBytes(cache)}) yang dihapus. '
          'Pengaturan dan file aplikasi lain tidak tersentuh.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bersihkan')),
        ],
      ),
    );
    if (ok != true) return;
    final freed = await NativeBridge.instance.clearOwnCache();
    if (!context.mounted) return;
    showMessage(context, 'Cache dibersihkan: ${formatBytes(freed)}');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const PageHeader('Alat', subtitle: 'Utilitas yang bekerja nyata'),
          const SectionTitle('Pemeriksaan'),
          _ToolTile(
            icon: Icons.fact_check_rounded,
            title: 'System Inspector',
            subtitle: 'Detail perangkat, Android, CPU, memori, sensor',
            onTap: () => _push(context, const SystemInfoPage()),
          ),
          _ToolTile(
            icon: Icons.speed_rounded,
            title: 'Performance Monitor',
            subtitle: 'CPU, RAM, penyimpanan, baterai, jaringan',
            onTap: () => _push(context, const PerformancePage()),
          ),
          _ToolTile(
            icon: Icons.pie_chart_rounded,
            title: 'Storage Analyzer',
            subtitle: 'Kapasitas, kategori file, berkas terbesar',
            onTap: () => _push(context, const StoragePage()),
          ),
          _ToolTile(
            icon: Icons.sensors_rounded,
            title: 'Daftar sensor',
            subtitle: 'Sensor yang tersedia di perangkat ini',
            onTap: () => _push(context, const SensorsPage()),
          ),
          _ToolTile(
            icon: Icons.battery_charging_full_rounded,
            title: 'Informasi baterai',
            subtitle: 'Level, status, suhu, tegangan',
            onTap: () => _push(context, const PerformancePage(initialTab: PerfTab.battery)),
          ),
          _ToolTile(
            icon: Icons.network_check_rounded,
            title: 'Informasi jaringan',
            subtitle: 'Jenis koneksi dan lalu lintas sistem',
            onTap: () => _push(context, const PerformancePage(initialTab: PerfTab.network)),
          ),
          const SectionTitle('Laporan & pemeliharaan'),
          _ToolTile(
            icon: Icons.copy_all_rounded,
            title: 'Salin ringkasan sistem',
            subtitle: 'Salin laporan teks ke clipboard',
            onTap: () => _copySummary(context),
          ),
          _ToolTile(
            icon: Icons.ios_share_rounded,
            title: 'Ekspor laporan ke file',
            subtitle: 'Simpan .txt ke lokasi pilihan Anda',
            onTap: () => _exportReport(context),
          ),
          _ToolTile(
            icon: Icons.cleaning_services_rounded,
            title: 'Bersihkan cache Task X',
            subtitle: 'Hanya file milik Task X sendiri',
            onTap: () => _cleanOwnFiles(context),
          ),
          _ToolTile(
            icon: Icons.info_outline_rounded,
            title: 'Info aplikasi Task X',
            subtitle: 'Buka halaman App Info Android',
            onTap: () async {
              final ok = await NativeBridge.instance.openOwnAppInfo();
              if (!context.mounted) return;
              if (!ok) showMessage(context, 'Tidak dapat membuka info aplikasi');
            },
          ),
          const SizedBox(height: 12),
          const LimitationNotice(
            'Task X sengaja tidak menyediakan "RAM Booster" atau task killer universal: Android modern tidak '
            'mengizinkan aplikasi biasa menutup proses aplikasi lain, sehingga fitur seperti itu hanya akan palsu.',
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.fg.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12.5, color: context.muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22, color: context.muted),
          ],
        ),
      ),
    );
  }
}
