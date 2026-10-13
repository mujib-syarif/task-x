import 'package:flutter/widgets.dart';

import '../services/services.dart';

/// Menyewa [MetricsService] selama halaman benar-benar terlihat.
///
/// Tidak terlihat = tab lain di Shell ([active] false) atau tertutup halaman lain
/// ([TickerMode] mati). Saat tidak terlihat, sewa dilepas sehingga timer berhenti.
class MetricsScope extends StatefulWidget {
  const MetricsScope({super.key, this.active = true, required this.child});

  final bool active;
  final Widget child;

  @override
  State<MetricsScope> createState() => _MetricsScopeState();
}

class _MetricsScopeState extends State<MetricsScope> {
  bool _held = false;

  void _update() {
    final want = widget.active && TickerMode.of(context);
    if (want == _held) return;
    _held = want;
    if (want) {
      Services.metrics.acquire();
    } else {
      Services.metrics.release();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(MetricsScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  @override
  void dispose() {
    if (_held) {
      _held = false;
      Services.metrics.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
