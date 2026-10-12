import '../utils/json_utils.dart';

class DeviceInfo {
  const DeviceInfo({
    required this.model,
    required this.manufacturer,
    required this.brand,
    required this.device,
    required this.hardware,
    required this.board,
    required this.androidVersion,
    required this.sdkInt,
    required this.abis,
    required this.cpuCores,
    required this.screenWidthPx,
    required this.screenHeightPx,
    required this.densityDpi,
    required this.density,
    required this.appBuild,
    this.securityPatch,
    this.soc,
    this.appVersion,
  });

  final String model;
  final String manufacturer;
  final String brand;
  final String device;
  final String hardware;
  final String board;
  final String androidVersion;
  final int sdkInt;
  final List<String> abis;
  final int cpuCores;
  final int screenWidthPx;
  final int screenHeightPx;
  final int densityDpi;
  final double density;
  final int appBuild;
  final String? securityPatch;
  final String? soc;
  final String? appVersion;

  factory DeviceInfo.fromMap(Map<String, dynamic> m) {
    final abiList = m['abis'];
    return DeviceInfo(
      model: asString(m['model']) ?? '—',
      manufacturer: asString(m['manufacturer']) ?? '—',
      brand: asString(m['brand']) ?? '—',
      device: asString(m['device']) ?? '—',
      hardware: asString(m['hardware']) ?? '—',
      board: asString(m['board']) ?? '—',
      androidVersion: asString(m['androidVersion']) ?? '—',
      sdkInt: asInt(m['sdkInt']) ?? 0,
      abis: abiList is List ? abiList.map((e) => e.toString()).toList() : const <String>[],
      cpuCores: asInt(m['cpuCores']) ?? 0,
      screenWidthPx: asInt(m['screenWidthPx']) ?? 0,
      screenHeightPx: asInt(m['screenHeightPx']) ?? 0,
      densityDpi: asInt(m['densityDpi']) ?? 0,
      density: asDouble(m['density']) ?? 0,
      appBuild: asInt(m['appBuild']) ?? 0,
      securityPatch: asString(m['securityPatch']),
      soc: asString(m['soc']),
      appVersion: asString(m['appVersion']),
    );
  }
}

class MemoryInfo {
  const MemoryInfo({
    required this.totalBytes,
    required this.availBytes,
    required this.thresholdBytes,
    required this.lowMemory,
  });

  final int totalBytes;
  final int availBytes;
  final int thresholdBytes;
  final bool lowMemory;

  int get usedBytes => totalBytes - availBytes;
  double get usedFraction => totalBytes <= 0 ? 0 : (usedBytes / totalBytes).clamp(0.0, 1.0).toDouble();

  factory MemoryInfo.fromMap(Map<String, dynamic> m) => MemoryInfo(
        totalBytes: asInt(m['total']) ?? 0,
        availBytes: asInt(m['avail']) ?? 0,
        thresholdBytes: asInt(m['threshold']) ?? 0,
        lowMemory: m['low'] == true,
      );
}

class StorageInfo {
  const StorageInfo({required this.totalBytes, required this.availBytes});

  final int totalBytes;
  final int availBytes;

  int get usedBytes => totalBytes - availBytes;
  double get usedFraction => totalBytes <= 0 ? 0 : (usedBytes / totalBytes).clamp(0.0, 1.0).toDouble();

  factory StorageInfo.fromMap(Map<String, dynamic> m) => StorageInfo(
        totalBytes: asInt(m['total']) ?? 0,
        availBytes: asInt(m['avail']) ?? 0,
      );
}

class BatteryInfo {
  const BatteryInfo({
    required this.status,
    required this.plugged,
    required this.health,
    this.percent,
    this.temperatureC,
    this.voltageMv,
    this.technology,
    this.currentNowUa,
  });

  final int? percent;
  final int status;
  final int plugged;
  final int health;
  final double? temperatureC;
  final int? voltageMv;
  final String? technology;
  final int? currentNowUa;

  bool get isCharging => status == 2 || status == 5;

  String get statusLabel => switch (status) {
        2 => 'Mengisi daya',
        3 => 'Tidak mengisi',
        4 => 'Tidak mengisi (terhubung)',
        5 => 'Penuh',
        _ => 'Tidak diketahui',
      };

  String get pluggedLabel {
    final parts = <String>[];
    if (plugged & 1 != 0) parts.add('Adaptor AC');
    if (plugged & 2 != 0) parts.add('USB');
    if (plugged & 4 != 0) parts.add('Nirkabel');
    return parts.isEmpty ? 'Tidak terhubung' : parts.join(' + ');
  }

  String get healthLabel => switch (health) {
        2 => 'Baik',
        3 => 'Terlalu panas',
        4 => 'Rusak',
        5 => 'Tegangan berlebih',
        6 => 'Kegagalan tidak spesifik',
        7 => 'Terlalu dingin',
        _ => 'Tidak diketahui',
      };

  factory BatteryInfo.fromMap(Map<String, dynamic> m) => BatteryInfo(
        percent: asInt(m['percent']),
        status: asInt(m['status']) ?? 1,
        plugged: asInt(m['plugged']) ?? 0,
        health: asInt(m['health']) ?? 1,
        temperatureC: asDouble(m['temperatureC']),
        voltageMv: asInt(m['voltageMv']),
        technology: asString(m['technology']),
        currentNowUa: asInt(m['currentNowUa']),
      );
}

class NetworkInfo {
  const NetworkInfo({
    required this.type,
    required this.vpn,
    required this.validated,
    required this.metered,
    this.downKbps,
    this.upKbps,
    this.rxBytes,
    this.txBytes,
    this.mobileRxBytes,
    this.mobileTxBytes,
  });

  final String type;
  final bool vpn;
  final bool validated;
  final bool metered;
  final int? downKbps;
  final int? upKbps;
  final int? rxBytes;
  final int? txBytes;
  final int? mobileRxBytes;
  final int? mobileTxBytes;

  bool get connected => type != 'none';

  String get typeLabel => switch (type) {
        'wifi' => 'Wi-Fi',
        'cellular' => 'Seluler',
        'ethernet' => 'Ethernet',
        'bluetooth' => 'Bluetooth',
        'vpn' => 'VPN',
        'other' => 'Lainnya',
        _ => 'Tidak terhubung',
      };

  factory NetworkInfo.fromMap(Map<String, dynamic> m) => NetworkInfo(
        type: asString(m['type']) ?? 'none',
        vpn: m['vpn'] == true,
        validated: m['validated'] == true,
        metered: m['metered'] == true,
        downKbps: asInt(m['downKbps']),
        upKbps: asInt(m['upKbps']),
        rxBytes: asInt(m['rxBytes']),
        txBytes: asInt(m['txBytes']),
        mobileRxBytes: asInt(m['mobileRxBytes']),
        mobileTxBytes: asInt(m['mobileTxBytes']),
      );
}

class CpuInfo {
  const CpuInfo({
    required this.cores,
    required this.curKhz,
    required this.maxKhz,
    this.stat,
  });

  final int cores;
  final List<int?> curKhz;
  final List<int?> maxKhz;

  /// Baris `cpu` dari /proc/stat; null jika Android menolak akses.
  final List<int>? stat;

  bool get hasFrequencies => curKhz.any((e) => e != null);

  factory CpuInfo.fromMap(Map<String, dynamic> m) {
    final raw = m['stat'];
    return CpuInfo(
      cores: asInt(m['cores']) ?? 0,
      curKhz: asNullableIntList(m['curKhz']),
      maxKhz: asNullableIntList(m['maxKhz']),
      stat: raw is List ? raw.whereType<num>().map((e) => e.toInt()).toList() : null,
    );
  }
}

class SensorItem {
  const SensorItem({required this.name, required this.vendor, required this.type, this.power});

  final String name;
  final String vendor;
  final String type;
  final double? power;

  factory SensorItem.fromMap(Map<String, dynamic> m) => SensorItem(
        name: asString(m['name']) ?? '—',
        vendor: asString(m['vendor']) ?? '—',
        type: asString(m['type']) ?? '—',
        power: asDouble(m['power']),
      );
}

class OwnProcessInfo {
  const OwnProcessInfo({
    required this.pid,
    required this.pssKb,
    required this.cacheBytes,
    required this.filesBytes,
  });

  final int pid;
  final int pssKb;
  final int cacheBytes;
  final int filesBytes;

  factory OwnProcessInfo.fromMap(Map<String, dynamic> m) => OwnProcessInfo(
        pid: asInt(m['pid']) ?? 0,
        pssKb: asInt(m['pssKb']) ?? 0,
        cacheBytes: asInt(m['cacheBytes']) ?? 0,
        filesBytes: asInt(m['filesBytes']) ?? 0,
      );
}
