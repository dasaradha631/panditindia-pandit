import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pandit_app/core/theme/app_theme.dart';
import 'package:pandit_app/core/widgets/common.dart';
import 'package:pandit_app/features/auth/login_screen.dart';
import 'package:pandit_app/providers/auth_provider.dart';
import 'package:pandit_app/providers/language_provider.dart';

void main() {
  test('display status mapping matches the backend status machine', () {
    expect(AppStatus.displayStatus('pending_acceptance'), 'Pending Acceptance');
    expect(AppStatus.displayStatus('pending_reassignment'), 'Pending Reassignment');
    expect(AppStatus.displayStatus('en_route'), 'In Progress');
    expect(AppStatus.displayStatus('aarti'), 'In Progress');
    expect(AppStatus.displayStatus('completed'), 'Completed');
    expect(AppStatus.displayStatus('cancelled'), 'Cancelled');
  });

  test('booking id display format matches the web app', () {
    expect(AppStatus.normalizeBookingId('#PI-2026-9123'), '9123');
    expect(AppStatus.displayBookingId(9123), '#PI-2026-9123');
  });

  testWidgets('KpiCard renders its value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: KpiCard(value: '3', label: 'New Requests')),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text('NEW REQUESTS'), findsOneWidget);
  });

  testWidgets('login screen renders the brand logo', (tester) async {
    tester.view.physicalSize = const Size(412 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/branding/logo.png'),
        tester.element(find.byType(MaterialApp)),
      );
    });
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/branding/logo.png',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/login.png'));
  });
}
