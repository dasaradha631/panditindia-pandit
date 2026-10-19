import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../main_shell.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([
      auth.restoreSession(),
      context.read<LanguageProvider>().load(),
      Future.delayed(const Duration(milliseconds: 1600)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn ? const MainShell() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldDark]),
                  boxShadow: [
                    BoxShadow(color: AppColors.gold.withValues(alpha: 0.45), blurRadius: 32, spreadRadius: 4),
                  ],
                ),
                child: const Center(child: Text('🕉', style: TextStyle(fontSize: 52))),
              ),
              const SizedBox(height: 26),
              const Text(
                AppConfig.appName,
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              const Text(
                'ACHARYA PORTAL',
                style: TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
