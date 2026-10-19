import '../core/network/api_client.dart';
import '../models/booking.dart';

class PanditBookingService {
  /// Returns `null` when BOTH endpoints fail (API down / DB unavailable) so
  /// callers can keep their previous list instead of wiping it to `[]`.
  Future<List<Booking>?> assignedBookings(String panditName) async {
    try {
      final res = await ApiClient.get(
        '/bookings/assigned',
        query: panditName.isEmpty ? null : {'pandit_name': panditName},
      );
      final body = res.body;
      final list = body['bookings'];
      if (body['success'] == true && list is List) {
        return list.whereType<Map<String, dynamic>>().map(Booking.fromJson).toList();
      }
      if (body['success'] != true) return null;
      return [];
    } catch (_) {
      try {
        final res = await ApiClient.get(
          '/pandit/bookings/assigned',
          query: panditName.isEmpty ? null : {'pandit_name': panditName},
        );
        final list = res.body['bookings'];
        if (list is List) {
          return list.whereType<Map<String, dynamic>>().map(Booking.fromJson).toList();
        }
      } catch (_) {}
      return null;
    }
  }

  Future<Map<String, dynamic>?> respondToAssignment(
    dynamic id, {
    required String action,
    String reason = '',
  }) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      final res = await ApiClient.patch(
        '/bookings/$numeric/pandit-response',
        body: {'action': action, 'reason': reason},
      );
      final body = res.body;
      if (body['success'] == true) return body;
      return null;
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateStatus(dynamic id, String status) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      final res = await ApiClient.patch(
        '/bookings/$numeric/status',
        body: {'status': status.toLowerCase()},
      );
      return res.body['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
