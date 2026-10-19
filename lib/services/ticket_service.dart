import '../core/network/api_client.dart';
import '../models/misc_models.dart';

class TicketService {
  Future<List<SupportTicket>> myTickets({String? email, int? userId}) async {
    try {
      final query = <String, String>{
        if (email != null && email.isNotEmpty) 'email': email,
        if (userId != null) 'user_id': '$userId',
      };
      final res = await ApiClient.get('/api/tickets/my', query: query.isEmpty ? null : query);
      final body = res.body;
      final list = body['tickets'];
      if (list is List) {
        return list.whereType<Map<String, dynamic>>().map(SupportTicket.fromJson).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<SupportTicket?> createTicket({
    required String name,
    required String email,
    required String mobile,
    required String category,
    required String message,
    String priority = 'Medium',
    int? userId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'email': email,
        'mobile': mobile,
        'category': category,
        'message': message,
        'priority': priority,
      };
      if (userId != null) payload['user_id'] = userId;
      final res = await ApiClient.post('/api/tickets', body: payload);
      final body = res.body;
      final ticket = body['ticket'];
      if (ticket is Map<String, dynamic>) return SupportTicket.fromJson(ticket);
      return null;
    } catch (_) {
      return null;
    }
  }
}
