import 'dart:convert';

class UserSession {
  UserSession({
    this.id,
    this.name,
    this.username,
    this.email,
    this.phone,
    this.role,
    this.token,
    this.gotra,
    this.kulaDevata,
    this.city,
    this.state,
  });

  final int? id;
  final String? name;
  final String? username;
  final String? email;
  final String? phone;
  final String? role;
  final String? token;
  final String? gotra;
  final String? kulaDevata;
  final String? city;
  final String? state;

  String get displayName {
    final n = (name ?? username ?? '').trim();
    if (n.isEmpty) return 'Devotee';
    return n.split(' ').first;
  }

  factory UserSession.fromLoginResponse(Map<String, dynamic> json) {
    return UserSession(
      id: json['user_id'] is int ? json['user_id'] as int : int.tryParse('${json['user_id']}'),
      name: json['username']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      phone: json['phonenumber']?.toString(),
      role: (json['role'] ?? 'user').toString(),
      token: json['token']?.toString(),
      gotra: json['gotra']?.toString(),
      kulaDevata: json['kula_devata']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
    );
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: (json['id'] ?? json['user_id']) is int
          ? (json['id'] ?? json['user_id']) as int
          : int.tryParse('${json['id'] ?? json['user_id']}'),
      name: (json['name'] ?? json['username'])?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      phone: (json['phone'] ?? json['phonenumber'])?.toString(),
      role: json['role']?.toString(),
      token: json['token']?.toString(),
      gotra: json['gotra']?.toString(),
      kulaDevata: json['kula_devata']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': id,
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'phonenumber': phone,
        'role': role,
        'token': token,
        'gotra': gotra,
        'kula_devata': kulaDevata,
        'city': city,
        'state': state,
        'loggedInAt': DateTime.now().toIso8601String(),
      };
}

class CustomerProfile {
  CustomerProfile({
    this.id,
    this.username,
    this.fullName,
    this.email,
    this.phonenumber,
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.pujaLanguage,
    this.gotra,
    this.kulaDevata,
    this.nakshatra,
    this.rashi,
    this.city,
    this.state,
    this.address,
    this.familyMembers,
    this.profilePhotoUrl,
    this.latitude,
    this.longitude,
    this.timezone,
  });

  final int? id;
  final String? username;
  final String? fullName;
  final String? email;
  final String? phonenumber;
  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? placeOfBirth;
  final String? pujaLanguage;
  final String? gotra;
  final String? kulaDevata;
  final String? nakshatra;
  final String? rashi;
  final String? city;
  final String? state;
  final String? address;
  final String? familyMembers;
  final String? profilePhotoUrl;
  final String? latitude;
  final String? longitude;
  final String? timezone;

  static String? _s(dynamic v) => v == null ? null : (v.toString().isEmpty ? null : v.toString());

  factory CustomerProfile.fromJson(Map<String, dynamic> json) => CustomerProfile(
        id: (json['id'] ?? json['user_id']) is int
            ? (json['id'] ?? json['user_id']) as int
            : int.tryParse('${json['id'] ?? json['user_id']}'),
        username: _s(json['username']),
        fullName: _s(json['full_name'] ?? json['username']),
        email: _s(json['email']),
        phonenumber: _s(json['phonenumber'] ?? json['phone']),
        dateOfBirth: _s(json['date_of_birth']),
        timeOfBirth: _s(json['time_of_birth']),
        placeOfBirth: _s(json['place_of_birth']),
        pujaLanguage: _s(json['puja_language']),
        gotra: _s(json['gotra']),
        kulaDevata: _s(json['kula_devata']),
        nakshatra: _s(json['nakshatra']),
        rashi: _s(json['rashi']),
        city: _s(json['city']),
        state: _s(json['state']),
        address: _s(json['address']),
        familyMembers: _s(json['family_members']),
        profilePhotoUrl: _s(json['profile_photo_url']),
        latitude: _s(json['latitude']),
        longitude: _s(json['longitude']),
        timezone: _s(json['timezone']),
      );

  Map<String, dynamic> toUpdatePayload() => {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (phonenumber != null) 'phonenumber': phonenumber,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (timeOfBirth != null) 'time_of_birth': timeOfBirth,
        if (placeOfBirth != null) 'place_of_birth': placeOfBirth,
        if (pujaLanguage != null) 'puja_language': pujaLanguage,
        if (gotra != null) 'gotra': gotra,
        if (kulaDevata != null) 'kula_devata': kulaDevata,
        if (nakshatra != null) 'nakshatra': nakshatra,
        if (rashi != null) 'rashi': rashi,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (address != null) 'address': address,
        if (familyMembers != null) 'family_members': familyMembers,
        if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
        'timezone': timezone ?? 'Asia/Kolkata',
      };
}

class FamilyMember {
  FamilyMember({this.name, this.relation, this.dateOfBirth, this.nakshatra});

  final String? name;
  final String? relation;
  final String? dateOfBirth;
  final String? nakshatra;

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
        name: json['name']?.toString(),
        relation: json['relation']?.toString(),
        dateOfBirth: json['dob']?.toString() ?? json['date_of_birth']?.toString(),
        nakshatra: json['nakshatra']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        if (dateOfBirth != null) 'dob': dateOfBirth,
        if (nakshatra != null) 'nakshatra': nakshatra,
      };

  static List<FamilyMember> parseList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => FamilyMember.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static String encodeList(List<FamilyMember> members) {
    try {
      return jsonEncode(members.map((m) => m.toJson()).toList());
    } catch (_) {
      return '[]';
    }
  }
}
