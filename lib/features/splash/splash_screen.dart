import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/brand_logo.dart';

/// Pandit app splash - brand screen that hands off to the login placeholder.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  int _activeDot = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    for (int i = 0; i < 4; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      setState(() => _activeDot = i);
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkStatus,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.splashGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 60),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOut,
                    ),
                    child: const Column(
                      children: <Widget>[
                        BrandLogo(size: 96, onDark: true),
                        SizedBox(height: 16),
                        BrandLockup(
                          size: 54,
                          onDark: true,
                          alignment: CrossAxisAlignment.center,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.35, 1, curve: Curves.easeOut),
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          AppStrings.splashHeadline,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: AppColors.onDark,
                                height: 1.32,
                              ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(4, (int index) {
                            final bool active = index == _activeDot;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 320),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: active ? 10 : 7,
                              height: active ? 10 : 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.onDark.withValues(alpha: 0.35),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppStrings.loading,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: AppColors.onDarkMuted,
                                letterSpacing: 0.6,
                              ),
                        ),
                        const SizedBox(height: 34),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
