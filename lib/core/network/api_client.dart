import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_config.dart';


class ApiResult {
  ApiResult({required this.statusCode, required this.data, required this.success, required this.message});

  final int statusCode;
  final dynamic data;
  final bool success;
  final String message;

  Map<String, dynamic> get body => data is Map<String, dynamic> ? data as Map<String, dynamic> : <String, dynamic>{};
}

class ApiClient {
  ApiClient._();

  static String? authToken;

  /// Invoked (before throwing) when the backend rejects a token because the
  /// account was signed in on another device — web parity: the `session-conflict`
  /// CustomEvent dispatched by the axios response interceptor.
  static void Function(String message)? onSessionConflict;

  static Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = authToken ?? '';
    if (auth && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p').replace(queryParameters: (query?.isNotEmpty ?? false) ? query : null);
  }

  static String normalizeError(dynamic error) {
    if (error is ApiException) return error.message;
    return 'Unable to connect to PanditIndia server. Please check your internet connection.';
  }

  static Future<ApiResult> get(String path, {Map<String, String>? query, bool auth = true}) async {
    return _send('GET', path, query: query, auth: auth);
  }

  static Future<ApiResult> post(String path, {Object? body, bool auth = true}) async {
    return _send('POST', path, body: body, auth: auth);
  }

  static Future<ApiResult> put(String path, {Object? body, bool auth = true}) async {
    return _send('PUT', path, body: body, auth: auth);
  }

  static Future<ApiResult> patch(String path, {Object? body, bool auth = true}) async {
    return _send('PATCH', path, body: body, auth: auth);
  }

  static Future<ApiResult> delete(String path, {Map<String, String>? query, bool auth = true}) async {
    return _send('DELETE', path, query: query, auth: auth);
  }

  static Future<ApiResult> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final uri = _uri(path, query);
    final headers = _headers(auth: auth);
    final encoded = body == null ? null : jsonEncode(body);

    http.Response res;
    try {
      final request = http.Request(method, uri);
      request.headers.addAll(headers);
      if (encoded != null) request.body = encoded;
      final streamed = await http.Client().send(request).timeout(AppConfig.requestTimeout);
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } catch (e) {
      throw ApiException(normalizeError(e));
    }

    dynamic parsed;
    if (res.body.isNotEmpty) {
      try {
        parsed = jsonDecode(res.body);
      } catch (_) {
        parsed = res.body;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ApiResult(
        statusCode: res.statusCode,
        data: parsed,
        success: true,
        message: _messageOf(parsed, statusCode: res.statusCode),
      );
    }

    final apiException = ApiException(
      _messageOf(parsed, statusCode: res.statusCode),
      statusCode: res.statusCode,
      data: parsed,
    );
    if (apiException.isSessionConflict) {
      ApiClient.onSessionConflict?.call(apiException.message);
    }
    throw apiException;
  }

  static String _messageOf(dynamic data, {int? statusCode}) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is Map<String, dynamic>) {
        final msg = detail['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      if (detail is String && detail.isNotEmpty) return detail;
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    if (data is String && data.isNotEmpty) {
      final trimmed = data.trimLeft();
      if (trimmed.startsWith('<')) {
        // HTML error page from the edge server (e.g. nginx 403/404/5xx) —
        // translate it instead of dumping raw markup into a toast.
        if (statusCode == 403) {
          return 'Access to the server was denied (HTTP 403). Please try again later.';
        }
        if (statusCode == 404) {
          return 'Service not found (HTTP 404). Please update the app or try again later.';
        }
        if (statusCode != null && statusCode >= 500) {
          return 'The server is unavailable (HTTP $statusCode). Please try again shortly.';
        }
        return 'The server returned an unexpected response. Please try again.';
      }
      if (!trimmed.startsWith('{')) return data;
    }
    return 'Something went wrong. Please try again.';
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final dynamic data;

  bool get isConflict => statusCode == 409;

  /// Mirrors the web `api.js` response interceptor: a 401 raised because the
  /// account was signed in somewhere else (single-session enforcement).
  bool get isSessionConflict {
    if (statusCode != 401) return false;
    final body = data;
    if (body is! Map<String, dynamic>) return false;
    if (body['session_conflict'] == true) return true;
    final detail = body['detail'];
    if (detail is Map<String, dynamic> && detail['session_conflict'] == true) {
      return true;
    }
    bool containsConflict(Object? value) =>
        value is String && value.toLowerCase().contains('another browser');
    return containsConflict(detail is Map<String, dynamic> ? detail['message'] : detail) ||
        containsConflict(body['message']);
  }

  @override
  String toString() => message;
}
