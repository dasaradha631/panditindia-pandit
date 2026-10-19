import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pandit_app/features/auth/login_screen.dart';
import 'package:pandit_app/providers/auth_provider.dart';
import 'package:pandit_app/providers/language_provider.dart';

import 'support/test_environment.dart';

/// Guards the Acharya auth layout so the redesigned login screen keeps fitting
/// a normal phone viewport without scrolling.
void main() {
  setUpAll(TestEnvironment.ensureLoaded);
  Future<double> measure(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(fontFamily: TestEnvironment.fontFamily),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
    return state.position.maxScrollExtent;
  }

  const tall = Size(412, 820);
  const common = Size(360, 740);

  testWidgets('acharya login fits a normal phone without scrolling', (
    tester,
  ) async {
    expect(await measure(tester, tall), 0);
    expect(await measure(tester, common), 0);
  });
}