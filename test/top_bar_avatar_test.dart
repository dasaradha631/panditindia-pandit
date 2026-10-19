import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pandit_app/features/main_shell.dart';

/// The top bar profile circle must keep its initial dead centre, otherwise the
/// letter floats into the top left corner of the ring.
void main() {
  Future<void> pumpAvatar(WidgetTester tester, {String? name, String? photoUrl}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF021F2C),
          body: Align(
            alignment: Alignment.topRight,
            child: TopBarAvatar(name: name, photoUrl: photoUrl, onTap: () {}),
          ),
        ),
      ),
    );
  }

  testWidgets('initial letter is centred inside the avatar ring', (tester) async {
    await pumpAvatar(tester, name: 'Pandit Sharma');

    final avatar = tester.getRect(find.byKey(TopBarAvatar.avatarKey));
    final letter = tester.getRect(find.byKey(TopBarAvatar.letterKey));

    expect(avatar.size, const Size(40, 40));
    expect((letter.center.dx - avatar.center.dx).abs(), lessThan(1.0),
        reason: 'letter should be horizontally centred');
    expect((letter.center.dy - avatar.center.dy).abs(), lessThan(1.0),
        reason: 'letter should be vertically centred');
  });

  testWidgets('falls back to a centred A when no name is known', (tester) async {
    await pumpAvatar(tester, name: '   ');

    expect(find.text('A'), findsOneWidget);
    final avatar = tester.getRect(find.byKey(TopBarAvatar.avatarKey));
    final letter = tester.getRect(find.byKey(TopBarAvatar.letterKey));
    expect((letter.center.dx - avatar.center.dx).abs(), lessThan(1.0));
    expect((letter.center.dy - avatar.center.dy).abs(), lessThan(1.0));
  });

  testWidgets('initial comes from the first word of the display name', (tester) async {
    await pumpAvatar(tester, name: 'pandit');
    expect(find.text('P'), findsOneWidget);
  });
}
