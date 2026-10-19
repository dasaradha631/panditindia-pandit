import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pandit_app/services/geo_service.dart';

void main() {
  late http.Request? lastRequest;

  MockClient clientReturning(Map<String, dynamic> body, {int status = 200}) =>
      MockClient((request) async {
        lastRequest = request;
        return http.Response(jsonEncode(body), status);
      });

  test('reverse geocode resolves city, state and pincode from address', () async {
    lastRequest = null;
    final service = GeoService(
      client: clientReturning({
        'address': {
          'city': 'Bengaluru',
          'state': 'Karnataka',
          'postcode': '560001',
          'country': 'India',
        },
      }),
    );

    final result = await service.reverseGeocode(13.06678, 77.52091);

    expect(result, isNotNull);
    expect(result!.city, 'Bengaluru');
    expect(result.state, 'Karnataka');
    expect(result.pincode, '560001');
    final uri = lastRequest!.url;
    expect(uri.host, 'nominatim.openstreetmap.org');
    expect(uri.path, '/reverse');
    expect(uri.queryParameters['format'], 'jsonv2');
    expect(uri.queryParameters['lat'], '13.06678');
    expect(uri.queryParameters['lon'], '77.52091');
  });

  test('city falls back to town, village then county like the web app', () async {
    lastRequest = null;
    final service = GeoService(
      client: clientReturning({
        'address': {'village': 'Melukote', 'state': 'Karnataka'},
      }),
    );

    final result = await service.reverseGeocode(12.6, 76.6);

    expect(result!.city, 'Melukote');
    expect(result.state, 'Karnataka');
    expect(result.pincode, isNull);
  });

  test('a failed response returns null so entered values are kept', () async {
    lastRequest = null;
    final service = GeoService(client: clientReturning(const {}, status: 404));

    expect(await service.reverseGeocode(13.0, 77.5), isNull);
  });

  test('a response without an address returns null', () async {
    lastRequest = null;
    final service = GeoService(client: clientReturning({'display_name': 'x'}));

    expect(await service.reverseGeocode(13.0, 77.5), isNull);
  });
}
