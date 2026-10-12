import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/app_models.dart';
import '../../core/services/native_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_icon_view.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';

class AppDetailPage extends StatelessWidget {
  const AppDetailPage({super.key, required this.app});

  final AppInfo app;

  Future<void> _uninstall(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus aplikasi?'),
        content: Text(
          '${app.label} akan dihapus melalui layar konfirmasi resmi Android. '
          'Anda masih dapat membatalkannya di sana.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lanjutkan')),
        ],
      ),
    );
    if (ok != true) return;
    final started = await NativeBridge.instance.uninstallApp(app.packageName);
    if (!context.mounted) return;
    if (!started) showMessage(context, 'Tidak dapat membuka layar uninstall');
  }

  @override
  Widget build(BuildContext context) {
    final canUninstall = !app.isSystem;
    return Scaffold(
      appBar: AppBar(title: Text(app.label, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(child: AppIconView(packageName: app.packageName, size: 72)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                app.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            Center(
              child: Text(app.packageName, style: TextStyle(fontSize: 12.5, color: context.muted)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: app.canLaunch
                        ? () async {
                            final ok = await NativeBridge.instance.launchApp(app.packageName);
                            if (!context.mounted) return;
                            if (!ok) showMessage(context, 'Aplikasi tidak dapat dibuka');
                          }
                        : null,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Buka'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final ok = await NativeBridge.instance.openAppInfo(app.packageName);
                      if (!context.mounted) return;
                      if (!ok) showMessage(context, 'Tidak dapat membuka info aplikasi');
                    },
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('Info aplikasi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canUninstall ? () => _uninstall(context) : null,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Uninstall'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: app.packageName));
                      if (!context.mounted) return;
                      showMessage(context, 'Package name disalin');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Salin package'),
                  ),
                ),
              ],
            ),
            if (!canUninstall)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: const LimitationNotice(
                  'Aplikasi sistem tidak dapat dihapus oleh Task X. Untuk menonaktifkan, gunakan halaman Info aplikasi Android.',
                ),
              ),
            const SectionTitle('Detail'),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  InfoRow('Versi', app.versionName ?? kUnavailable),
                  InfoRow('Kode versi', '${app.versionCode}'),
                  InfoRow('Jenis', app.isSystem ? (app.isUpdatedSystem ? 'Sistem (diperbarui)' : 'Sistem') : 'Pengguna'),
                  InfoRow('Status', app.enabled ? 'Aktif' : 'Dinonaktifkan'),
                  InfoRow('Kategori', app.categoryLabel),
                  InfoRow('Ukuran APK', formatBytes(app.apkSize)),
                  InfoRow('SDK target', '${app.targetSdk}'),
                  InfoRow('SDK minimum', app.minSdk == null ? kUnavailable : '${app.minSdk}'),
                  InfoRow('Pertama dipasang', formatDate(app.firstInstall)),
                  InfoRow('Terakhir diperbarui', formatDate(app.lastUpdate)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const LimitationNotice(
              'Ukuran yang tampil adalah ukuran berkas APK. Total data & cache aplikasi lain tidak dapat dibaca '
              'tanpa izin khusus, dan Task X tidak dapat menghapus cache aplikasi lain.',
            ),
          ],
        ),
      ),
    );
  }
}
