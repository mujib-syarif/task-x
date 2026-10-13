/// Penghitung lalu lintas "sesi ini" (sejak Task X dibuka) dari penghitung sistem.
class SessionTraffic {
  int? _baseRx;
  int? _baseTx;
  DateTime? started;

  /// Jika penghitung sistem turun (mis. reset), baseline diulang dari nilai terbaru.
  void update(int? rx, int? tx, DateTime now) {
    if (rx == null || tx == null) return;
    if (_baseRx == null || _baseTx == null || rx < _baseRx! || tx < _baseTx!) {
      _baseRx = rx;
      _baseTx = tx;
      started = now;
    }
  }

  int? rx(int? current) => (current == null || _baseRx == null) ? null : current - _baseRx!;
  int? tx(int? current) => (current == null || _baseTx == null) ? null : current - _baseTx!;
}
