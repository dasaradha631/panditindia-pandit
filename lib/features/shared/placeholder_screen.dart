import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Generic "not built yet" screen used by every deferred stage route.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.construction_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.comingSoonTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.onDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.comingSoonSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onDarkMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
