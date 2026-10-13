import 'dart:convert';

import '../models/device_models.dart';
import '../utils/format.dart';
import 'metrics_service.dart';

class ReportRow {
  const ReportRow(this.label, this.value);

  final String label;
  final String value;
}

class ReportSection {
  const ReportSection(this.title, this.rows);

  final String title;
  final List<ReportRow> rows;
}

/// Menyusun laporan sistem dari data nyata. Nilai yang tidak ada ditulis "Tidak tersedia".
class ReportService {
  ReportService._();

  static String _v(Object? v) => v == null ? kUnavailable : v.toString();

  static List<ReportSection> sections(
    DeviceInfo? d,
    MetricsSnapshot? s,
    List<SensorItem> sensors,
  ) {
    final mem = s?.memory;
    final sto = s?.storage;
    final bat = s?.battery;
    final net = s?.network;
    final cpu = s?.cpu;

    return [
      ReportSection('Perangkat', [
        ReportRow('Model', _v(d?.model)),
        ReportRow('Produsen', _v(d?.manufacturer)),
        ReportRow('Merek', _v(d?.brand)),
        ReportRow('Kode perangkat', _v(d?.device)),
        ReportRow('Papan', _v(d?.board)),
        ReportRow('Layar', d == null ? kUnavailable : '${d.screenWidthPx} × ${d.screenHeightPx} px'),
        ReportRow('Kepadatan', d == null ? kUnavailable : '${d.densityDpi} dpi (×${d.density.toStringAsFixed(2)})'),
        ReportRow('Uptime', s?.uptimeMs == null ? kUnavailable : formatDuration(Duration(milliseconds: s!.uptimeMs!))),
      ]),
      ReportSection('Android', [
        ReportRow('Versi Android', _v(d?.androidVersion)),
        ReportRow('SDK (API level)', d == null ? kUnavailable : d.sdkInt.toString()),
        ReportRow('Patch keamanan', _v(d?.securityPatch)),
      ]),
      ReportSection('CPU', [
        ReportRow('Hardware', _v(d?.hardware)),
        ReportRow('SoC', _v(d?.soc)),
        ReportRow('Jumlah core', d == null ? kUnavailable : d.cpuCores.toString()),
        ReportRow('ABI', d == null || d.abis.isEmpty ? kUnavailable : d.abis.join(', ')),
        ReportRow('Penggunaan total', s?.cpuUsage == null ? kUnavailable : formatPercent(s!.cpuUsage, decimals: 1)),
        ReportRow(
          'Frekuensi saat ini',
          cpu == null || !cpu.hasFrequencies
              ? kUnavailable
              : [for (var i = 0; i < cpu.curKhz.length; i++) formatFrequency(cpu.curKhz[i])].join(' / '),
        ),
      ]),
      ReportSection('Memori', [
        ReportRow('Total', mem == null ? kUnavailable : formatBytes(mem.totalBytes)),
        ReportRow('Digunakan', mem == null ? kUnavailable : formatBytes(mem.usedBytes)),
        ReportRow('Tersedia', mem == null ? kUnavailable : formatBytes(mem.availBytes)),
        ReportRow('Status memori rendah', mem == null ? kUnavailable : (mem.lowMemory ? 'Ya' : 'Tidak')),
      ]),
      ReportSection('Penyimpanan internal', [
        ReportRow('Total', sto == null ? kUnavailable : formatBytes(sto.totalBytes)),
        ReportRow('Terpakai', sto == null ? kUnavailable : formatBytes(sto.usedBytes)),
        ReportRow('Tersedia', sto == null ? kUnavailable : formatBytes(sto.availBytes)),
      ]),
      ReportSection('Baterai', [
        ReportRow('Level', bat?.percent == null ? kUnavailable : '${bat!.percent}%'),
        ReportRow('Status', _v(bat?.statusLabel)),
        ReportRow('Sumber daya', _v(bat?.pluggedLabel)),
        ReportRow('Suhu baterai (bukan suhu CPU)', bat?.temperatureC == null ? kUnavailable : '${bat!.temperatureC!.toStringAsFixed(1)} °C'),
        ReportRow('Tegangan', bat?.voltageMv == null ? kUnavailable : '${bat!.voltageMv} mV'),
        ReportRow('Kondisi', _v(bat?.healthLabel)),
        ReportRow('Teknologi', _v(bat?.technology)),
      ]),
      ReportSection('Jaringan', [
        ReportRow('Koneksi', _v(net?.typeLabel)),
        ReportRow('VPN aktif', net == null ? kUnavailable : (net.vpn ? 'Ya' : 'Tidak')),
        ReportRow('Internet tervalidasi', net == null ? kUnavailable : (net.validated ? 'Ya' : 'Tidak')),
        ReportRow('Total diterima (sejak boot)', net?.rxBytes == null ? kUnavailable : formatBytes(net!.rxBytes)),
        ReportRow('Total dikirim (sejak boot)', net?.txBytes == null ? kUnavailable : formatBytes(net!.txBytes)),
        ReportRow(
          'Diterima (sesi Task X)',
          s?.sessionRxBytes == null ? kUnavailable : formatBytes(s!.sessionRxBytes),
        ),
        ReportRow(
          'Dikirim (sesi Task X)',
          s?.sessionTxBytes == null ? kUnavailable : formatBytes(s!.sessionTxBytes),
        ),
        const ReportRow('Cakupan lalu lintas', 'Seluruh sistem, bukan per aplikasi'),
      ]),
      ReportSection('Sensor (${sensors.length})', [
        for (final sensor in sensors) ReportRow(sensor.name, sensor.type),
      ]),
      ReportSection('Task X', [
        ReportRow('Versi', d?.appVersion == null ? kUnavailable : '${d!.appVersion} (build ${d.appBuild})'),
        const ReportRow('Pembuat', 'mujib_syarif'),
      ]),
    ];
  }

  static String toText(List<ReportSection> sections, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final b = StringBuffer()
      ..writeln('Task X by mujib_syarif — Laporan Sistem')
      ..writeln('Dibuat: ${t.year}-${two(t.month)}-${two(t.day)} ${formatClock(t)}')
      ..writeln();
    for (final s in sections) {
      b.writeln('== ${s.title} ==');
      for (final r in s.rows) {
        b.writeln('${r.label}: ${r.value}');
      }
      b.writeln();
    }
    return b.toString();
  }

  /// Laporan terstruktur untuk JSON. Nilai yang tidak terbaca ditulis null (bukan angka karangan).
  /// Tidak memuat identitas pribadi: tanpa daftar aplikasi, SSID, alamat IP, atau ID perangkat.
  static Map<String, Object?> toJsonMap(
    DeviceInfo? d,
    MetricsSnapshot? s,
    List<SensorItem> sensors, {
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final mem = s?.memory;
    final sto = s?.storage;
    final bat = s?.battery;
    final net = s?.network;
    final cpu = s?.cpu;
    return {
      'generator': 'Task X by mujib_syarif',
      'schemaVersion': 1,
      'generatedAt': t.toIso8601String(),
      'app': {'version': d?.appVersion, 'build': d?.appBuild},
      'device': {
        'model': d?.model,
        'manufacturer': d?.manufacturer,
        'brand': d?.brand,
        'device': d?.device,
        'hardware': d?.hardware,
        'board': d?.board,
        'soc': d?.soc,
        'cpuCores': d?.cpuCores,
        'abis': d?.abis,
        'screen': d == null
            ? null
            : {'widthPx': d.screenWidthPx, 'heightPx': d.screenHeightPx, 'densityDpi': d.densityDpi},
        'uptimeMs': s?.uptimeMs,
      },
      'android': {'version': d?.androidVersion, 'sdk': d?.sdkInt, 'securityPatch': d?.securityPatch},
      'cpu': {
        'usageFraction': s?.cpuUsage,
        'usageNote': cpu?.stat == null ? 'Dibatasi Android (/proc/stat tidak terbaca)' : null,
        'currentKhz': cpu?.curKhz,
        'maxKhz': cpu?.maxKhz,
      },
      'memory': mem == null
          ? null
          : {
              'totalBytes': mem.totalBytes,
              'usedBytes': mem.usedBytes,
              'availableBytes': mem.availBytes,
              'lowMemory': mem.lowMemory,
            },
      'storage': sto == null
          ? null
          : {'totalBytes': sto.totalBytes, 'usedBytes': sto.usedBytes, 'availableBytes': sto.availBytes},
      'battery': bat == null
          ? null
          : {
              'percent': bat.percent,
              'status': bat.statusLabel,
              'plugged': bat.pluggedLabel,
              'temperatureC': bat.temperatureC,
              'temperatureNote': 'Suhu baterai, bukan suhu CPU',
              'voltageMv': bat.voltageMv,
              'technology': bat.technology,
            },
      'network': net == null
          ? null
          : {
              'type': net.type,
              'vpn': net.vpn,
              'internetValidated': net.validated,
              'metered': net.metered,
              'totalRxBytesSinceBoot': net.rxBytes,
              'totalTxBytesSinceBoot': net.txBytes,
              'sessionRxBytes': s?.sessionRxBytes,
              'sessionTxBytes': s?.sessionTxBytes,
              'trafficScope': 'Seluruh sistem (semua aplikasi), bukan per aplikasi',
            },
      'sensors': [
        for (final x in sensors) {'name': x.name, 'vendor': x.vendor, 'type': x.type},
      ],
    };
  }

  static String toJson(DeviceInfo? d, MetricsSnapshot? s, List<SensorItem> sensors, {DateTime? now}) =>
      const JsonEncoder.withIndent('  ').convert(toJsonMap(d, s, sensors, now: now));

  /// Nama berkas laporan, mis. taskx_laporan_20261013_1644.json
  static String fileName(String ext, {DateTime? now}) {
    final t = now ?? DateTime.now();
    return 'taskx_laporan_${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}.$ext';
  }
}
