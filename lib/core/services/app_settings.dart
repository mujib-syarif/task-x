import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/thermal.dart';

/// ID modul kartu pada Beranda.
class DashboardModule {
  DashboardModule._();

  static const ram = 'ram';
  static const cpu = 'cpu';
  static const storage = 'storage';
  static const battery = 'battery';
  static const network = 'network';
  static const system = 'system';

  static const all = [ram, cpu, storage, battery, network, system];

  static String label(String id) => switch (id) {
        DashboardModule.ram => 'Memori (RAM)',
        DashboardModule.cpu => 'CPU',
        DashboardModule.storage => 'Penyimpanan',
        DashboardModule.battery => 'Baterai',
        DashboardModule.network => 'Jaringan',
        _ => 'Sistem (uptime & aplikasi)',
      };
}

/// Preferensi pengguna, disimpan lokal dengan shared_preferences.
class AppSettings extends ChangeNotifier {
  static const intervalOptions = [1, 2, 3, 5, 10];
  static const historyOptions = [30, 60, 120, 300];

  ThemeMode themeMode = ThemeMode.system;
  int intervalSeconds = 2;
  int historyPoints = 60;
  bool filledCharts = true;
  bool thermalAlert = true;
  int thermalWarnC = Thermal.defaultWarnC;
  Set<String> modules = {...DashboardModule.all};
  String? lastScanUri;

  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      final theme = p.getString('theme');
      themeMode = ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system);
      final interval = p.getInt('interval');
      if (interval != null && intervalOptions.contains(interval)) intervalSeconds = interval;
      final history = p.getInt('history');
      if (history != null && historyOptions.contains(history)) historyPoints = history;
      filledCharts = p.getBool('filled') ?? true;
      thermalAlert = p.getBool('thermalAlert') ?? true;
      final warn = p.getInt('thermalWarnC');
      if (warn != null && Thermal.warnOptions.contains(warn)) thermalWarnC = warn;
      final mods = p.getStringList('modules');
      if (mods != null) modules = mods.where(DashboardModule.all.contains).toSet();
      lastScanUri = p.getString('lastScanUri');
    } catch (_) {
      // Gunakan nilai bawaan jika penyimpanan tidak dapat dibaca.
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _prefs?.setString('theme', mode.name);
    notifyListeners();
  }

  void setInterval(int seconds) {
    intervalSeconds = seconds;
    _prefs?.setInt('interval', seconds);
    notifyListeners();
  }

  void setHistoryPoints(int points) {
    historyPoints = points;
    _prefs?.setInt('history', points);
    notifyListeners();
  }

  void setFilledCharts(bool value) {
    filledCharts = value;
    _prefs?.setBool('filled', value);
    notifyListeners();
  }

  void setThermalAlert(bool value) {
    thermalAlert = value;
    _prefs?.setBool('thermalAlert', value);
    notifyListeners();
  }

  void setThermalWarnC(int celsius) {
    thermalWarnC = celsius;
    _prefs?.setInt('thermalWarnC', celsius);
    notifyListeners();
  }

  void setModule(String id, bool enabled) {
    final next = {...modules};
    if (enabled) {
      next.add(id);
    } else {
      next.remove(id);
    }
    modules = next;
    _prefs?.setStringList('modules', next.toList());
    notifyListeners();
  }

  void setLastScanUri(String? uri) {
    lastScanUri = uri;
    if (uri == null) {
      _prefs?.remove('lastScanUri');
    } else {
      _prefs?.setString('lastScanUri', uri);
    }
  }
}
