class AppNotification {
  AppNotification({
    this.id,
    this.title,
    this.message,
    this.type,
    this.isRead = false,
    this.bookingId,
    this.createdAt,
  });

  final int? id;
  final String? title;
  final String? message;
  final String? type;
  final bool isRead;
  final int? bookingId;
  final String? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final isReadRaw = json['is_read'];
    final unreadRaw = json['unread'];
    return AppNotification(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      title: json['title']?.toString(),
      message: (json['message'] ?? json['text'])?.toString(),
      type: json['type']?.toString(),
      isRead: unreadRaw is bool
          ? !unreadRaw
          : (isReadRaw is int ? isReadRaw == 1 : (isReadRaw is bool ? isReadRaw : false)),
      bookingId: json['booking_id'] is int ? json['booking_id'] as int : int.tryParse('${json['booking_id']}'),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class SupportTicket {
  SupportTicket({
    this.id,
    this.ticketId,
    this.category,
    this.status,
    this.priority,
    this.message,
    this.reply,
    this.coordinator,
    this.createdAt,
  });

  final int? id;
  final String? ticketId;
  final String? category;
  final String? status;
  final String? priority;
  final String? message;
  final String? reply;
  final String? coordinator;
  final String? createdAt;

  String get displayId => ticketId ?? (id != null ? 'TKT-$id' : '-');

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
        ticketId: json['ticket_id']?.toString(),
        category: json['category']?.toString(),
        status: json['status']?.toString(),
        priority: json['priority']?.toString(),
        message: json['message']?.toString(),
        reply: json['reply']?.toString(),
        coordinator: json['coordinator']?.toString(),
        createdAt: json['created_at']?.toString(),
      );
}

class SavedAddress {
  SavedAddress({
    this.id = '',
    this.label,
    this.address = '',
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
  });

  String id;
  String? label;
  String address;
  String? city;
  String? state;
  String? pincode;
  double? latitude;
  double? longitude;

  String get fullDisplay {
    final parts = [address, city, state, pincode].where((p) => p != null && p.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: json['label']?.toString(),
        address: json['address']?.toString() ?? '',
        city: json['city']?.toString(),
        state: json['state']?.toString(),
        pincode: json['pincode']?.toString(),
        latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
        longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
      };
}
