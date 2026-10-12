/// Perhitungan penggunaan CPU dari dua pembacaan baris `cpu` pada /proc/stat.
class CpuMath {
  CpuMath._();

  /// Mengembalikan fraksi 0..1, atau null jika data tidak valid.
  static double? usage(List<int> prev, List<int> cur) {
    if (prev.length < 5 || cur.length < 5) return null;
    int total(List<int> v) => v.take(8).fold(0, (a, b) => a + b);
    int idle(List<int> v) => v[3] + v[4];
    final dTotal = total(cur) - total(prev);
    final dIdle = idle(cur) - idle(prev);
    if (dTotal <= 0) return null;
    return ((dTotal - dIdle) / dTotal).clamp(0.0, 1.0).toDouble();
  }
}
