import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const String kLogoAsset = 'assets/images/mujib_logo.png';

/// Logo resmi (mujib_logo.png) pada plat gelap; rasio aspek dipertahankan (BoxFit.contain).
class LogoPlate extends StatelessWidget {
  const LogoPlate({super.key, this.size = 44, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(radius ?? size * 0.26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
      ),
      child: Image.asset(
        kLogoAsset,
        fit: BoxFit.contain,
        cacheWidth: (size * 3).round(),
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// "Task X" + "by mujib_syarif" di samping logo.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.logoSize = 44});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoPlate(size: logoSize),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Task X',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.1,
                color: context.fg,
              ),
            ),
            Text(
              'by mujib_syarif',
              style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w500,
                color: context.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
