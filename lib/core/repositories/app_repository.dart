import '../models/app_models.dart';
import '../services/native_bridge.dart';

/// Cache daftar aplikasi terinstal agar tidak dipindai berulang kali.
class AppRepository {
  AppRepository._();

  static final AppRepository instance = AppRepository._();

  List<AppInfo>? _cache;
  Future<List<AppInfo>>? _loading;

  List<AppInfo>? get cached => _cache;

  Future<List<AppInfo>> load({bool force = false}) {
    final cache = _cache;
    if (!force && cache != null) return Future.value(cache);
    final running = _loading;
    if (running != null) return running;
    final future = _fetch();
    _loading = future;
    return future;
  }

  Future<List<AppInfo>> _fetch() async {
    try {
      final apps = await NativeBridge.instance.installedApps();
      apps.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      _cache = apps;
      return apps;
    } finally {
      _loading = null;
    }
  }
}
