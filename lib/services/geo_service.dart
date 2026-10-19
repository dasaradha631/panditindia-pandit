import 'dart:convert';

import 'package:http/http.dart' as http;

/// Address fields resolved from a GPS fix, mirroring the web dashboard's
/// `pingDeviceGpsForProfile` reverse geocode (Nominatim OSM).
class ReverseGeoResult {
  const ReverseGeoResult({this.city, this.state, this.pincode});

  factory ReverseGeoResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'];
    if (address is! Map) return const ReverseGeoResult();
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = address[k]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    return ReverseGeoResult(
      city: pick(const [
        'city', 'town', 'village', 'municipality', 'suburb', 'county',
      ]),
      state: pick(const ['state', 'state_district', 'region', 'province']),
      pincode: pick(const ['postcode', 'postal_code']),
    );
  }

  final String? city;
  final String? state;
  final String? pincode;

  bool get hasAny =>
      (city?.isNotEmpty ?? false) ||
      (state?.isNotEmpty ?? false) ||
      (pincode?.isNotEmpty ?? false);
}

/// A point resolved from an address (city/state/pincode -> lat/lng).
class ForwardGeoResult {
  const ForwardGeoResult({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Forward + reverse geocoding helper (Nominatim OSM).
class GeoService {
  GeoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _reverseEndpoint =
      'https://nominatim.openstreetmap.org/reverse';
  static const String _searchEndpoint =
      'https://nominatim.openstreetmap.org/search';

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'PanditIndiaApp/1.0 (https://panditindia.com)',
  };

  /// Resolves an address to a point, mirroring the web dashboard's
  /// `autoGeocodeLocation` (Nominatim search pinned to India). Returns null
  /// when nothing resolves so callers can leave latitude/longitude unset and
  /// let the backend auto-geocode from the city instead.
  Future<ForwardGeoResult?> geocodeAddress({
    String? city,
    String? state,
    String? pincode,
  }) async {
    final digits = (pincode ?? '').replaceAll(RegExp(r'\D'), '');
    final query = <String>[
      if (digits.isNotEmpty) digits,
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((state ?? '').trim().isNotEmpty) state!.trim(),
      'India',
    ].join(', ');
    if (query == 'India') return null;
    try {
      final uri = Uri.parse('$_searchEndpoint?format=jsonv2&limit=1'
          '&countrycodes=in&q=${Uri.encodeQueryComponent(query)}');
      final res = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! List || body.isEmpty) return null;
      final first = body.first;
      if (first is! Map) return null;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;
      return ForwardGeoResult(latitude: lat, longitude: lon);
    } catch (_) {
      return null;
    }
  }

  /// Resolves [latitude]/[longitude] to an address. Returns null when the
  /// lookup fails or the response carries no address, so callers keep the
  /// values the user already entered.
  Future<ReverseGeoResult?> reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.parse('$_reverseEndpoint?format=jsonv2'
          '&lat=$latitude&lon=$longitude');
      // Nominatim rejects requests without an identifying User-Agent, which
      // is why the field autofill silently failed with the dart:http default.
      final res = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'PanditIndiaApp/1.0 (https://panditindia.com)',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) return null;
      final result = ReverseGeoResult.fromJson(body);
      return result.hasAny ? result : null;
    } catch (_) {
      return null;
    }
  }
}
