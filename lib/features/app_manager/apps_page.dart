import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_icon_view.dart';
import '../../core/widgets/common_widgets.dart';
import 'app_detail_page.dart';

enum AppFilter { all, user, system }

enum AppSort { name, size, installed, updated }

class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  List<AppInfo>? _apps;
  bool _loading = true;
  String _query = '';
  AppFilter _filter = AppFilter.user;
  AppSort _sort = AppSort.name;
  String? _category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() => _loading = true);
    final apps = await AppRepository.instance.load(force: force);
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _loading = false;
    });
  }

  List<AppInfo> _visible() {
    final all = _apps ?? const <AppInfo>[];
    final q = _query.trim().toLowerCase();
    final list = all.where((a) {
      if (_filter == AppFilter.user && a.isSystem && !a.isUpdatedSystem) return false;
      if (_filter == AppFilter.system && !a.isSystem) return false;
      if (_category != null && a.categoryLabel != _category) return false;
      if (q.isEmpty) return true;
      return a.label.toLowerCase().contains(q) || a.packageName.toLowerCase().contains(q);
    }).toList();
    switch (_sort) {
      case AppSort.name:
        list.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      case AppSort.size:
        list.sort((a, b) => b.apkSize.compareTo(a.apkSize));
      case AppSort.installed:
        list.sort((a, b) => b.firstInstall.compareTo(a.firstInstall));
      case AppSort.updated:
        list.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    }
    return list;
  }

  List<String> _categories() {
    final set = <String>{};
    for (final a in _apps ?? const <AppInfo>[]) {
      set.add(a.categoryLabel);
    }
    final list = set.toList()..sort();
    return list;
  }

  String _sortLabel(AppSort s) => switch (s) {
        AppSort.name => 'Nama',
        AppSort.size => 'Ukuran APK',
        AppSort.installed => 'Terbaru dipasang',
        AppSort.updated => 'Terakhir diperbarui',
      };

  Future<void> _open(AppInfo app) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AppDetailPage(app: app)));
    if (mounted) _load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible();
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          PageHeader(
            'Aplikasi',
            subtitle: _apps == null ? 'Memuat…' : '${visible.length} dari ${_apps!.length} aplikasi',
            trailing: PopupMenuButton<AppSort>(
              tooltip: 'Urutkan',
              icon: const Icon(Icons.sort_rounded),
              initialValue: _sort,
              onSelected: (s) => setState(() => _sort = s),
              itemBuilder: (_) => [
                for (final s in AppSort.values) PopupMenuItem(value: s, child: Text(_sortLabel(s))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari nama atau package…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                filled: true,
                fillColor: context.fg.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final f in AppFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        AppFilter.all => 'Semua',
                        AppFilter.user => 'Pengguna',
                        AppFilter.system => 'Sistem',
                      }),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
                for (final c in _categories())
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (sel) => setState(() => _category = sel ? c : null),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _apps == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : RefreshIndicator(
                    onRefresh: () => _load(force: true),
                    child: visible.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(child: Text('Tidak ada aplikasi yang cocok')),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: visible.length,
                            itemExtent: 64,
                            itemBuilder: (context, i) => _AppTile(app: visible[i], onTap: () => _open(visible[i])),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app, required this.onTap});

  final AppInfo app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: AppIconView(packageName: app.packageName, size: 40),
      title: Text(app.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${app.packageName}\n${app.versionName ?? '—'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(formatBytes(app.apkSize), style: TextStyle(fontSize: 12, color: context.muted)),
    );
  }
}
