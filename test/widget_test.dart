import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:panditindia_pandit/app/app.dart';
import 'package:panditindia_pandit/app/routes.dart';
import 'package:panditindia_pandit/core/constants/app_strings.dart';
import 'package:panditindia_pandit/core/widgets/brand_logo.dart';
import 'package:panditindia_pandit/features/splash/splash_screen.dart';

void main() {
  testWidgets('splash renders brand and hands off to login',
      (WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, _) => const SizedBox.shrink()),
      ],
    );
    await tester.pumpWidget(PanditIndiaPanditApp(router: router));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(BrandLockup), findsOneWidget);
    expect(find.text(AppStrings.splashHeadline), findsOneWidget);

    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 520));
    }
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.byType(SplashScreen), findsNothing);
  });

  test('createRouter exposes the Stage 1 scaffold routes', () {
    final GoRouter router = createRouter();
    expect(router.configuration.routes.length, greaterThanOrEqualTo(8));
    expect(router.configuration.routes.first, isA<GoRoute>());
  });
}
