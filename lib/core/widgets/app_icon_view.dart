import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/native_bridge.dart';
import '../theme/app_theme.dart';

class IconCache {
  IconCache._();

  static const int _maxEntries = 200;

  // Map literal mempertahankan urutan sisip; entri tertua ada di depan (LRU).
  static final Map<String, Future<Uint8List?>> _cache = {};

  static Future<Uint8List?> get(String packageName, int px) {
    final hit = _cache.remove(packageName);
    if (hit != null) {
      _cache[packageName] = hit; // tandai sebagai paling baru dipakai
      return hit;
    }
    final future = NativeBridge.instance.appIcon(packageName, px);
    _cache[packageName] = future;
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    // Jangan menyimpan hasil null (gagal) agar bisa dicoba lagi.
    future.then<void>(
      (data) {
        if (data == null && identical(_cache[packageName], future)) {
          _cache.remove(packageName);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_cache[packageName], future)) _cache.remove(packageName);
      },
    );
    return future;
  }
}

/// Ikon asli aplikasi (dimuat malas dari PackageManager dan di-cache).
class AppIconView extends StatefulWidget {
  const AppIconView({super.key, required this.packageName, this.size = 40});

  final String packageName;
  final double size;

  @override
  State<AppIconView> createState() => _AppIconViewState();
}

class _AppIconViewState extends State<AppIconView> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant AppIconView old) {
    super.didUpdateWidget(old);
    if (old.packageName != widget.packageName) _future = _load();
  }

  Future<Uint8List?> _load() => IconCache.get(widget.packageName, 128);

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<Uint8List?>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data;
          if (data == null) {
            return Icon(Icons.android_rounded, size: size * 0.6, color: context.muted);
          }
          return Image.memory(
            data,
            width: size,
            height: size,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          );
        },
      ),
    );
  }
}
