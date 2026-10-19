import '../core/network/api_client.dart';
import '../models/pandit_profile.dart';

class PanditService {
  Future<PanditProfile?> getProfile() async {
    try {
      final res = await ApiClient.get('/pandit/profile');
      final body = res.body;
      if (body['success'] == true && body['profile'] is Map<String, dynamic>) {
        return PanditProfile.fromJson(body['profile'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    try {
      final res = await ApiClient.put('/pandit/profile', body: payload);
      return res.body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setAvailability(String availability) async {
    try {
      final res = await ApiClient.patch('/pandit/status', body: {'availability': availability});
      return res.body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<DevoteeReview>> reviews() async {
    try {
      final res = await ApiClient.get('/pandit/reviews');
      final list = res.body['reviews'];
      if (list is List) {
        return list.whereType<Map<String, dynamic>>().map(DevoteeReview.fromJson).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
