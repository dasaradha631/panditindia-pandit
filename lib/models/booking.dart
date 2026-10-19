import '../core/theme/app_theme.dart';

class Booking {
  Booking({
    this.bookingId,
    this.ceremony,
    this.price,
    this.priceRaw,
    this.samagri,
    this.ecokit,
    this.ecokitPrice,
    this.bookingDate,
    this.timeSlot,
    this.language,
    this.city,
    this.state,
    this.fullName,
    this.email,
    this.mobile,
    this.address,
    this.addressLine1,
    this.pincode,
    this.gothram,
    this.nakshatra,
    this.rashi,
    this.specialRequests,
    this.samagriNotes,
    this.latitude,
    this.longitude,
    this.status,
    this.rawStatus,
    this.assignedPandit,
    this.panditAcceptance,
    this.declineReason,
    this.panditPhone,
    this.panditCity,
    this.panditPhoto,
    this.panditVerified,
    this.panditExperience,
    this.panditVeda,
    this.distanceKm,
    this.etaMinutes,
    this.speedKmph,
    this.isTracking,
    this.panditLatitude,
    this.panditLongitude,
    this.createdAt,
    this.assignedAt,
    this.responseMessage,
  });

  final int? bookingId;
  final String? ceremony;
  final double? price;
  final String? priceRaw;
  final String? samagri;
  final String? ecokit;
  final double? ecokitPrice;
  final String? bookingDate;
  final String? timeSlot;
  final String? language;
  final String? city;
  final String? state;
  final String? fullName;
  final String? email;
  final String? mobile;
  final String? address;
  final String? addressLine1;
  final String? pincode;
  final String? gothram;
  final String? nakshatra;
  final String? rashi;
  final String? specialRequests;
  final String? samagriNotes;
  final double? latitude;
  final double? longitude;
  final String? status;
  final String? rawStatus;
  final String? assignedPandit;
  final String? panditAcceptance;
  final String? declineReason;
  final String? panditPhone;
  final String? panditCity;
  final String? panditPhoto;
  final bool? panditVerified;
  final String? panditExperience;
  final String? panditVeda;
  final double? distanceKm;
  final int? etaMinutes;
  final double? speedKmph;
  final bool? isTracking;
  final double? panditLatitude;
  final double? panditLongitude;
  final String? createdAt;
  final String? assignedAt;
  final String? responseMessage;

  String get displayId => AppStatus.displayBookingId(bookingId ?? '');

  static String normalizeIdString(dynamic id) => AppStatus.normalizeBookingId(id);

  String get displayStatus => AppStatus.displayStatus(rawStatus ?? status);

  bool get isAccepted => (panditAcceptance ?? 'pending') == 'accepted';

  bool get hasPandit => assignedPandit != null && assignedPandit!.isNotEmpty && assignedPandit != 'Unassigned';

  bool get isCompleted => (rawStatus ?? '').toLowerCase().contains('complete');
  bool get isCancelled => (rawStatus ?? '').toLowerCase().contains('cancel');
  bool get canReschedule {
    final s = (rawStatus ?? '').toLowerCase();
    if (s.contains('progress') || s.contains('route') || s.contains('live') || s.contains('arrived')) return false;
    if (s.contains('complete') || s.contains('cancel')) return false;
    return true;
  }

  String get priceDisplay {
    if (price != null) return Fmt.inr(price);
    return Fmt.inr(Fmt.parseAmount(priceRaw));
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final cleaned = v.toString().replaceAll(RegExp(r'[^\d.\-]'), '');
    return double.tryParse(cleaned);
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().replaceAll(RegExp(r'[^\d\-]'), ''));
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static String? _date(dynamic v) {
    final s = _str(v);
    if (s == null) return null;
    return s.split('T').first;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['booking_id'] ?? json['id']);
    final raw = _str(json['status']) ?? 'pending';

    String display;
    final lower = raw.toLowerCase();
    if (lower.contains('complete')) {
      display = 'Completed';
    } else if (lower.contains('cancel')) {
      display = 'Cancelled';
    } else if (lower.contains('pending_acceptance')) {
      display = 'Pending Acceptance';
    } else if (lower.contains('reassignment')) {
      display = 'Pending Reassignment';
    } else if (lower.contains('pending')) {
      display = 'Pending';
    } else if (lower.contains('progress') ||
        lower.contains('route') ||
        lower.contains('arrived') ||
        lower.contains('aarti') ||
        lower.contains('live')) {
      display = 'In Progress';
    } else {
      display = 'Confirmed';
    }

    var acharya = _str(json['assigned_pandit']);
    if (acharya == 'Unassigned') acharya = null;

    final telemetry = json['telemetry'] is Map<String, dynamic> ? json['telemetry'] as Map<String, dynamic> : null;

    return Booking(
      bookingId: id,
      ceremony: _str(json['ceremony']),
      price: _toDouble(json['price']),
      priceRaw: _str(json['price']),
      samagri: _str(json['samagri']),
      ecokit: _str(json['ecokit']),
      ecokitPrice: _toDouble(json['ecokit_price']),
      bookingDate: _date(json['booking_date'] ?? json['date']),
      timeSlot: _str(json['time_slot'] ?? json['timeSlot']),
      language: _str(json['language']),
      city: _str(json['city']),
      state: _str(json['state']),
      fullName: _str(json['full_name']),
      email: _str(json['email']),
      mobile: _str(json['mobile'] ?? json['phonenumber']),
      address: _str(json['address']),
      addressLine1: _str(json['address_line1']),
      pincode: _str(json['pincode']),
      gothram: _str(json['gothram'] ?? json['gotra']),
      nakshatra: _str(json['nakshatra']),
      rashi: _str(json['rashi']),
      specialRequests: _str(json['special_requests']),
      samagriNotes: _str(json['samagri_notes']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      status: display,
      rawStatus: raw,
      assignedPandit: acharya,
      panditAcceptance: _str(json['pandit_acceptance']) ?? 'pending',
      declineReason: _str(json['decline_reason']),
      panditPhone: _str(json['pandit_phone'] ?? json['panditProfile']?['phone']),
      panditCity: _str(json['pandit_city'] ?? json['pandit_location']?['city']),
      panditPhoto: _str(json['pandit_photo'] ?? json['pandit_profile']?['profile_photo_url']),
      panditVerified: json['pandit_verified'] is bool ? json['pandit_verified'] as bool : null,
      panditExperience: _str(json['pandit_experience']),
      panditVeda: _str(json['pandit_veda']),
      distanceKm: _toDouble(json['distance_km'] ?? telemetry?['distanceKm']),
      etaMinutes: _toInt(json['eta_minutes'] ?? telemetry?['etaMinutes']),
      speedKmph: _toDouble(json['speed_kmph'] ?? telemetry?['speedKmph']),
      isTracking: json['is_live_tracking'] is bool ? json['is_live_tracking'] as bool : null,
      panditLatitude: _toDouble(json['pandit_latitude'] ?? json['pandit_location']?['latitude']),
      panditLongitude: _toDouble(json['pandit_longitude'] ?? json['pandit_location']?['longitude']),
      createdAt: _str(json['created_at']),
      assignedAt: _str(json['assigned_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'booking_id': bookingId,
        'ceremony': ceremony,
        'price': priceRaw ?? price,
        'samagri': samagri,
        'ecokit': ecokit,
        'ecokit_price': ecokitPrice,
        'booking_date': bookingDate,
        'time_slot': timeSlot,
        'language': language,
        'city': city,
        'state': state,
        'full_name': fullName,
        'email': email,
        'mobile': mobile,
        'address': address,
        'address_line1': addressLine1,
        'pincode': pincode,
        'gothram': gothram,
        'nakshatra': nakshatra,
        'rashi': rashi,
        'special_requests': specialRequests,
        'samagri_notes': samagriNotes,
        'latitude': latitude,
        'longitude': longitude,
        'status': rawStatus,
        'assigned_pandit': assignedPandit,
        'pandit_acceptance': panditAcceptance,
        'decline_reason': declineReason,
        'pandit_phone': panditPhone,
        'pandit_city': panditCity,
        'pandit_photo': panditPhoto,
        'pandit_verified': panditVerified,
        'distance_km': distanceKm,
        'eta_minutes': etaMinutes,
        'created_at': createdAt,
        'assigned_at': assignedAt,
      };
}
