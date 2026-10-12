import 'app_settings.dart';
import 'metrics_service.dart';

/// Akses global sederhana ke layanan inti (tanpa dependency tambahan).
class Services {
  Services._();

  static late AppSettings settings;
  static late MetricsService metrics;

  static Future<void> init() async {
    settings = AppSettings();
    await settings.load();
    metrics = MetricsService(settings);
    metrics.start();
  }
}
