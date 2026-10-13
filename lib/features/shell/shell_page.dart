import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/metrics_scope.dart';
import '../app_manager/apps_page.dart';
import '../dashboard/dashboard_page.dart';
import '../processes/processes_page.dart';
import '../settings/settings_page.dart';
import '../tools/tools_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;
  final Set<int> _visited = {0};

  Widget _page(int i) => switch (i) {
        0 => MetricsScope(active: _index == 0, child: const DashboardPage()),
        1 => const ProcessesPage(),
        2 => const AppsPage(),
        3 => const ToolsPage(),
        _ => const SettingsPage(),
      };

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final overlay = (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < 5; i++)
              _visited.contains(i) ? TickerMode(enabled: i == _index, child: _page(i)) : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: _GlassNavBar(
          index: _index,
          onChanged: (i) => setState(() {
            _index = i;
            _visited.add(i);
          }),
        ),
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    // Satu-satunya elemen dengan blur: ringan dan hanya di bar bawah.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (dark ? Colors.black : Colors.white).withValues(alpha: 0.62),
            border: Border(
              top: BorderSide(
                color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                width: 0.6,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: onChanged,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Beranda'),
              NavigationDestination(icon: Icon(Icons.memory_rounded), label: 'Proses'),
              NavigationDestination(icon: Icon(Icons.apps_rounded), label: 'Aplikasi'),
              NavigationDestination(icon: Icon(Icons.construction_rounded), label: 'Alat'),
              NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Pengaturan'),
            ],
          ),
        ),
      ),
    );
  }
}
