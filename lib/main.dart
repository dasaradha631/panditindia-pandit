import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_l10n.dart';
import 'core/session/session_guard.dart';
import 'core/theme/app_theme.dart';
import 'core/translation/translated_scope.dart';
import 'core/widgets/mobile_frame.dart';
import 'features/splash/splash_screen.dart';
import 'providers/assignments_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/pandit_profile_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PanditIndiaAcharyaApp());
}

/// Shared with SessionGuard so the 15-minute idle sign-out can route to
/// the login screen from anywhere.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class PanditIndiaAcharyaApp extends StatelessWidget {
  const PanditIndiaAcharyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(recipientType: 'pandit')),
        ChangeNotifierProvider(create: (_) => PanditProfileProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, language, _) => Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) =>
              context.read<AuthProvider>().touchActivityThrottled(),
          child: MaterialApp(
            title: 'PanditIndia Acharya',
            debugShowCheckedModeBanner: false,
            navigatorKey: rootNavigatorKey,
            theme: AppTheme.light(),
            locale: language.locale,
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.delegates,
            // Translates every rendered string into the selected language —
            // the mobile counterpart of the web app's Google Translate widget.
            // SessionGuard reacts to the 15-minute idle sign-out by routing
            // to the login screen with an explanatory toast so screens never
            // sit there with empty, cleared-session data.
            builder: (context, child) => TranslatedScope(
              child: SessionGuard(
                navigatorKey: rootNavigatorKey,
                child: buildMobileFrame(context, child),
              ),
            ),
            home: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}