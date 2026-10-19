import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pandit_app/features/samagri/samagri_screen.dart';

import 'support/test_environment.dart';

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: TestEnvironment.fontFamily),
        home: SamagriScreen(onNavigate: (_) {}),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the web protocols header and both guideline cards', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Vedic Samagri & Ritual Preparation Mandap Protocols'), findsOneWidget);
    expect(find.text('Mandap guidelines and sacred item verification checklist.'), findsOneWidget);
    expect(find.text('Havan & Homam Mandate'), findsOneWidget);
    expect(find.text('Sankalpa Mantra Recitation Guidelines'), findsOneWidget);
    expect(find.text('All PanditIndia Eco-Samagri kits are 100% pre-certified.'), findsOneWidget);
    expect(find.text('Before initiating any ceremony, verify:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('carries the exact Havan and Sankalpa checklist copy', (tester) async {
    await pumpScreen(tester);

    const havan = [
      'Verify 100% pure organic A2 Cow Ghee container before lighting the Agni Kund.',
      'Check 108 Sacred Herb Hawan mix and Navgraha Samidha wood sticks.',
      'Ensure Gangotri Gangajal sealed container is unbroken.',
      'Keep sacred brass/copper Kalash with coconut and mango leaves ready.',
    ];
    const sankalpa = [
      "Devotee's Gotra and ancestral deity (Kula Devata).",
      'Birth Nakshatra of Yajamana (Head of family) and spouse.',
      'Sankalpa purpose (Griha Pravesh, Vastu Shanti, Ayushya, etc.).',
      'Current Vikram Samvat and Lunar Month (Masa & Paksha).',
    ];

    for (final line in havan) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
    for (final line in sankalpa) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('drops the mobile-only kit checklist sections', (tester) async {
    await pumpScreen(tester);

    expect(find.text('SELECT CEREMONY TO PREPARE'), findsNothing);
    expect(find.text('Sealed Eco-Samagri Kit'), findsNothing);
    expect(find.text('Ritual Preparation Protocol'), findsNothing);
    expect(find.text('Acharya Prep Notes'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
