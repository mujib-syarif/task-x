import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/models/device_models.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/services/native_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_icon_view.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../app_manager/app_detail_page.dart';

enum ProcSort { name, lastUsed, foreground, size }

/// Android 11 tidak mengizinkan aplikasi biasa melihat proses aplikasi lain.
/// Halaman ini menampilkan hal yang benar-benar dapat diamati:
///  - proses Task X sendiri (PID & memori nyata),
///  - aplikasi yang digunakan 24 jam terakhir (jika pengguna memberi Akses penggunaan),
///  - fallback: semua aplikasi terinstal.
class ProcessesPage extends StatefulWidget {
  const ProcessesPage({super.key});

  @override
  State<ProcessesPage> createState() => _ProcessesPageState();
}

class _ProcessesPageState extends State<ProcessesPage> with WidgetsBindingObserver {
  List<AppInfo> _apps = const [];
  Map<String, UsageEntry> _usage = const {};
  OwnProcessInfo? _own;
  bool _hasAccess = false;
  bool _loading = true;
  bool _showAll = false;
  bool _includeSystem = false;
  String _query = '';
  ProcSort _sort = ProcSort.lastUsed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pengguna mungkin baru saja memberi/mencabut Akses penggunaan di Pengaturan.
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final bridge = NativeBridge.instance;
    final results = await Future.wait<Object?>([
      AppRepository.instance.load(),
      bridge.hasUsageAccess(),
      bridge.ownProcess(),
    ]);
    final apps = results[0] as List<AppInfo>;
    final access = results[1] as bool;
    final own = results[2] as OwnProcessInfo?;
    final usage = access ? await bridge.recentlyUsed() : const <UsageEntry>[];
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _hasAccess = access;
      _own = own;
      _usage = {for (final u in usage) u.packageName: u};
      _loading = false;
    });
  }

  List<AppInfo> _visible() {
    final q = _query.trim().toLowerCase();
    final list = _apps.where((a) {
      if (!_includeSystem && a.isSystem && !a.isUpdatedSystem) return false;
      if (_hasAccess && !_showAll && !_usage.containsKey(a.packageName)) return false;
      if (q.isEmpty) return true;
      return a.label.toLowerCase().contains(q) || a.packageName.toLowerCase().contains(q);
    }).toList();
    int lastUsed(AppInfo a) => _usage[a.packageName]?.lastUsed ?? 0;
    int fg(AppInfo a) => _usage[a.packageName]?.foregroundMs ?? 0;
    switch (_sort) {
      case ProcSort.name:
        list.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      case ProcSort.lastUsed:
        list.sort((a, b) => lastUsed(b).compareTo(lastUsed(a)));
      case ProcSort.foreground:
        list.sort((a, b) => fg(b).compareTo(fg(a)));
      case ProcSort.size:
        list.sort((a, b) => b.apkSize.compareTo(a.apkSize));
    }
    return list;
  }

  String _sortLabel(ProcSort s) => switch (s) {
        ProcSort.name => 'Nama',
        ProcSort.lastUsed => 'Terakhir dipakai',
        ProcSort.foreground => 'Waktu foreground',
        ProcSort.size => 'Ukuran APK',
      };

  String _subtitle(AppInfo a) {
    final u = _usage[a.packageName];
    if (u == null) return 'Ukuran APK ${formatBytes(a.apkSize)}';
    final mins = (u.foregroundMs / 60000).round();
    return 'Dipakai ${formatAgo(u.lastUsed)} · foreground 24 jam: $mins menit';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _loading ? const <AppInfo>[] : _visible();
    final own = _own;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          PageHeader(
            'Proses',
            subtitle: 'Aplikasi yang dapat diamati',
            trailing: PopupMenuButton<ProcSort>(
              tooltip: 'Urutkan',
              icon: const Icon(Icons.sort_rounded),
              initialValue: _sort,
              onSelected: (s) => setState(() => _sort = s),
              itemBuilder: (_) => [
                for (final s in ProcSort.values) PopupMenuItem(value: s, child: Text(_sortLabel(s))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LimitationNotice(
                  'Android 11 membatasi aplikasi biasa: daftar proses, PID, serta CPU/RAM aplikasi lain tidak dapat '
                  'dibaca. Task X tidak memakai root atau trik tersembunyi. Yang ditampilkan di bawah adalah data nyata '
                  'yang tersedia secara resmi.',
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Proses Task X', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                          own == null
                              ? const DataBadge(DataKind.unavailable)
                              : const DataBadge(DataKind.snapshot),
                        ],
                      ),
                      InfoRow('PID', own == null ? kUnavailable : '${own.pid}'),
                      InfoRow('Memori (PSS)', own == null ? kUnavailable : formatBytes(own.pssKb * 1024)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!_loading && !_hasAccess)
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aktivitas aplikasi (opsional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          'Dengan "Akses penggunaan", Task X dapat menampilkan aplikasi yang dipakai 24 jam terakhir. '
                          'Izin ini hanya membaca statistik penggunaan di perangkat; tidak ada data yang dikirim ke mana pun.',
                          style: TextStyle(fontSize: 12.5, height: 1.4, color: context.muted),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: () => NativeBridge.instance.openUsageSettings(),
                          icon: const Icon(Icons.lock_open_rounded, size: 18),
                          label: const Text('Buka pengaturan Akses penggunaan'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Cari aplikasi…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: context.fg.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Termasuk sistem'),
                      selected: _includeSystem,
                      onSelected: (v) => setState(() => _includeSystem = v),
                    ),
                    if (_hasAccess)
                      FilterChip(
                        label: const Text('Semua terinstal'),
                        selected: _showAll,
                        onSelected: (v) => setState(() => _showAll = v),
                      ),
                  ],
                ),
                SectionTitle(
                  _hasAccess && !_showAll ? 'Dipakai 24 jam terakhir (${visible.length})' : 'Aplikasi terinstal (${visible.length})',
                ),
              ],
            ),
          ),
              ],
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final a = visible[i];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: AppIconView(packageName: a.packageName, size: 38),
                  title: Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_subtitle(a), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => AppDetailPage(app: a)),
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
