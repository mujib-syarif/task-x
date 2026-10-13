/// Tingkat peringatan suhu BATERAI (bukan suhu CPU atau komponen lain).
enum ThermalLevel { unknown, normal, warm, hot }

class Thermal {
  Thermal._();

  /// Ambang awal konservatif (°C).
  static const defaultWarnC = 40;
  static const warnOptions = [38, 40, 42, 45];

  /// Selisih antara tingkat "hangat" dan "panas".
  static const hotMarginC = 5;

  static ThermalLevel evaluate(double? tempC, int warnC) {
    if (tempC == null || tempC.isNaN) return ThermalLevel.unknown;
    if (tempC >= warnC + hotMarginC) return ThermalLevel.hot;
    if (tempC >= warnC) return ThermalLevel.warm;
    return ThermalLevel.normal;
  }
}
