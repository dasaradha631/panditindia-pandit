import 'package:flutter_test/flutter_test.dart';
import 'package:pandit_app/core/network/api_client.dart';
import 'package:pandit_app/core/theme/app_theme.dart';

import 'support/test_environment.dart';

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  test('dob mobile display format is 15-october-2026 and roundtrips to ISO', () {
    expect(Fmt.dobInput('1985-05-15'), '15-may-1985');
    expect(Fmt.dobInput('2026-10-15'), '15-october-2026');
    expect(Fmt.dobInput('15-May-1985'), '15-may-1985');
    expect(Fmt.dobInput('15/05/1985'), '15-may-1985');
    expect(Fmt.dobInput(null), '');
    expect(Fmt.dobToIso('15-october-2026'), '2026-10-15');
    expect(Fmt.dobToIso('15-may-1985'), '1985-05-15');
    expect(Fmt.dobToIso('1985-05-15'), '1985-05-15');
    expect(Fmt.dobToIso('junk'), 'junk');
  });

  group('ApiException.isSessionConflict', () {
    test('detects detail.session_conflict flag (401 only)', () {
      final e = ApiException(
        'Logged in elsewhere',
        statusCode: 401,
        data: {
          'detail': {'session_conflict': true, 'message': 'Signed in from another browser'},
        },
      );
      expect(e.isSessionConflict, isTrue);
    });

    test('detects "another browser" message text', () {
      final e = ApiException(
        'Your account was logged in from another browser or device.',
        statusCode: 401,
        data: {
          'message': 'Your account was logged in from another browser or device.',
        },
      );
      expect(e.isSessionConflict, isTrue);
    });

    test('plain 401 without conflict markers is not a conflict', () {
      final e = ApiException('Invalid credentials', statusCode: 401, data: null);
      expect(e.isSessionConflict, isFalse);
    });
  });
}
