import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:pandit_app/services/tracking_service.dart';

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.whileInUse;
  bool serviceEnabled = true;
  LocationSettings? lastSettings;

  static Position _position() => Position(
        latitude: 28.4595,
        longitude: 77.0266,
        timestamp: DateTime.now(),
        accuracy: 6,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    lastSettings = locationSettings;
    return _position();
  }

  @override
  Future<Position?> getLastKnownPosition({bool forceLocationManager = false}) async => null;
}

void main() {
  late _FakeGeolocatorPlatform fake;
  final GeolocatorPlatform original = GeolocatorPlatform.instance;

  setUp(() {
    fake = _FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fake;
  });

  tearDown(() {
    GeolocatorPlatform.instance = original;
  });

  test('device location switched off is reported as serviceDisabled', () async {
    fake.serviceEnabled = false;
    expect(await PanditTrackingService().requestAccess(), GpsAccess.serviceDisabled);
  });

  test('a denied prompt stays askable and maps to denied', () async {
    fake.permission = LocationPermission.denied;
    expect(await PanditTrackingService().requestAccess(), GpsAccess.denied);
  });

  test('a permanent denial maps to deniedForever so settings can be opened', () async {
    fake.permission = LocationPermission.deniedForever;
    expect(await PanditTrackingService().requestAccess(), GpsAccess.deniedForever);
  });

  test('granted permission maps to granted', () async {
    fake.permission = LocationPermission.whileInUse;
    expect(await PanditTrackingService().requestAccess(), GpsAccess.granted);
  });

  test('a position request carries the 15 second high accuracy time limit', () async {
    final position = await PanditTrackingService().currentPosition();

    expect(position, isNotNull);
    expect(fake.lastSettings, isNotNull);
    expect(fake.lastSettings!.timeLimit, PanditTrackingService.fixTimeLimit);
    expect(fake.lastSettings!.accuracy, LocationAccuracy.high);
  });
}
