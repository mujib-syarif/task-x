import '../utils/json_utils.dart';

class AppInfo {
  const AppInfo({
    required this.packageName,
    required this.label,
    required this.versionCode,
    required this.isSystem,
    required this.isUpdatedSystem,
    required this.enabled,
    required this.apkSize,
    required this.firstInstall,
    required this.lastUpdate,
    required this.targetSdk,
    required this.category,
    required this.canLaunch,
    this.versionName,
    this.minSdk,
  });

  final String packageName;
  final String label;
  final String? versionName;
  final int versionCode;
  final bool isSystem;
  final bool isUpdatedSystem;
  final bool enabled;

  /// Ukuran berkas APK (termasuk split), BUKAN total data/cache aplikasi.
  final int apkSize;
  final int firstInstall;
  final int lastUpdate;
  final int targetSdk;
  final int? minSdk;
  final int category;
  final bool canLaunch;

  String get categoryLabel => switch (category) {
        0 => 'Game',
        1 => 'Audio',
        2 => 'Video',
        3 => 'Gambar',
        4 => 'Sosial',
        5 => 'Berita',
        6 => 'Peta & Navigasi',
        7 => 'Produktivitas',
        _ => 'Tanpa kategori',
      };

  factory AppInfo.fromMap(Map<String, dynamic> m) => AppInfo(
        packageName: asString(m['package']) ?? '',
        label: asString(m['label']) ?? asString(m['package']) ?? '',
        versionName: asString(m['versionName']),
        versionCode: asInt(m['versionCode']) ?? 0,
        isSystem: m['isSystem'] == true,
        isUpdatedSystem: m['isUpdatedSystem'] == true,
        enabled: m['enabled'] != false,
        apkSize: asInt(m['apkSize']) ?? 0,
        firstInstall: asInt(m['firstInstall']) ?? 0,
        lastUpdate: asInt(m['lastUpdate']) ?? 0,
        targetSdk: asInt(m['targetSdk']) ?? 0,
        minSdk: asInt(m['minSdk']),
        category: asInt(m['category']) ?? -1,
        canLaunch: m['canLaunch'] == true,
      );
}

class UsageEntry {
  const UsageEntry({required this.packageName, required this.lastUsed, required this.foregroundMs});

  final String packageName;
  final int lastUsed;
  final int foregroundMs;

  factory UsageEntry.fromMap(Map<String, dynamic> m) => UsageEntry(
        packageName: asString(m['package']) ?? '',
        lastUsed: asInt(m['lastUsed']) ?? 0,
        foregroundMs: asInt(m['foregroundMs']) ?? 0,
      );
}
