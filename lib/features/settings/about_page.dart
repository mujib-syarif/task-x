import 'package:flutter/material.dart';

import '../../core/models/device_models.dart';
import '../../core/services/native_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<DeviceInfo?> _future = NativeBridge.instance.deviceInfo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Center(child: LogoPlate(size: 132, radius: 34)),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Task X',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: context.fg),
              ),
            ),
            Center(
              child: Text(
                'by mujib_syarif',
                style: TextStyle(fontSize: 14, letterSpacing: 1.4, color: context.muted),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: FutureBuilder<DeviceInfo?>(
                future: _future,
                builder: (context, s) {
                  final d = s.data;
                  final text = d?.appVersion == null ? 'Versi tidak tersedia' : 'Versi ${d!.appVersion} (build ${d.appBuild})';
                  return Text(text, style: TextStyle(fontSize: 12.5, color: context.muted));
                },
              ),
            ),
            const SizedBox(height: 24),
            const GlassCard(
              child: Text(
                'Task X adalah pemantau sistem dan pengelola aplikasi untuk Android: gabungan Task Manager dan '
                'System Monitor. Semua data berasal dari API resmi Android; bila suatu data dibatasi sistem, '
                'Task X menampilkannya sebagai "Tidak tersedia" — bukan angka karangan.',
                style: TextStyle(fontSize: 13.5, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            const GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privasi', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text(
                    'Tanpa akun, tanpa server, tanpa izin internet. Data perangkat tidak pernah meninggalkan HP Anda. '
                    'Tanpa root dan tanpa hidden API.',
                    style: TextStyle(fontSize: 13.5, height: 1.5),
                  ),
                ],
              ),
            ),
            const SectionTitle('Lencana data'),
            const GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [DataBadge(DataKind.periodic), SizedBox(width: 10), Expanded(child: Text('Diperbarui berkala sesuai interval'))]),
                  SizedBox(height: 8),
                  Row(children: [DataBadge(DataKind.snapshot), SizedBox(width: 10), Expanded(child: Text('Dibaca sekali / saat dibuka'))]),
                  SizedBox(height: 8),
                  Row(children: [DataBadge(DataKind.unavailable), SizedBox(width: 10), Expanded(child: Text('Dibatasi oleh Android'))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
