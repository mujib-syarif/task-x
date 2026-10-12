import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/device_models.dart';
import '../utils/cpu_math.dart';
import 'app_settings.dart';
import 'native_bridge.dart';

enum Series { ram, cpu, batteryLevel, batteryTemp, netDown, netUp }

class MetricsSnapshot {
  const MetricsSnapshot({
    required this.time,
    this.memory,
    this.storage,
    this.battery,
    this.network,
    this.cpu,
    this.cpuUsage,
    this.netDownBps,
    this.netUpBps,
    this.uptimeMs,
  });

  final DateTime time;
  final MemoryInfo? memory;
  final StorageInfo? storage;
  final BatteryInfo? battery;
  final NetworkInfo? network;
  final CpuInfo? cpu;

  /// Fraksi 0..1; null jika Android tidak mengizinkan pembacaan CPU total.
  final double? cpuUsage;
  final double? netDownBps;
  final double? netUpBps;
  final int? uptimeMs;
}

class SnapshotNotifier extends ValueNotifier<MetricsSnapshot?> {
  SnapshotNotifier() : super(null);

  void bump() => notifyListeners();
}

/// Mengumpulkan metrik secara berkala. Berhenti ketika aplikasi tidak aktif.
class MetricsService with WidgetsBindingObserver {
  MetricsService(this._settings) {
    _lastInterval = _settings.intervalSeconds;
    _settings.addListener(_onSettings);
  }

  final AppSettings _settings;
  final SnapshotNotifier snapshot = SnapshotNotifier();
  final Map<Series, ListQueue<double>> _history = {
    for (final s in Series.values) s: ListQueue<double>(),
  };

  Timer? _timer;
  bool _busy = false;
  bool _observing = false;
  bool _active = false;
  int _lastInterval = 2;

  List<int>? _prevStat;
  int? _prevRx;
  int? _prevTx;
  DateTime? _prevTime;

  List<double> history(Series s) => _history[s]!.toList(growable: false);

  void start() {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _active = true;
    _schedule();
    refresh();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: _settings.intervalSeconds), (_) => refresh());
  }

  void _resetDeltas() {
    _prevStat = null;
    _prevRx = null;
    _prevTx = null;
    _prevTime = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _active = true;
      _resetDeltas();
      _schedule();
      refresh();
    } else {
      _active = false;
      _timer?.cancel();
      _timer = null;
    }
  }

  void _onSettings() {
    if (_settings.intervalSeconds != _lastInterval) {
      _lastInterval = _settings.intervalSeconds;
      if (_active) _schedule();
    }
    for (final q in _history.values) {
      while (q.length > _settings.historyPoints) {
        q.removeFirst();
      }
    }
  }

  void clearHistory() {
    for (final q in _history.values) {
      q.clear();
    }
    snapshot.bump();
  }

  void _push(Series s, double? v) {
    if (v == null) return;
    final q = _history[s]!;
    q.add(v);
    while (q.length > _settings.historyPoints) {
      q.removeFirst();
    }
  }

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    try {
      final b = NativeBridge.instance;
      final results = await Future.wait<Object?>([
        b.memory(),
        b.storage(),
        b.battery(),
        b.network(),
        b.cpu(),
        b.uptimeMs(),
      ]);
      final mem = results[0] as MemoryInfo?;
      final sto = results[1] as StorageInfo?;
      final bat = results[2] as BatteryInfo?;
      final net = results[3] as NetworkInfo?;
      final cpu = results[4] as CpuInfo?;
      final uptime = results[5] as int?;
      final now = DateTime.now();

      double? cpuUsage;
      final stat = cpu?.stat;
      if (stat != null) {
        final prev = _prevStat;
        if (prev != null) cpuUsage = CpuMath.usage(prev, stat);
        _prevStat = stat;
      } else {
        _prevStat = null;
      }

      double? down;
      double? up;
      final rx = net?.rxBytes;
      final tx = net?.txBytes;
      final prevRx = _prevRx;
      final prevTx = _prevTx;
      final prevTime = _prevTime;
      if (rx != null && tx != null && prevRx != null && prevTx != null && prevTime != null) {
        final dt = now.difference(prevTime).inMilliseconds / 1000.0;
        if (dt > 0) {
          down = math.max(0.0, (rx - prevRx) / dt);
          up = math.max(0.0, (tx - prevTx) / dt);
        }
      }
      _prevRx = rx;
      _prevTx = tx;
      _prevTime = now;

      _push(Series.ram, mem == null ? null : mem.usedFraction * 100);
      _push(Series.cpu, cpuUsage == null ? null : cpuUsage * 100);
      _push(Series.batteryLevel, bat?.percent?.toDouble());
      _push(Series.batteryTemp, bat?.temperatureC);
      _push(Series.netDown, down);
      _push(Series.netUp, up);

      snapshot.value = MetricsSnapshot(
        time: now,
        memory: mem,
        storage: sto,
        battery: bat,
        network: net,
        cpu: cpu,
        cpuUsage: cpuUsage,
        netDownBps: down,
        netUpBps: up,
        uptimeMs: uptime,
      );
    } finally {
      _busy = false;
    }
  }
}
