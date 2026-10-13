import 'package:flutter/services.dart';

import '../models/app_models.dart';
import '../models/device_models.dart';
import '../models/sensor_models.dart';
import '../models/storage_models.dart';
import '../utils/json_utils.dart';

/// Satu-satunya pintu masuk ke kode native Android (Kotlin).
/// Semua metode mengembalikan null/false/kosong jika data tidak tersedia,
/// sehingga UI dapat menampilkan status "tidak tersedia" tanpa crash.
class NativeBridge {
  NativeBridge._();

  static final NativeBridge instance = NativeBridge._();
  static const MethodChannel _ch = MethodChannel('taskx/native');
  static const EventChannel _sensorCh = EventChannel('taskx/sensors');

  Future<Object?> _raw(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _ch.invokeMethod<Object?>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<T?> _obj<T>(String method, T Function(Map<String, dynamic>) parse, [Map<String, dynamic>? args]) async {
    final r = await _raw(method, args);
    if (r is Map) return parse(asMap(r));
    return null;
  }

  Future<bool> _bool(String method, [Map<String, dynamic>? args]) async {
    final r = await _raw(method, args);
    return r == true;
  }

  // --- Perangkat & metrik ---
  Future<DeviceInfo?> deviceInfo() => _obj('deviceInfo', DeviceInfo.fromMap);
  Future<MemoryInfo?> memory() => _obj('memory', MemoryInfo.fromMap);
  Future<StorageInfo?> storage() => _obj('storage', StorageInfo.fromMap);
  Future<BatteryInfo?> battery() => _obj('battery', BatteryInfo.fromMap);
  Future<NetworkInfo?> network() => _obj('network', NetworkInfo.fromMap);
  Future<CpuInfo?> cpu() => _obj('cpu', CpuInfo.fromMap);
  Future<OwnProcessInfo?> ownProcess() => _obj('ownProcess', OwnProcessInfo.fromMap);

  Future<int?> uptimeMs() async => asInt(await _raw('uptimeMs'));

  Future<List<SensorItem>> sensors() async {
    final r = await _raw('sensors');
    return asMapList(r).map(SensorItem.fromMap).toList();
  }

  Future<int> clearOwnCache() async => asInt(await _raw('clearOwnCache')) ?? 0;

  // --- Aplikasi ---
  Future<int?> appCount() async => asInt(await _raw('appCount'));

  Future<List<AppInfo>> installedApps() async {
    final r = await _raw('installedApps');
    return asMapList(r).map(AppInfo.fromMap).where((a) => a.packageName.isNotEmpty).toList();
  }

  Future<Uint8List?> appIcon(String packageName, int size) async {
    final r = await _raw('appIcon', {'package': packageName, 'size': size});
    return r is Uint8List ? r : null;
  }

  Future<bool> launchApp(String packageName) => _bool('launchApp', {'package': packageName});
  Future<bool> openAppInfo(String packageName) => _bool('openAppInfo', {'package': packageName});
  Future<bool> openOwnAppInfo() => _bool('openOwnAppInfo');
  Future<bool> uninstallApp(String packageName) => _bool('uninstallApp', {'package': packageName});

  Future<bool> hasUsageAccess() => _bool('hasUsageAccess');
  Future<bool> openUsageSettings() => _bool('openUsageSettings');

  Future<List<UsageEntry>> recentlyUsed({Duration window = const Duration(hours: 24)}) async {
    final r = await _raw('recentlyUsed', {'windowMs': window.inMilliseconds});
    return asMapList(r).map(UsageEntry.fromMap).where((e) => e.packageName.isNotEmpty).toList();
  }

  // --- Penyimpanan (Storage Access Framework) ---
  Future<String?> pickDirectory() async => asString(await _raw('pickDirectory'));

  Future<ScanResult?> scanDirectory(String uri) =>
      _obj('scanDirectory', ScanResult.fromMap, {'uri': uri, 'topN': 50});

  Future<bool> openDocument(String uri, String mime) => _bool('openDocument', {'uri': uri, 'mime': mime});

  /// Menyimpan teks lewat dialog "Simpan sebagai" milik sistem. Mengembalikan URI atau null jika dibatalkan.
  Future<String?> saveTextFile(String name, String content, {String mime = 'text/plain'}) async =>
      asString(await _raw('saveTextFile', {'name': name, 'content': content, 'mime': mime}));

  /// Membuka lembar berbagi Android. Pengguna memilih tujuan; Task X tidak mengirim apa pun sendiri.
  Future<bool> shareText(String subject, String text) => _bool('shareText', {'subject': subject, 'text': text});

  Future<bool> openStorageSettings() => _bool('openStorageSettings');

  /// Aliran pembacaan sensor. Pendengar native hanya aktif selama ada langganan.
  Stream<SensorReading> sensorStream(List<int> types) {
    return _sensorCh
        .receiveBroadcastStream(types)
        .map((e) => SensorReading.fromEvent(e))
        .where((r) => r != null)
        .cast<SensorReading>();
  }
}
