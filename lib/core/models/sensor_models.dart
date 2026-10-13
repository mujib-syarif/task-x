import '../utils/json_utils.dart';

/// Sensor yang dapat dibaca langsung tanpa izin khusus (selaras dengan SensorStreamer.kt).
class SensorSpec {
  const SensorSpec(this.type, this.label, this.unit, this.axes);

  final int type;
  final String label;
  final String unit;
  final List<String> axes;

  static const List<SensorSpec> live = [
    SensorSpec(1, 'Akselerometer', 'm/s²', ['X', 'Y', 'Z']),
    SensorSpec(4, 'Giroskop', 'rad/s', ['X', 'Y', 'Z']),
    SensorSpec(5, 'Sensor cahaya', 'lx', ['Cahaya']),
    SensorSpec(8, 'Sensor jarak (proximity)', 'cm', ['Jarak']),
    SensorSpec(2, 'Magnetometer', 'µT', ['X', 'Y', 'Z']),
    SensorSpec(6, 'Barometer', 'hPa', ['Tekanan']),
    SensorSpec(9, 'Gravitasi', 'm/s²', ['X', 'Y', 'Z']),
    SensorSpec(10, 'Akselerasi linear', 'm/s²', ['X', 'Y', 'Z']),
    SensorSpec(11, 'Vektor rotasi', '', ['X', 'Y', 'Z']),
    SensorSpec(15, 'Vektor rotasi game', '', ['X', 'Y', 'Z']),
    SensorSpec(20, 'Vektor rotasi geomagnetik', '', ['X', 'Y', 'Z']),
    SensorSpec(12, 'Kelembapan', '%', ['Kelembapan']),
    SensorSpec(13, 'Suhu lingkungan', '°C', ['Suhu']),
  ];

  static SensorSpec? byType(int type) {
    for (final s in live) {
      if (s.type == type) return s;
    }
    return null;
  }
}

/// Satu pembacaan sensor dari native.
class SensorReading {
  const SensorReading({required this.type, required this.values, required this.accuracy, required this.time});

  final int type;
  final List<double> values;
  final int accuracy;
  final DateTime time;

  static SensorReading? fromEvent(Object? e, {DateTime? now}) {
    if (e is! Map) return null;
    final m = asMap(e);
    final type = asInt(m['type']);
    final raw = m['values'];
    if (type == null || raw is! List) return null;
    return SensorReading(
      type: type,
      values: [for (final v in raw) if (v is num) v.toDouble()],
      accuracy: asInt(m['accuracy']) ?? -1,
      time: now ?? DateTime.now(),
    );
  }
}
