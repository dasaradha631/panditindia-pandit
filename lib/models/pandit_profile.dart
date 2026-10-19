class PanditProfile {
  PanditProfile({
    this.id,
    this.username,
    this.fullName,
    this.email,
    this.phonenumber,
    this.dateOfBirth,
    this.role,
    this.isVerified,
    this.vedaBranch,
    this.gotra,
    this.gurukul,
    this.anyGovernmentId,
    this.experanceCertificateNumber,
    this.upiId,
    this.bankAccount,
    this.ifscCode,
    this.experienceYears,
    this.languages,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.specializations,
    this.bio,
    this.availability,
    this.profilePhotoUrl,
    this.subscriptionStatus,
  });

  final int? id;
  final String? username;
  final String? fullName;
  final String? email;
  final String? phonenumber;
  final String? dateOfBirth;
  final String? role;
  final bool? isVerified;
  final String? vedaBranch;
  final String? gotra;
  final String? gurukul;
  final String? anyGovernmentId;
  final String? experanceCertificateNumber;
  final String? upiId;
  final String? bankAccount;
  final String? ifscCode;
  final int? experienceYears;
  final String? languages;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? specializations;
  final String? bio;
  final String? availability;
  final String? profilePhotoUrl;
  final String? subscriptionStatus;

  static String? _s(dynamic v) => v == null ? null : (v.toString().isEmpty ? null : v.toString());

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().replaceAll(RegExp(r'[^\d\-]'), ''));
  }

  factory PanditProfile.fromJson(Map<String, dynamic> json) => PanditProfile(
        id: (json['id'] ?? json['user_id']) is int
            ? (json['id'] ?? json['user_id']) as int
            : int.tryParse('${json['id'] ?? json['user_id']}'),
        username: _s(json['username']),
        fullName: _s(json['full_name'] ?? json['name']),
        email: _s(json['email']),
        phonenumber: _s(json['phonenumber'] ?? json['phone']),
        dateOfBirth: _s(json['date_of_birth']),
        role: _s(json['role']),
        isVerified: json['is_verified'] is bool
            ? json['is_verified'] as bool
            : (json['is_verified'] is num ? (json['is_verified'] as num) == 1 : null),
        vedaBranch: _s(json['veda_branch']),
        gotra: _s(json['gotra']),
        gurukul: _s(json['gurukul']),
        anyGovernmentId: _s(json['any_government_id']),
        experanceCertificateNumber: _s(json['experance_certificate_number']),
        upiId: _s(json['upi_id']),
        bankAccount: _s(json['bank_account']),
        ifscCode: _s(json['ifsc_code']),
        experienceYears: _i(json['experience_years']),
        languages: _s(json['languages']),
        city: _s(json['city']),
        state: _s(json['state']),
        pincode: _s(json['pincode']),
        latitude: _d(json['latitude']),
        longitude: _d(json['longitude']),
        specializations: _s(json['specializations']),
        bio: _s(json['bio']),
        availability: _s(json['availability']),
        profilePhotoUrl: _s(json['profile_photo_url']),
        subscriptionStatus: _s(json['subscription_status']),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (fullName != null) 'full_name': fullName,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (phonenumber != null) 'phonenumber': phonenumber,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (vedaBranch != null) 'veda_branch': vedaBranch,
        if (gotra != null) 'gotra': gotra,
        if (gurukul != null) 'gurukul': gurukul,
        if (anyGovernmentId != null) 'any_government_id': anyGovernmentId,
        if (experanceCertificateNumber != null)
          'experance_certificate_number': experanceCertificateNumber,
        if (upiId != null) 'upi_id': upiId,
        if (bankAccount != null) 'bank_account': bankAccount,
        if (ifscCode != null) 'ifsc_code': ifscCode,
        'experience_years': experienceYears ?? 0,
        if (languages != null) 'languages': languages,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (specializations != null) 'specializations': specializations,
        if (bio != null) 'bio': bio,
        'availability': availability ?? 'available',
        if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      };

  bool get isComplete =>
      (fullName?.isNotEmpty ?? false) && (phonenumber?.isNotEmpty ?? false) && (city?.isNotEmpty ?? false);
}

class DevoteeReview {
  DevoteeReview({
    this.reviewId,
    this.rating,
    this.reviewTitle,
    this.reviewText,
    this.isAnonymous,
    this.customerName,
    this.ceremony,
    this.createdAt,
  });

  final int? reviewId;
  final int? rating;
  final String? reviewTitle;
  final String? reviewText;
  final bool? isAnonymous;
  final String? customerName;
  final String? ceremony;
  final String? createdAt;

  factory DevoteeReview.fromJson(Map<String, dynamic> json) => DevoteeReview(
        reviewId: json['review_id'] is int ? json['review_id'] as int : int.tryParse('${json['review_id']}'),
        rating: json['rating'] is int
            ? json['rating'] as int
            : int.tryParse('${json['rating']}'),
        reviewTitle: json['review_title']?.toString(),
        reviewText: json['review_text']?.toString(),
        isAnonymous: json['is_anonymous'] is bool ? json['is_anonymous'] as bool : null,
        customerName: json['customer_name']?.toString(),
        ceremony: json['ceremony']?.toString(),
        createdAt: json['created_at']?.toString(),
      );
}
