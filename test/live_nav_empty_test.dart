import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pandit_app/features/app_tab.dart';
import 'package:pandit_app/features/live/live_nav_screen.dart';
import 'package:pandit_app/providers/assignments_provider.dart';
import 'package:pandit_app/providers/pandit_profile_provider.dart';

import 'support/test_environment.dart';

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  testWidgets('empty cockpit offers the View Puja Schedule button', (tester) async {
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AppTab? landed;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AssignmentsProvider()),
          ChangeNotifierProvider(create: (_) => PanditProfileProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(fontFamily: TestEnvironment.fontFamily),
          home: LiveNavScreen(onNavigate: (tab) => landed = tab),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Live Ceremony GPS Navigation'), findsOneWidget);
    expect(find.text('No Active Ceremonies to Navigate'), findsOneWidget);
    expect(
      find.text(
        'Live GPS navigation will appear here when you accept a puja request and begin an active ceremony journey.',
      ),
      findsOneWidget,
    );
    expect(find.text('View Puja Schedule'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('View Puja Schedule'));
    await tester.pump();

    expect(landed, AppTab.schedule);
  });
}
