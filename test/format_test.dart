import 'package:flutter_test/flutter_test.dart';
import 'package:task_x/core/utils/cpu_math.dart';
import 'package:task_x/core/utils/format.dart';

void main() {
  group('formatBytes', () {
    test('null menjadi tanda strip', () {
      expect(formatBytes(null), '—');
    });
    test('satuan basis 1024', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(1024 * 1024 * 1024), '1.0 GB');
    });
  });

  group('formatDuration', () {
    test('menit dan detik', () {
      expect(formatDuration(const Duration(minutes: 5, seconds: 7)), '5 menit 7 detik');
    });
    test('jam', () {
      expect(formatDuration(const Duration(hours: 3, minutes: 4)), '3 jam 4 menit');
    });
    test('satu hari tidak ambigu', () {
      expect(formatDuration(const Duration(days: 1, hours: 9, minutes: 11)), '1 hari 9 jam 11 menit');
    });
    test('di bawah semenit', () {
      expect(formatDuration(const Duration(seconds: 42)), '42 detik');
    });
    test('hari', () {
      expect(formatDuration(const Duration(days: 2, hours: 5, minutes: 1)), '2 hari 5 jam 1 menit');
    });
  });

  group('formatFrequency', () {
    test('MHz dan GHz', () {
      expect(formatFrequency(null), '—');
      expect(formatFrequency(800000), '800 MHz');
      expect(formatFrequency(2000000), '2.00 GHz');
    });
  });

  group('CpuMath', () {
    test('menghitung fraksi pemakaian dari dua pembacaan', () {
      // user nice system idle iowait
      final prev = [100, 0, 100, 800, 0];
      final cur = [250, 0, 250, 1000, 0];
      // total delta = 500, idle delta = 200 -> 60%
      expect(CpuMath.usage(prev, cur), closeTo(0.6, 1e-9));
    });
    test('data tidak valid menghasilkan null', () {
      expect(CpuMath.usage([1, 2], [3, 4]), isNull);
      expect(CpuMath.usage([1, 1, 1, 1, 1], [1, 1, 1, 1, 1]), isNull);
    });
  });
}
