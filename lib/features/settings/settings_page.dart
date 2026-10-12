import 'package:flutter/material.dart';

import '../../core/services/app_settings.dart';
import '../../core/services/services.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import 'about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Services.settings;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const PageHeader('Pengaturan'),
              const SectionTitle('Tampilan'),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tema', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
                          ButtonSegment(value: ThemeMode.light, label: Text('Terang')),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Gelap')),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (s) => settings.setThemeMode(s.first),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Grafik berisi (area)'),
                      subtitle: const Text('Isi gradien di bawah garis grafik'),
                      value: settings.filledCharts,
                      onChanged: settings.setFilledCharts,
                    ),
                  ],
                ),
              ),
              const SectionTitle('Pemantauan'),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Interval pembaruan', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'Interval lebih panjang menghemat baterai. Pembaruan berhenti saat aplikasi di latar belakang.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in AppSettings.intervalOptions)
                          ChoiceChip(
                            label: Text('$s dtk'),
                            selected: settings.intervalSeconds == s,
                            onSelected: (_) => settings.setInterval(s),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Riwayat grafik', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'Jumlah titik data yang disimpan di memori selama aplikasi aktif. Riwayat tidak ditulis ke penyimpanan.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final p in AppSettings.historyOptions)
                          ChoiceChip(
                            label: Text('$p titik'),
                            selected: settings.historyPoints == p,
                            onSelected: (_) => settings.setHistoryPoints(p),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Services.metrics.clearHistory();
                        showMessage(context, 'Riwayat grafik dihapus');
                      },
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                      label: const Text('Hapus riwayat grafik'),
                    ),
                  ],
                ),
              ),
              const SectionTitle('Modul Beranda'),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    for (final id in DashboardModule.all)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(DashboardModule.label(id)),
                        value: settings.modules.contains(id),
                        onChanged: (v) => settings.setModule(id, v),
                      ),
                  ],
                ),
              ),
              const SectionTitle('Tentang'),
              GlassCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutPage())),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 22),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text('Tentang Task X', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 22),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
