import '../core/network/api_client.dart';
import '../models/misc_models.dart';

class NotificationService {
  Future<List<AppNotification>> list({required String recipientType, required String recipientId}) async {
    try {
      final res = await ApiClient.get(
        '/notifications',
        query: {'recipient_type': recipientType, 'recipient_id': recipientId},
      );
      final body = res.body;
      final list = body['notifications'];
      if (list is List) {
        return list.whereType<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> markRead(int id) async {
    try {
      final res = await ApiClient.patch('/notifications/$id/read');
      return res.body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllRead({required String recipientType, required String recipientId}) async {
    try {
      final res = await ApiClient.patch(
        '/notifications/mark-all-read',
        body: {'recipient_type': recipientType, 'recipient_id': recipientId},
      );
      return res.body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(int id) async {
    try {
      final res = await ApiClient.delete('/notifications/$id');
      return res.body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearAll({required String recipientType, required String recipientId}) async {
    try {
      final res = await ApiClient.delete(
        '/notifications/clear-all',
        query: {'recipient_type': recipientType, 'recipient_id': recipientId},
      );
      return res.body['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
