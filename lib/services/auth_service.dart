import '../core/network/api_client.dart';

class AuthResult {
  AuthResult({required this.success, this.message, this.data});

  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
}

class AuthService {
  Future<AuthResult> register(Map<String, dynamic> payload) async {
    try {
      final res = await ApiClient.post('/register', body: payload, auth: false);
      final body = res.body;
      return AuthResult(success: body['success'] == true, message: body['message']?.toString(), data: body);
    } on ApiException catch (e) {
      return AuthResult(success: false, message: e.message);
    }
  }

  Future<AuthResult> login({required String email, required String password, required String role}) async {
    try {
      final res = await ApiClient.post('/login', body: {'email': email, 'password': password, 'role': role}, auth: false);
      final body = res.body;
      return AuthResult(success: body['success'] == true, message: body['message']?.toString(), data: body);
    } on ApiException catch (e) {
      return AuthResult(success: false, message: e.message);
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    try {
      final res = await ApiClient.post('/forgot-password', body: {'email': email}, auth: false);
      final body = res.body;
      return AuthResult(success: body['success'] == true, message: body['message']?.toString(), data: body);
    } on ApiException catch (e) {
      return AuthResult(success: false, message: e.message);
    }
  }

  Future<AuthResult> verifyOtp({required String email, required String otp}) async {
    try {
      final res = await ApiClient.post('/verify-otp', body: {'email': email, 'otp': otp}, auth: false);
      final body = res.body;
      return AuthResult(success: body['success'] == true, message: body['message']?.toString(), data: body);
    } on ApiException catch (e) {
      return AuthResult(success: false, message: e.message);
    }
  }

  Future<AuthResult> changePassword({required String email, required String newPassword}) async {
    try {
      final res = await ApiClient.post('/change-password', body: {'email': email, 'newPassword': newPassword}, auth: false);
      final body = res.body;
      return AuthResult(success: body['success'] == true, message: body['message']?.toString(), data: body);
    } on ApiException catch (e) {
      return AuthResult(success: false, message: e.message);
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.post('/logout');
    } catch (_) {}
  }

  /// Starts pandit registration verification — web parity:
  /// `POST /register/send-otp` with `{identifier, channel}` (channel is
  /// 'email' or 'mobile').
  Future<AuthResult> sendRegistrationOtp({
    required String identifier,
    required String channel,
  }) async {
    try {
      final res = await ApiClient.post(
        '/register/send-otp',
        body: {'identifier': identifier, 'channel': channel},
        auth: false,
      );
      final body = res.body;
      return AuthResult(
        success: body['success'] == true,
        message: body['message']?.toString(),
        data: body,
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, message: e.message);
    }
  }

  /// Confirms the 6-digit code issued by [sendRegistrationOtp].
  Future<AuthResult> verifyRegistrationOtp({
    required String identifier,
    required String channel,
    required String otp,
  }) async {
    try {
      final res = await ApiClient.post(
        '/register/verify-otp',
        body: {'identifier': identifier, 'channel': channel, 'otp': otp},
        auth: false,
      );
      final body = res.body;
      return AuthResult(
        success: body['success'] == true,
        message: body['message']?.toString(),
        data: body,
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, message: e.message);
    }
  }

  /// Single-session verification — web parity: `GET /session-check`.
  /// Throws [ApiException] on 401 so the caller can distinguish
  /// "signed out elsewhere" from network errors.
  Future<void> sessionCheck() async {
    await ApiClient.get('/session-check');
  }
}
