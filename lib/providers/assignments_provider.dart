import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/pandit_service.dart';
import '../services/tracking_service.dart';

class AssignmentsProvider extends ChangeNotifier {
  AssignmentsProvider();

  final PanditBookingService _service = PanditBookingService();
  final PanditService _panditService = PanditService();
  final PanditTrackingService _tracking = PanditTrackingService();

  List<Booking> bookings = [];
  bool loading = false;
  String panditName = '';
  String? processingId;
  String? processingAction;
  Timer? _pollTimer;

  static const stageLabels = <String, String>{
    'en_route': '🚗 Journey Started — Live location sharing is active.',
    'arrived': '📍 Reached Location — the devotee now sees “Reached Mandap”.',
    'in_progress': '🔥 Live Puja started.',
    'aarti': '✨ Purna Ahuti & Maha Aarti in progress.',
    'completed': '✅ Puja completed successfully. Live tracking has ended.',
  };

  List<Booking> get pendingRequests => bookings
      .where((b) =>
          !b.isAccepted &&
          !b.isCompleted &&
          !b.isCancelled &&
          (b.panditAcceptance ?? 'pending') != 'declined')
      .toList();

  /// Mirrors web `isBookingTrackable` (usePanditBookings.js) exactly:
  /// case-insensitive accepted, excluding completed / cancelled / declined
  /// statuses — keeps the Live GPS ceremony dropdown in sync with web.
  List<Booking> get acceptedBookings => bookings.where((b) {
        final status = (b.rawStatus ?? b.status ?? '').toLowerCase();
        final acceptance = (b.panditAcceptance ?? '').toLowerCase();
        if (acceptance != 'accepted') return false;
        if (status.contains('complete')) return false;
        if (status.contains('cancel')) return false;
        if (status.contains('declin')) return false;
        return true;
      }).toList();

  Booking? get currentRitual {
    for (final b in acceptedBookings) {
      final s = (b.rawStatus ?? '').toLowerCase();
      if (s.contains('progress') ||
          s.contains('route') ||
          s.contains('arrived') ||
          s.contains('aarti') ||
          s.contains('live')) {
        return b;
      }
    }
    for (final b in acceptedBookings) {
      if (_isInCeremonyWindow(b)) return b;
    }
    return null;
  }

  List<Booking> get upcomingBookings {
    final current = currentRitual;
    return acceptedBookings.where((b) => current == null || b.bookingId != current.bookingId).toList()
      ..sort((a, b) => (a.bookingDate ?? '').compareTo(b.bookingDate ?? ''));
  }

  List<Booking> get completedBookings {
    final list = bookings.where((b) => b.isCompleted).toList()
      ..sort((a, b) => (b.bookingDate ?? '').compareTo(a.bookingDate ?? ''));
    return list;
  }

  int get activeCount => acceptedBookings.length;
  int get pendingCount => pendingRequests.length;
  int get completedCount => completedBookings.length;

  double get totalDakshina => completedBookings.fold<double>(
      0, (sum, b) => sum + (b.price ?? 0));

  bool _isInCeremonyWindow(Booking b) {
    final date = DateTime.tryParse(b.bookingDate ?? '');
    if (date == null) return false;
    final now = DateTime.now();
    if (date.year != now.year || date.month != now.month || date.day != now.day) return false;
    final window = _parseWindow(b.timeSlot);
    final minutes = now.hour * 60 + now.minute;
    return minutes >= window.$1 && minutes <= window.$2;
  }

  (int, int) _parseWindow(String? slot) {
    final matches = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false).allMatches(slot ?? '').toList();
    int toMinutes(Match m) {
      var h = int.parse(m.group(1)!);
      final min = int.parse(m.group(2)!);
      final meridiem = (m.group(3) ?? '').toUpperCase();
      if (meridiem == 'PM' && h < 12) h += 12;
      if (meridiem == 'AM' && h == 12) h = 0;
      return h * 60 + min;
    }

    if (matches.length >= 2) {
      return (toMinutes(matches[0]), toMinutes(matches[1]));
    }
    return (8 * 60, 10 * 60);
  }

  Future<void> load({bool showSpinner = false}) async {
    if (showSpinner) {
      loading = true;
      notifyListeners();
    }
    try {
      final list = await _service.assignedBookings(panditName);
      // null = API unreachable (e.g. DB outage) → keep the last good list
      // instead of blanking the dashboard.
      if (list != null) bookings = list;
    } finally {
      // Always clear the spinner — a failed fetch must not wedge the
      // Refresh button in its busy state.
      loading = false;
      notifyListeners();
    }
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => load());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<String?> accept(Booking b) async {
    processingId = '${b.bookingId}';
    processingAction = 'accept';
    notifyListeners();
    final res = await _service.respondToAssignment(b.bookingId, action: 'accept');
    processingId = null;
    processingAction = null;
    if (res == null || res['success'] != true) {
      notifyListeners();
      return res?['message']?.toString() ?? 'Could not accept the request. Please try again.';
    }
    await load();
    return null;
  }

  Future<String?> decline(Booking b, {required String reason, String notes = ''}) async {
    processingId = '${b.bookingId}';
    processingAction = 'decline';
    notifyListeners();
    final fullReason = notes.isEmpty ? reason : '$reason - $notes';
    final res = await _service.respondToAssignment(
      b.bookingId,
      action: 'decline',
      reason: fullReason,
    );
    processingId = null;
    processingAction = null;
    if (res == null || res['success'] != true) {
      notifyListeners();
      return res?['message']?.toString() ?? 'Could not decline the request. Please try again.';
    }
    await load();
    return null;
  }

  Future<String?> advanceStage(Booking b, String stage) async {
    processingId = '${b.bookingId}';
    processingAction = 'stage';
    notifyListeners();
    final ok = await _service.updateStatus(b.bookingId, stage);
    processingId = null;
    processingAction = null;
    if (!ok) {
      notifyListeners();
      return 'Could not update the ceremony stage. Please try again.';
    }
    await load();
    return null;
  }

  Future<String?> completeCeremony(Booking b) async {
    processingId = '${b.bookingId}';
    processingAction = 'end';
    notifyListeners();
    final ok = await _service.updateStatus(b.bookingId, 'completed');
    if (ok) {
      await _tracking.stopTracking(b.bookingId, status: 'completed');
      await _panditService.setAvailability('available');
    }
    processingId = null;
    processingAction = null;
    if (!ok) {
      notifyListeners();
      return 'Could not complete the ceremony. Please try again.';
    }
    await load();
    return null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
