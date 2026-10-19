import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/contact_actions.dart';
import '../../core/utils/gps_prompts.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../providers/assignments_provider.dart';
import '../../providers/pandit_profile_provider.dart';
import '../../services/tracking_service.dart';
import '../app_tab.dart';
import '../home/widgets/ceremony_stages.dart';
import '../home/widgets/dashboard_widgets.dart';
import '../home/widgets/sheets.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Live GPS Navigation cockpit — mobile port of the web `LiveGpsView`
/// (Acharya Cockpit): ceremony picker, START JOURNEY telemetry, devotee
/// contact strip with Sankalpa PIN, one-tap stage sync and a map HUD.
class LiveNavScreen extends StatefulWidget {
  const LiveNavScreen({super.key, required this.onNavigate, this.initialBookingId});

  final void Function(AppTab tab) onNavigate;
  final String? initialBookingId;

  @override
  State<LiveNavScreen> createState() => LiveNavScreenState();
}

class LiveNavScreenState extends State<LiveNavScreen> {
  static const LatLng _india = LatLng(20.5937, 78.9629);

  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _amber50 = Color(0xFFFFFBEB);
  static const Color _amber200 = Color(0xFFFDE68A);

  final PanditTrackingService _tracking = PanditTrackingService();
  final MapController _mapController = MapController();

  String? _selectedId;
  Position? _position;
  bool _sharing = false;
  bool _broadcasting = true;
  bool _locating = false;
  bool _darkTiles = false;
  String? _gpsError;
  double? _distanceM;
  Timer? _shareTimer;

  /// Road-following route drawn on the map (fetched from OSRM exactly like the
  /// web `useLiveGps` hook); `null` falls back to the dashed straight line.
  List<LatLng>? _routePoints;
  String? _routeKey;
  late final AssignmentsProvider _assignments;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialBookingId;
    _assignments = context.read<AssignmentsProvider>();
    // Booking data (venue coordinates) may arrive after the first GPS fix —
    // re-sync the drawn route whenever assignments change.
    _assignments.addListener(_syncRoute);
    if (widget.initialBookingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locate(force: true));
    }
  }

  @override
  void didUpdateWidget(covariant LiveNavScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBookingId != null && widget.initialBookingId != oldWidget.initialBookingId) {
      setState(() => _selectedId = widget.initialBookingId);
      _locate(force: true);
    }
  }

  @override
  void dispose() {
    _shareTimer?.cancel();
    PanditTrackingService.broadcasting = false;
    _assignments.removeListener(_syncRoute);
    super.dispose();
  }

  List<Booking> _bookings(AssignmentsProvider a) {
    final current = a.currentRitual;
    final rest = a.acceptedBookings
        .where((b) => current == null || b.bookingId != current.bookingId)
        .toList()
      ..sort((x, y) => (x.bookingDate ?? '').compareTo(y.bookingDate ?? ''));
    return [?current, ...rest];
  }

  void _select(String? id) {
    if (id == null) return;
    setState(() => _selectedId = id);
    _recomputeDistance();
    _syncRoute();
  }

  Future<void> _locate({bool force = false}) async {
    if (_locating && !force) return;
    setState(() {
      _locating = true;
      _gpsError = null;
    });
    final access = await _tracking.requestAccess();
    if (!mounted) return;
    if (access != GpsAccess.granted) {
      setState(() {
        _locating = false;
        _gpsError = _accessMessage(access);
      });
      if (access == GpsAccess.serviceDisabled || access == GpsAccess.deniedForever) {
        await promptGpsUnblock(context, _tracking, access);
      }
      return;
    }
    final pos = await _tracking.currentPosition();
    if (!mounted) return;
    setState(() {
      _position = pos;
      _locating = false;
      if (pos == null) _gpsError = 'Unable to get your current GPS location. Please check GPS/location services.';
      _recomputeDistance();
    });
    _syncRoute();
  }

  String _accessMessage(GpsAccess access) => switch (access) {
        GpsAccess.serviceDisabled =>
          'Device location (GPS) is switched off. Turn it on to start live tracking.',
        GpsAccess.denied =>
          'Location permission is required to start live tracking. Please allow location access in settings.',
        GpsAccess.deniedForever =>
          'Location permission is blocked for this app. Allow it in app settings to start live tracking.',
        GpsAccess.unavailable => 'Geolocation is not available on this device right now.',
        GpsAccess.granted => '',
      };

  void _recomputeDistance() {
    final venue = _venueOf();
    if (venue == null || _position == null) {
      _distanceM = null;
      return;
    }
    _distanceM = Geolocator.distanceBetween(
      _position!.latitude,
      _position!.longitude,
      venue.latitude,
      venue.longitude,
    );
  }

  /// Keeps the drawn route in sync with the current trip. Refetches only when
  /// the trip changed or the origin moved about a kilometre (web parity with
  /// `useLiveGps.js`, which draws the OSRM road route between the two points).
  void _syncRoute() {
    if (!mounted) return;
    final venue = _venueOf();
    final pos = _position;
    if (venue == null || pos == null || _selectedId == null) {
      if (_routePoints != null || _routeKey != null) {
        setState(() {
          _routePoints = null;
          _routeKey = null;
        });
      }
      return;
    }
    final key = '$_selectedId|${venue.latitude.toStringAsFixed(3)},'
        '${venue.longitude.toStringAsFixed(3)}|${pos.latitude.toStringAsFixed(2)},'
        '${pos.longitude.toStringAsFixed(2)}';
    if (key == _routeKey) return;
    _routeKey = key;
    _fetchRoute(LatLng(pos.latitude, pos.longitude), venue);
  }

  /// `https://router.project-osrm.org/route/v1/bike/…` — the same endpoint and
  /// profile the web dashboard uses to render the turn-by-turn route line.
  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/bike/${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}?overview=full&geometries=geojson');
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (!mounted || res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      final routes = body is Map<String, dynamic> ? body['routes'] : null;
      if (routes is! List || routes.isEmpty) return;
      final geometry = routes.first is Map<String, dynamic> ? routes.first['geometry'] : null;
      final coords = geometry is Map<String, dynamic> ? geometry['coordinates'] : null;
      if (coords is! List) return;
      final points = <LatLng>[
        for (final c in coords)
          if (c is List && c.length >= 2 && c[0] is num && c[1] is num)
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      if (points.length < 2) return;
      setState(() => _routePoints = points);
    } catch (_) {
      // Offline or OSRM unreachable → keep the dashed straight line fallback,
      // exactly like the web dashboard's catch branch.
    }
  }

  /// Web `START JOURNEY`: grab a high accuracy fix, start the live stream and
  /// push the ceremony to `en_route`.
  Future<void> _startJourney(Booking booking, {bool advanceStage = true}) async {
    if (!_sharing) {
      setState(() {
        _locating = true;
        _gpsError = null;
      });
      showAppToast(context, 'Acquiring device GPS location… Please allow location access.',
          type: ToastType.info, title: 'Live GPS');
      final access = await _tracking.requestAccess();
      if (!mounted) return;
      if (access != GpsAccess.granted) {
        setState(() {
          _locating = false;
          _gpsError = _accessMessage(access);
        });
        if (access == GpsAccess.serviceDisabled || access == GpsAccess.deniedForever) {
          await promptGpsUnblock(context, _tracking, access);
        } else {
          showAppToast(context, _accessMessage(access), type: ToastType.error, title: 'Location Blocked');
        }
        return;
      }
      final pos = await _tracking.currentPosition();
      if (!mounted) return;
      if (pos == null) {
        setState(() {
          _locating = false;
          _gpsError = 'Unable to get your current GPS location. Please check GPS/location services.';
        });
        showAppToast(context, 'Could not lock your GPS fix. Move to an open area and try again.',
            type: ToastType.error, title: 'GPS Fix Failed');
        return;
      }
      setState(() {
        _position = pos;
        _sharing = true;
        _locating = false;
      });
      PanditTrackingService.broadcasting = true;
      _recomputeDistance();
      _syncRoute();
      final startedOk = await _tracking.startJourney(booking.bookingId, pos);
      final sentOk = await _tracking.sendLocation(
          booking.bookingId, pos,
          status: _stageId(booking));
      _shareTimer?.cancel();
      _shareTimer = Timer.periodic(const Duration(seconds: 12), (_) => _tick(booking));
      if (!mounted) return;
      if (startedOk || sentOk) {
        showAppToast(context, 'Journey started — devotee and admin now receive your live location stream.',
            type: ToastType.success, title: 'Live Telemetry');
      } else {
        showAppToast(
            context,
            'GPS is on, but the location server did not confirm the stream. '
            'Your stage was still advanced — check network and retry Live GPS if the map stays empty.',
            type: ToastType.warning, title: 'Live Telemetry');
      }
    }
    if (advanceStage) await _advance(booking, 'en_route');
  }

  /// Web `Stop Tracking`: ends the stream but keeps the ceremony stage.
  Future<void> _stopTracking(Booking booking) async {
    _shareTimer?.cancel();
    _shareTimer = null;
    PanditTrackingService.broadcasting = false;
    if (mounted) setState(() => _sharing = false);
    final ok = await _tracking.stopTracking(booking.bookingId, status: _stageId(booking));
    if (!mounted) return;
    showAppToast(
        context,
        ok
            ? 'Live GPS journey completed.'
            : 'Live GPS stopped on this device. The server did not confirm — please retry if needed.',
        type: ok ? ToastType.info : ToastType.warning,
        title: 'Live GPS');
  }

  /// Flip the local share flag. Turning it off only pauses client-side sends;
  /// the real end-of-journey is [_stopTracking].
  void _toggleBroadcast() {
    setState(() => _broadcasting = !_broadcasting);
    if (_broadcasting) {
      showAppToast(
        context,
        'Live telemetry broadcasting resumed — each 12-second GPS tick is sent to the devotee & admin.',
        type: ToastType.success,
        title: 'Broadcasting',
      );
    } else {
      showAppToast(
        context,
        'Broadcasting paused on this device. GPS is still on — use Stop Tracking to end the live stream.',
        type: ToastType.warning,
        title: 'Broadcasting',
      );
    }
  }

  Future<void> _tick(Booking booking) async {
    final pos = await _tracking.currentPosition();
    if (!mounted || pos == null) return;
    // Always refresh the latest ceremony stage from the provider — the
    // [booking] captured when the timer started goes stale as soon as the
    // acharya advances stages on another screen.
    final latest = context
        .read<AssignmentsProvider>()
        .acceptedBookings
        .where((b) => '${b.bookingId}' == '${booking.bookingId}')
        .toList();
    final stage = _stageId(latest.isNotEmpty ? latest.first : booking);
    setState(() {
      _position = pos;
      _recomputeDistance();
    });
    _syncRoute();
    if (!_broadcasting) return;
    await _tracking.sendLocation(booking.bookingId, pos, status: stage);
  }

  String _stageId(Booking b) => CeremonyStage.all[CeremonyStage.indexOf(b)].id;

  Future<void> _advance(Booking booking, String stage) async {
    final error = await context.read<AssignmentsProvider>().advanceStage(booking, stage);
    if (!mounted) return;
    if (error != null) {
      showAppToast(context, error, type: ToastType.error, title: 'Stage Update');
      return;
    }
    showAppToast(context, AssignmentsProvider.stageLabels[stage] ?? 'Stage updated.',
        type: ToastType.success, title: 'Ceremony');
    if (stage == 'en_route' && !_sharing) {
      if (!mounted) return;
      final refreshed = context.read<AssignmentsProvider>().acceptedBookings
          .where((b) => '${b.bookingId}' == '${booking.bookingId}');
      await _startJourney(refreshed.isNotEmpty ? refreshed.first : booking, advanceStage: false);
    }
  }

  /// One-tap stage sync — never regresses a ceremony to an earlier stage.
  void _pressStage(Booking booking, int stageIndex, int targetIndex) {
    if (targetIndex < stageIndex) return;
    if (targetIndex == 1) {
      _startJourney(booking, advanceStage: stageIndex < 1);
      return;
    }
    _advance(booking, CeremonyStage.all[targetIndex].id);
  }

  Future<void> _endPuja(Booking booking) async {
    final confirmed = await confirmEndPuja(context, booking);
    if (!confirmed || !mounted) return;
    _shareTimer?.cancel();
    _shareTimer = null;
    PanditTrackingService.broadcasting = false;
    setState(() => _sharing = false);
    final error = await context.read<AssignmentsProvider>().completeCeremony(booking);
    await _tracking.stopTracking(booking.bookingId, status: 'completed');
    if (!mounted) return;
    if (error != null) {
      showAppToast(context, error, type: ToastType.error, title: 'End Puja');
      return;
    }
    showAppToast(context, AssignmentsProvider.stageLabels['completed']!,
        type: ToastType.success, title: 'Puja Completed');
  }

  void _fitRoute(LatLng? venue) {
    try {
      // Fit the whole drawn route (web "Fit Route" fits the OSRM bounds).
      final pts = _routePoints != null && _routePoints!.length > 1
          ? _routePoints!
          : <LatLng>[
              if (_position != null) LatLng(_position!.latitude, _position!.longitude),
              ?venue,
            ];
      if (pts.length >= 2) {
        _mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(pts),
          padding: const EdgeInsets.all(50),
        ));
        return;
      }
      if (venue != null) {
        _mapController.move(venue, 16);
      } else if (_position != null) {
        _mapController.move(LatLng(_position!.latitude, _position!.longitude), 16);
      }
    } catch (_) {
      // Map not laid out yet.
    }
  }

  LatLng? _venueOf() {
    if (!mounted) return null;
    final bookings = _bookings(context.read<AssignmentsProvider>());
    Booking? selected;
    for (final b in bookings) {
      if ('${b.bookingId}' == _selectedId) {
        selected = b;
        break;
      }
    }
    selected ??= bookings.isEmpty ? null : bookings.first;
    final lat = selected?.latitude;
    final lng = selected?.longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  // ── Display helpers ────────────────────────────────────────────────

  String get _digits {
    final b = _selectedBooking;
    if (b == null) return '8842';
    final digits = Booking.normalizeIdString(b.bookingId);
    return digits.isEmpty ? '8842' : digits;
  }

  String get _pin {
    final d = _digits;
    return d.length >= 4 ? d.substring(d.length - 4) : d.padLeft(4, '0');
  }

  Booking? get _selectedBooking {
    if (!mounted) return null;
    final bookings = _bookings(context.read<AssignmentsProvider>());
    for (final b in bookings) {
      if ('${b.bookingId}' == _selectedId) return b;
    }
    return bookings.isEmpty ? null : bookings.first;
  }

  double? get _accuracy => _position?.accuracy.isFinite == true ? _position!.accuracy : null;

  double get _speedKmph {
    final s = _position?.speed;
    if (s == null || !s.isFinite || s < 0) return 0;
    return (s * 3.6).roundToDouble();
  }

  String get _distanceLabel {
    final d = _distanceM;
    if (d == null) return '—';
    if (d <= 80) return '0 m';
    return '${(d / 1000).toStringAsFixed(1)} km';
  }

  String get _etaLabel {
    final d = _distanceM;
    if (d == null) return '—';
    if (d <= 80) return 'Arrived';
    final speed = _speedKmph > 15 ? _speedKmph : 30;
    final mins = ((d / 1000) / speed * 60).ceil();
    return mins > 0 ? '$mins Mins' : '1 Min';
  }

  String get _headingLabel {
    final h = _position?.heading;
    if (h == null || !h.isFinite) return '—';
    return '${h.round()}°';
  }

  String _hudStatus() {
    if (_locating) return 'Fetching your current location...';
    if (_position == null) return 'Standby';
    if (_distanceM != null && _distanceM! <= 80) return '🏠 Arrived at Devotee Venue';
    if (!_broadcasting) return '⏸️ GPS Telemetry Paused';
    if (_sharing) return '🟢 Live GPS (±${_accuracy?.round() ?? 10}m)';
    return 'Standby';
  }

  String _modeLabel() {
    if (_locating) return 'Acquiring GPS...';
    if (_sharing && _position != null) return 'Real GPS (±${_accuracy?.round() ?? 10}m)';
    return 'Standby (Base Profile)';
  }

  String _statusChipLabel() {
    if (_locating) return '⏳ Acquiring GPS...';
    if (_sharing && _broadcasting && _position != null) {
      return '🟢 Live GPS${_accuracy != null ? ' (±${_accuracy!.round()}m)' : ''}';
    }
    return 'Standby';
  }

  // ── Screen ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AssignmentsProvider>();
    final bookings = _bookings(a);
    final profile = context.watch<PanditProfileProvider>().profile;

    if (bookings.isEmpty) return _emptyPane();

    final booking = bookings.firstWhere(
      (b) => '${b.bookingId}' == _selectedId,
      orElse: () => bookings.first,
    );
    if (!bookings.any((b) => '${b.bookingId}' == _selectedId)) {
      _selectedId = '${booking.bookingId}';
    }
    final stageIndex = CeremonyStage.indexOf(booking);
    final busy = a.processingId == '${booking.bookingId}';
    final stageBusy = busy && a.processingAction == 'stage';
    final endBusy = busy && a.processingAction == 'end';
    final venue = (booking.latitude != null && booking.longitude != null)
        ? LatLng(booking.latitude!, booking.longitude!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _headerCard(),
          const SizedBox(height: 12),
          _controlsCard(bookings, booking),
          const SizedBox(height: 12),
          _destinationCard(booking),
          const SizedBox(height: 12),
          _stageCard(booking, stageIndex, stageBusy, endBusy),
          const SizedBox(height: 12),
          _mapCard(venue, profile?.latitude, profile?.longitude),
        ],
      ),
    );
  }

  Widget _emptyPane() {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          SectionCard(
            title: 'Live Ceremony GPS Navigation',
            icon: Icons.podcasts_outlined,
            iconColor: AppColors.danger,
            subtitle: 'Real-time GPS telemetry is active only for confirmed, non-completed ceremonies.',
            borderColor: AppColors.info,
            child: EmptyState(
              icon: Icons.cell_tower_outlined,
              title: 'No Active Ceremonies to Navigate',
              subtitle:
                  'Live GPS navigation will appear here when you accept a puja request and begin an active ceremony journey.',
              actionLabel: 'View Puja Schedule',
              onAction: () => widget.onNavigate(AppTab.schedule),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cockpit cards ──────────────────────────────────────────────────

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore, size: 11, color: Colors.white),
                    SizedBox(width: 4),
                    Text('ACHARYA COCKPIT',
                        style: TextStyle(
                            color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.9)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  'Ref #$_digits',
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9A3412)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.podcasts_rounded, size: 17, color: AppColors.danger),
              SizedBox(width: 6),
              Expanded(
                child: Text('Live Ceremony GPS Navigation',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Real-time device GPS telemetry broadcasting directly to Devotee & Super Admin operations console.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statusChip(),
              const Spacer(),
              _smallButton(
                label: 'Fit Route',
                icon: Icons.fullscreen_rounded,
                onTap: () => _fitRoute(_venueOf()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip() {
    final active = _sharing && _broadcasting && _position != null;
    final color = active
        ? AppColors.success
        : _locating
            ? AppColors.warning
            : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _statusChipLabel(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _smallButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: _slate50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _slate200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: _slate700),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _slate700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlsCard(List<Booking> bookings, Booking booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECT ACTIVE CEREMONY:',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: _slate700)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _slate200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedId,
                items: bookings
                    .map((b) => DropdownMenuItem(
                          value: '${b.bookingId}',
                          child: Text(
                            '${b.displayId} — ${b.ceremony ?? 'Puja'} (${b.fullName ?? 'Devotee'})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                          ),
                        ))
                    .toList(),
                onChanged: _select,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _journeyControls(booking)),
              const SizedBox(width: 8),
              _broadcastButton(),
            ],
          ),
          if (_gpsError != null) ...[
            const SizedBox(height: 12),
            _gpsErrorAlert(booking),
          ],
          const SizedBox(height: 12),
          _coordinatesBanner(),
        ],
      ),
    );
  }

  Widget _journeyControls(Booking booking) {
    if (!_sharing) {
      return SizedBox(
        height: 46,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentHover]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 5)),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _locating ? null : () => _startJourney(booking),
              child: Container(
                alignment: Alignment.center,
                child: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_filled, size: 16, color: AppColors.primary),
                          SizedBox(width: 7),
                          Text('START JOURNEY',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: AppColors.primary)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 14, color: Color(0xFF059669)),
                SizedBox(width: 6),
                Text('Journey Started',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _stopTracking(booking),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDA4AF)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop_circle_outlined, size: 15, color: Color(0xFFBE123C)),
                  SizedBox(width: 5),
                  Text('Stop Tracking',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFFBE123C))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _broadcastButton() {
    final on = _broadcasting;
    return Material(
      color: on ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _toggleBroadcast,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3)),
          ),
          child: Icon(
            on ? Icons.cell_tower : Icons.sensors_off,
            size: 19,
            color: on ? AppColors.successDark : AppColors.danger,
          ),
        ),
      ),
    );
  }

  Widget _gpsErrorAlert(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 17, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GPS Location Error:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.danger)),
                const SizedBox(height: 2),
                Text(_gpsError!,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF9F1239), height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => _startJourney(booking),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: const Text('Retry GPS',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordinatesBanner() {
    final profile = context.watch<PanditProfileProvider>().profile;
    final device = _position;
    final lat = device?.latitude ?? profile?.latitude;
    final lon = device?.longitude ?? profile?.longitude;
    final source = device != null
        ? ('Live Device GPS', AppColors.success)
        : profile?.latitude != null
            ? ('pandit_profile table', AppColors.info)
            : ('Awaiting GPS', const Color(0xFF64748B));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _amber50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Text('📍', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PANDIT COORDINATES (PANDIT_PROFILE / GPS)',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                        color: Color(0xFF92400E))),
                const SizedBox(height: 5),
                if (lat != null && lon != null)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _coordChip('Lat: ${lat.toStringAsFixed(5)}'),
                      _coordChip('Lon: ${lon.toStringAsFixed(5)}'),
                    ],
                  )
                else
                  const Text('Acquiring coordinates...',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: source.$2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: source.$2.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: source.$2, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(source.$1,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: source.$2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _amber200),
      ),
      child: Text(label,
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textDark)),
    );
  }

  Widget _destinationCard(Booking booking) {
    final address = [booking.address ?? booking.addressLine1, booking.city]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
    final gotram = (booking.gothram ?? '').isEmpty ? 'Kashyapa' : booking.gothram!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFBEB), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: const Text('🪔', style: TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(booking.ceremony ?? 'Puja',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF6EE7B7)),
                          ),
                          child: Text('Dakshina: ${booking.priceDisplay}',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                        children: [
                          const TextSpan(text: 'Yajamana: '),
                          TextSpan(
                            text: booking.fullName ?? 'Devotee',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
                          ),
                          TextSpan(text: ' ($gotram Gotra)'),
                        ],
                      ),
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 13, color: AppColors.danger),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11.5, color: AppColors.textMuted, height: 1.35)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _amber200),
                ),
                child: Column(
                  children: [
                    const Text('SANKALPA PIN',
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Color(0xFFB45309))),
                    const SizedBox(height: 2),
                    Text(_pin,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: AppColors.textDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  label: 'Call',
                  icon: Icons.call_rounded,
                  color: const Color(0xFF059669),
                  onTap: () async {
                    final phone = (booking.mobile ?? '').trim();
                    if (phone.isEmpty) {
                      showAppToast(context, 'Devotee mobile number is not available yet.',
                          type: ToastType.warning, title: 'Call Devotee');
                      return;
                    }
                    final ok = await callDevotee(phone);
                    if (!ok && mounted) {
                      showAppToast(context, 'Unable to open the dialer. Try again.',
                          type: ToastType.error, title: 'Call Devotee');
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _contactButton(
                  label: 'WhatsApp',
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF059669),
                  filled: true,
                  onTap: () async {
                    final phone = (booking.mobile ?? '').trim();
                    if (phone.isEmpty) {
                      showAppToast(context, 'Devotee mobile number is not available yet.',
                          type: ToastType.warning, title: 'WhatsApp');
                      return;
                    }
                    final ok = await whatsappDevotee(
                      phone,
                      'Namaste Ji, Acharya is en route for your ${booking.ceremony ?? 'puja'}.',
                    );
                    if (!ok && mounted) {
                      showAppToast(context, 'Unable to open WhatsApp. Try again.',
                          type: ToastType.error, title: 'WhatsApp');
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _contactButton(
              label: 'Open Route in Maps',
              icon: Icons.directions_rounded,
              color: AppColors.accent,
              filled: true,
              onTap: () => openMaps([
                if (_venueOf() != null) '${_venueOf()!.latitude},${_venueOf()!.longitude}',
                address,
              ].where((s) => s.isNotEmpty).join(', ')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Material(
      color: filled ? color : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: filled ? Colors.transparent : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: filled ? Colors.white : color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w900, color: filled ? Colors.white : color)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stageCard(Booking booking, int stageIndex, bool stageBusy, bool endBusy) {
    final specs = [
      (1, '1. Start Journey', Icons.directions_car_filled, const Color(0xFF2563EB)),
      (2, '2. Arrived', Icons.home_rounded, const Color(0xFF059669)),
      (3, '3. Start Puja', Icons.local_fire_department_rounded, const Color(0xFFD97706)),
      (4, '4. Aarti', Icons.wb_sunny_rounded, const Color(0xFF7C3AED)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('LIVE RITUAL STAGE PROGRESSION:',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: _slate700)),
              ),
              Text('1-Click Live Stage Sync',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (index, label, icon, color) in specs)
                _stageButton(
                  label: label,
                  icon: icon,
                  color: color,
                  active: stageIndex == index,
                  disabled: stageBusy || stageIndex >= 5,
                  busy: stageBusy && stageIndex == index,
                  onTap: () => _pressStage(booking, stageIndex, index),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _stageButton(
              label: '5. End Puja',
              icon: Icons.stop_circle_rounded,
              color: const Color(0xFFE11D48),
              active: stageIndex == 5,
              filled: true,
              disabled: endBusy || stageIndex >= 5,
              busy: endBusy,
              wide: true,
              onTap: () => _endPuja(booking),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool active = false,
    bool filled = false,
    bool disabled = false,
    bool busy = false,
    bool wide = false,
  }) {
    final paintFilled = filled || active;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: paintFilled ? color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled ? null : onTap,
          child: Container(
            width: wide ? double.infinity : null,
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: paintFilled ? color : color.withValues(alpha: 0.45)),
            ),
            child: busy
                ? SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: paintFilled ? Colors.white : color))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 14, color: paintFilled ? Colors.white : color),
                      const SizedBox(width: 5),
                      Text(label,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: paintFilled ? Colors.white : color)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Map + telemetry HUD ────────────────────────────────────────────

  Widget _mapCard(LatLng? venue, double? profileLat, double? profileLon) {
    final center = venue ??
        (_position != null
            ? LatLng(_position!.latitude, _position!.longitude)
            : (profileLat != null && profileLon != null
                ? LatLng(profileLat, profileLon)
                : _india));

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 380,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            _map(center, venue),
            Positioned(
              top: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modePill(),
                  if (_position != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xD9020617),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: const Color(0x4DFBBF24)),
                      ),
                      child: Text(
                        'Lat: ${_position!.latitude.toStringAsFixed(4)}, Lon: ${_position!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFCD34D)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _slate200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_outlined, size: 14, color: AppColors.accent),
                    const SizedBox(width: 5),
                    Text(_headingLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 74,
              right: 12,
              child: Column(
                children: [
                  _mapButton(
                    icon: _darkTiles ? Icons.map_outlined : Icons.dark_mode_outlined,
                    onTap: () => setState(() => _darkTiles = !_darkTiles),
                  ),
                  const SizedBox(height: 8),
                  _mapButton(icon: Icons.my_location_rounded, onTap: () => _locate(force: true)),
                  const SizedBox(height: 8),
                  _mapButton(icon: Icons.fullscreen_rounded, onTap: () => _fitRoute(venue)),
                ],
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: _hudStrip(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modePill() {
    final active = _sharing && _position != null;
    final color = _locating
        ? const Color(0xFFFBBF24)
        : active
            ? const Color(0xFF34D399)
            : const Color(0xFF94A3B8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xE60F172A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(_modeLabel(),
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  /// Pandit coordinates for the HUD: live device fix first, then the stored
  /// pandit_profile / booking coordinates so the cell mirrors the web
  /// dashboard's Pandit Coordinates panel instead of showing "—".
  String _panditCoordsLabel() {
    if (_position != null) {
      return '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}';
    }
    final profile = context.read<PanditProfileProvider>().profile;
    final booking = _selectedBooking;
    final lat = profile?.latitude ?? booking?.panditLatitude;
    final lon = profile?.longitude ?? booking?.panditLongitude;
    if (lat != null && lon != null) {
      return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
    }
    return '—';
  }

  Widget _hudStrip() {
    final List<(String, String, Color)> cells = [
      ('Estimated ETA', _etaLabel, Colors.white),
      ('Distance Remaining', _distanceLabel, Colors.white),
      ('Current Speed', '${_speedKmph.round()} km/h', const Color(0xFF34D399)),
      (
        'Pandit Lat / Lon',
        _panditCoordsLabel(),
        const Color(0xFFFCD34D)
      ),
      ('Telemetry Status', _hudStatus(), const Color(0xFFFCD34D)),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xF20F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DFBBF24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final perRow = constraints.maxWidth >= 560 ? 5 : 2;
          final rows = <List<(String, String, Color)>>[];
          for (var i = 0; i < cells.length; i += perRow) {
            final end = i + perRow > cells.length ? cells.length : i + perRow;
            rows.add(cells.sublist(i, end));
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                Row(
                  children: [
                    for (final cell in rows[r]) Expanded(child: _hudCell(cell)),
                  ],
                ),
                if (r != rows.length - 1) const SizedBox(height: 4),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _hudCell((String label, String value, Color color) cell) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cell.$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFFFBBF24)),
          ),
          const SizedBox(height: 2),
          Text(
            cell.$2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: cell.$2.length > 22 ? 10.5 : 12.5,
                fontWeight: FontWeight.w900,
                color: cell.$3),
          ),
        ],
      ),
    );
  }

  Widget _map(LatLng center, LatLng? venue) {
    final markers = <Marker>[
      if (venue != null)
        Marker(
          point: venue,
          width: 46,
          height: 56,
          child: const _VenuePin(),
        ),
      if (_position != null)
        Marker(
          point: LatLng(_position!.latitude, _position!.longitude),
          width: 46,
          height: 46,
          child: const _AcharyaDot(),
        ),
    ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: venue != null ? 15 : (_position != null ? 15 : 6),
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: _darkTiles
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: _darkTiles ? const ['a', 'b', 'c', 'd'] : const <String>[],
          userAgentPackageName: 'com.panditindia.acharya',
          retinaMode: _darkTiles ? RetinaMode.isHighDensity(context) : false,
          // Tiles pruned while the camera moves are aborted mid-flight; on
          // the web that surfaces as an unmapped DOMException "AbortError"
          // for every tile. Aborted/failed fetches render a transparent tile
          // instead of spamming the console.
          tileProvider: NetworkTileProvider(silenceExceptions: true),
        ),
        if (venue != null && _position != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints != null && _routePoints!.length > 1
                    ? _routePoints!
                    : [
                        LatLng(_position!.latitude, _position!.longitude),
                        venue,
                      ],
                strokeWidth: 5,
                color: const Color(0xFFFF8C00),
                pattern: _routePoints != null && _routePoints!.length > 1
                    ? const StrokePattern.solid()
                    : StrokePattern.dashed(segments: const [6, 8]),
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap / CARTO contributors'),
          ],
        ),
      ],
    );
  }

  Widget _mapButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _VenuePin extends StatelessWidget {
  const _VenuePin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            color: Color(0xFFE11D48),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x66E11D48), blurRadius: 10)],
          ),
          child: const Icon(Icons.home_rounded, size: 18, color: Colors.white),
        ),
        Transform.translate(
          offset: const Offset(0, -3),
          child: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFFE11D48)),
        ),
      ],
    );
  }
}

class _AcharyaDot extends StatelessWidget {
  const _AcharyaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.directions_walk_rounded, size: 18, color: AppColors.primary),
      ),
    );
  }
}
