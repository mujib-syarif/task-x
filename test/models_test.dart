import 'package:flutter_test/flutter_test.dart';
import 'package:task_x/core/models/app_models.dart';
import 'package:task_x/core/models/device_models.dart';
import 'package:task_x/core/services/report_service.dart';
import 'package:task_x/core/utils/format.dart';

void main() {
  test('BatteryInfo memetakan status & suhu', () {
    final b = BatteryInfo.fromMap({'percent': 80, 'status': 2, 'plugged': 3, 'health': 2, 'temperatureC': 31.5});
    expect(b.isCharging, isTrue);
    expect(b.statusLabel, 'Mengisi daya');
    expect(b.pluggedLabel, 'Adaptor AC + USB');
    expect(b.temperatureC, 31.5);
  });

  test('BatteryInfo tanpa data suhu tetap aman', () {
    final b = BatteryInfo.fromMap({'status': 1});
    expect(b.percent, isNull);
    expect(b.temperatureC, isNull);
  });

  test('MemoryInfo menghitung fraksi terpakai', () {
    final m = MemoryInfo.fromMap({'total': 4000, 'avail': 1000, 'threshold': 100, 'low': false});
    expect(m.usedBytes, 3000);
    expect(m.usedFraction, closeTo(0.75, 1e-9));
  });

  test('CpuInfo menolak /proc/stat yang tidak ada', () {
    final c = CpuInfo.fromMap({'cores': 8, 'curKhz': [null, 1800000], 'maxKhz': [2000000, 2000000]});
    expect(c.stat, isNull);
    expect(c.hasFrequencies, isTrue);
  });

  test('AppInfo.fromMap', () {
    final a = AppInfo.fromMap({
      'package': 'com.example.app',
      'label': 'Contoh',
      'versionCode': 3,
      'isSystem': false,
      'apkSize': 2048,
      'category': 4,
      'canLaunch': true,
    });
    expect(a.packageName, 'com.example.app');
    expect(a.categoryLabel, 'Sosial');
    expect(a.canLaunch, isTrue);
  });

  test('Laporan menulis "N/A" saat data kosong dan memuat branding', () {
    final text = ReportService.toText(ReportService.sections(null, null, const []), now: DateTime(2026, 1, 2, 3, 4, 5));
    expect(text, contains(kUnavailable));
    expect(text, contains('Task X by mujib_syarif'));
    expect(text, contains('2026-01-02 03:04:05'));
  });
}
