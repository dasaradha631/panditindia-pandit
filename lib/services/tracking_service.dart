import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/network/api_client.dart';
import '../models/booking.dart';

/// Why a GPS request could not run, so each caller can offer the right fix.
enum GpsAccess {
  /// Permission granted and device location services are on.
  granted,

  /// The device level "Location" toggle is switched off.
  serviceDisabled,

  /// User denied the prompt but can still be asked again.
  denied,

  /// User denied permanently ("Don't ask again") -> app settings only.
  deniedForever,

  /// Platform threw while probing (unsupported device, web without HTTPS, …).
  unavailable,
}

class PanditTrackingService {
  /// True while a live journey stream is running on this device. The idle
  /// sign-out check treats an active broadcast as "the Acharya is working"
  /// so a driving pandit is never logged out mid-journey. Dart timers only
  /// fire while the app engine is active, so this flag is reliable at every
  /// idle-check tick.
  static bool broadcasting = false;

  /// Mirrors the browser behaviour (enableHighAccuracy + 15 s timeout) so a
  /// cold GPS fix can never hang the UI forever.
  static const Duration fixTimeLimit = Duration(seconds: 15);

  LocationSettings _settings({bool forceLocationManager = false}) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: fixTimeLimit,
        forceLocationManager: forceLocationManager,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: fixTimeLimit,
      );
    }
    return LocationSettings(accuracy: LocationAccuracy.high, timeLimit: fixTimeLimit);
  }

  /// Asks for permission (and that location services are on) exactly once.
  Future<GpsAccess> requestAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return GpsAccess.serviceDisabled;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return switch (permission) {
        LocationPermission.whileInUse || LocationPermission.always => GpsAccess.granted,
        LocationPermission.deniedForever => GpsAccess.deniedForever,
        LocationPermission.denied => GpsAccess.denied,
        _ => GpsAccess.unavailable,
      };
    } catch (_) {
      return GpsAccess.unavailable;
    }
  }

  Future<bool> ensurePermission() async => await requestAccess() == GpsAccess.granted;

  /// Opens the settings page that can unblock the given [access] failure.
  Future<void> openSettings(GpsAccess access) async {
    try {
      if (access == GpsAccess.serviceDisabled) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (_) {
      // Settings screens are best effort on a few OEM builds.
    }
  }

  /// High accuracy fix with a hard timeout, a fused-provider fallback and a
  /// last-known-position rescue so the Acharya always gets a coordinate.
  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(locationSettings: _settings());
    } catch (e) {
      if (e is TimeoutException) return _lastKnown();
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _settings(forceLocationManager: true),
      );
    } catch (_) {}
    return _lastKnown();
  }

  Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Returns true only when the server acknowledged the request — callers use
  /// this to avoid showing a false "Live Telemetry Active" success toast when
  /// the network call silently failed.
  Future<bool> startJourney(dynamic id, Position pos) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      final res = await ApiClient.post(
        '/api/bookings/$numeric/start-journey',
        body: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'accuracy': pos.accuracy,
        },
      );
      return res.success;
    } catch (_) {
      // Stage already advanced through the regular status endpoint.
      return false;
    }
  }

  Future<bool> sendLocation(dynamic id, Position pos, {String? status}) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      final res = await ApiClient.post(
        '/api/bookings/$numeric/location',
        body: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'accuracy': pos.accuracy,
          'speed': pos.speed.isFinite ? pos.speed : 0,
          'heading': pos.heading.isFinite ? pos.heading : 0,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return res.success;
    } catch (_) {
      // Non-critical: next tick will retry.
      return false;
    }
  }

  /// Stops the live stream. [status] must keep the ceremony stage it is
  /// already in — the backend treats an omitted status as "completed".
  Future<bool> stopTracking(dynamic id, {String status = 'completed'}) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      final res = await ApiClient.post(
        '/api/bookings/$numeric/stop-tracking',
        body: {'status': status},
      );
      return res.success;
    } catch (_) {
      // Non-critical.
      return false;
    }
  }
}
