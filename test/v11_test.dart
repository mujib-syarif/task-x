import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_x/core/models/device_models.dart';
import 'package:task_x/core/models/sensor_models.dart';
import 'package:task_x/core/services/app_settings.dart';
import 'package:task_x/core/services/metrics_service.dart';
import 'package:task_x/core/services/report_service.dart';
import 'package:task_x/core/utils/thermal.dart';
import 'package:task_x/core/utils/traffic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Thermal', () {
    test('tingkat berdasarkan ambang', () {
      expect(Thermal.evaluate(null, 40), ThermalLevel.unknown);
      expect(Thermal.evaluate(36.5, 40), ThermalLevel.normal);
      expect(Thermal.evaluate(40.0, 40), ThermalLevel.warm);
      expect(Thermal.evaluate(44.9, 40), ThermalLevel.warm);
      expect(Thermal.evaluate(45.0, 40), ThermalLevel.hot);
    });
    test('ambang bawaan konservatif', () {
      expect(Thermal.defaultWarnC, lessThanOrEqualTo(40));
      expect(Thermal.warnOptions, contains(Thermal.defaultWarnC));
    });
  });

  group('SessionTraffic', () {
    test('menghitung selisih sejak baseline', () {
      final t = SessionTraffic();
      expect(t.rx(100), isNull);
      t.update(1000, 500, DateTime(2026));
      expect(t.rx(1500), 500);
      expect(t.tx(800), 300);
    });
    test('reset penghitung sistem memulai baseline baru', () {
      final t = SessionTraffic()..update(1000, 1000, DateTime(2026));
      t.update(10, 10, DateTime(2027));
      expect(t.rx(60), 50);
      expect(t.started, DateTime(2027));
    });
    test('data tidak tersedia diabaikan', () {
      final t = SessionTraffic()..update(null, 5, DateTime(2026));
      expect(t.rx(5), isNull);
    });
  });

  group('SensorReading', () {
    test('mem-parsing event native', () {
      final r = SensorReading.fromEvent({'type': 1, 'values': [0.1, 9.8, 0], 'accuracy': 3});
      expect(r, isNotNull);
      expect(r!.values.length, 3);
      expect(SensorSpec.byType(r.type)?.label, 'Akselerometer');
    });
    test('event rusak ditolak tanpa crash', () {
      expect(SensorReading.fromEvent('x'), isNull);
      expect(SensorReading.fromEvent({'type': 1}), isNull);
    });
  });

  group('Laporan JSON', () {
    test('valid, memuat timestamp/branding, dan null untuk data tidak ada', () {
      final text = ReportService.toJson(null, null, const [], now: DateTime(2026, 10, 13, 16, 44));
      final m = jsonDecode(text) as Map<String, dynamic>;
      expect(m['generator'], 'Task X by mujib_syarif');
      expect(m['generatedAt'], startsWith('2026-10-13T16:44'));
      expect(m['memory'], isNull);
      expect(m['battery'], isNull);
      expect((m['sensors'] as List), isEmpty);
    });
    test('menyertakan suhu baterai dengan catatan bukan suhu CPU', () {
      final snap = MetricsSnapshot(
        time: DateTime(2026),
        battery: BatteryInfo.fromMap({'percent': 50, 'status': 3, 'temperatureC': 33.0}),
        sessionRxBytes: 10,
      );
      final m = ReportService.toJsonMap(null, snap, const []);
      final bat = m['battery'] as Map<String, Object?>;
      expect(bat['temperatureC'], 33.0);
      expect(bat['temperatureNote'], contains('bukan suhu CPU'));
      expect((m['network'] as Map?), isNull);
    });
    test('nama berkas', () {
      expect(ReportService.fileName('json', now: DateTime(2026, 1, 2, 3, 4)), 'taskx_laporan_20260102_0304.json');
    });
  });

  group('MetricsService lease', () {
    test('timer hanya berjalan saat ada penyewa', () {
      final svc = MetricsService(AppSettings());
      expect(svc.isRunning, isFalse);
      svc.acquire();
      expect(svc.isRunning, isTrue);
      svc.acquire();
      svc.release();
      expect(svc.isRunning, isTrue);
      svc.release();
      expect(svc.isRunning, isFalse);
      expect(svc.leaseCount, 0);
    });
    test('release berlebih tidak membuat hitungan negatif', () {
      final svc = MetricsService(AppSettings())..release();
      expect(svc.leaseCount, 0);
    });
  });
}
