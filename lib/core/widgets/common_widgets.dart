import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/thermal.dart';

/// Jenis sumber data, supaya pengguna tahu seberapa "hidup" angka yang tampil.
enum DataKind { realtime, periodic, snapshot, unavailable }

class DataBadge extends StatelessWidget {
  const DataBadge(this.kind, {super.key, this.detail});

  final DataKind kind;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      DataKind.realtime => 'Real-time',
      DataKind.periodic => 'Berkala',
      DataKind.snapshot => 'Snapshot',
      DataKind.unavailable => kUnavailable,
    };
    final color = switch (kind) {
      DataKind.realtime => AppColors.green,
      DataKind.periodic => AppColors.blue,
      DataKind.snapshot => context.muted,
      DataKind.unavailable => AppColors.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        detail == null ? label : '$label · $detail',
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: context.muted,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Baris label–nilai. Tekan lama untuk menyalin nilai.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () async {
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(ClipboardData(text: '$label: $value'));
        messenger.showSnackBar(const SnackBar(content: Text('Disalin'), duration: Duration(seconds: 1)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(label, style: TextStyle(fontSize: 13.5, color: context.muted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: value == kUnavailable ? context.muted : context.fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pesan keterbatasan Android yang jujur (bukan error).
class LimitationNotice extends StatelessWidget {
  const LimitationNotice(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, height: 1.4, color: context.fg)),
          ),
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: context.fg,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: TextStyle(fontSize: 13, color: context.muted)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
}

/// Peringatan suhu BATERAI. Tidak tampil jika suhu normal atau tidak terbaca.
class ThermalBanner extends StatelessWidget {
  const ThermalBanner({super.key, required this.tempC, required this.warnC});

  final double? tempC;
  final int warnC;

  @override
  Widget build(BuildContext context) {
    final level = Thermal.evaluate(tempC, warnC);
    if (level != ThermalLevel.warm && level != ThermalLevel.hot) return const SizedBox.shrink();
    final hot = level == ThermalLevel.hot;
    final color = hot ? AppColors.red : AppColors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.thermostat_rounded, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${hot ? 'Suhu baterai tinggi' : 'Suhu baterai hangat'}: ${tempC!.toStringAsFixed(1)} °C '
                '(ambang $warnC °C). Ini suhu baterai, bukan suhu CPU. '
                '${hot ? 'Hentikan penggunaan berat dan lepas pengisi daya bila perangkat terasa panas.' : 'Kurangi penggunaan berat bila terus naik.'}',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: context.fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
