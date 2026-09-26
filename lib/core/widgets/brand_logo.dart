import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Code drawn PanditIndia monogram (placeholder for `assets/images/logo.png`).
///
/// When a real logo is dropped into [AppAssets] the calling widgets can switch
/// to `Image.asset` without any layout changes.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 56, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: size * 0.045),
        boxShadow: onDark
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.05),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'P',
            style: TextStyle(
              fontFamily: 'Marcellus',
              fontSize: size * 0.46,
              height: 0.9,
              color: AppColors.maroon,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.only(top: size * 0.02),
              child: Text(
                'PANDIT INDIA',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: size * 0.115,
                  fontWeight: FontWeight.w600,
                  letterSpacing: size * 0.012,
                  height: 1,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo + wordmark + tagline header used on splash, app bars and auth pages.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.size = 44,
    this.onDark = false,
    this.showTagline = true,
    this.alignment = CrossAxisAlignment.center,
  });

  final double size;
  final bool onDark;
  final bool showTagline;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final Color wordmarkColor = onDark ? AppColors.onDark : AppColors.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: <Widget>[
        BrandLogo(size: size, onDark: onDark),
        SizedBox(width: size * 0.28),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: wordmarkColor,
                ),
                children: <TextSpan>[
                  const TextSpan(text: 'Pandit'),
                  TextSpan(
                    text: 'India',
                    style: TextStyle(
                      color: onDark ? AppColors.primary : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (showTagline)
              Padding(
                padding: EdgeInsets.only(top: size * 0.06),
                child: Text(
                  AppStrings.tagline,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: size * 0.2,
                    fontWeight: FontWeight.w500,
                    letterSpacing: size * 0.035,
                    color: onDark
                        ? AppColors.onDarkMuted
                        : AppColors.muted.withValues(alpha: 0.9),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
