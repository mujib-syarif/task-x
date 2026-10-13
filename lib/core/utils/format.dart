/// Nilai yang tidak dapat dibaca dari Android (bukan angka karangan).
const String kUnavailable = 'N/A';

/// Ukuran dengan basis 1024 (konvensi Android untuk RAM/penyimpanan).
String formatBytes(num? bytes, {int decimals = 1}) {
  if (bytes == null || bytes.isNaN || bytes.isInfinite) return '—';
  if (bytes < 1024) return '${bytes.round()} B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  double v = bytes / 1024;
  int i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(decimals)} ${units[i]}';
}

String formatRate(double? bytesPerSecond) {
  if (bytesPerSecond == null) return '—';
  return '${formatBytes(bytesPerSecond)}/s';
}

String formatPercent(double? fraction, {int decimals = 0}) {
  if (fraction == null) return '—';
  return '${(fraction * 100).toStringAsFixed(decimals)}%';
}

/// Format Indonesia yang konsisten: "1 hari 9 jam 11 menit".
String formatDuration(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  if (days > 0) return '$days hari $hours jam $minutes menit';
  if (d.inHours > 0) return '${d.inHours} jam $minutes menit';
  if (d.inMinutes > 0) return '${d.inMinutes} menit $seconds detik';
  return '$seconds detik';
}

String two(int n) => n.toString().padLeft(2, '0');

String formatClock(DateTime t) => '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatDate(int? millis) {
  if (millis == null || millis <= 0) return '—';
  final t = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${t.day} ${_months[t.month - 1]} ${t.year}';
}

String formatAgo(int? millis, {DateTime? now}) {
  if (millis == null || millis <= 0) return '—';
  final diff = (now ?? DateTime.now()).difference(DateTime.fromMillisecondsSinceEpoch(millis));
  if (diff.inSeconds < 60) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}

String formatFrequency(int? khz) {
  if (khz == null) return '—';
  if (khz >= 1000000) return '${(khz / 1000000).toStringAsFixed(2)} GHz';
  return '${(khz / 1000).round()} MHz';
}
