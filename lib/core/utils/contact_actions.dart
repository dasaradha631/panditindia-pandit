import 'package:url_launcher/url_launcher.dart';

/// Opens the native dialer for any phone number (devotee or support line).
Future<bool> callNumber(String? phone) => callDevotee(phone);

/// Opens a WhatsApp chat for [phone] with an optional prefilled [message].
Future<bool> openWhatsApp(String? phone, {String? message}) =>
    whatsappDevotee(phone, message ?? '');

/// Opens the native dialer for a devotee number.
Future<bool> callDevotee(String? mobile) async {
  final raw = _clean(mobile);
  if (raw.isEmpty) return false;
  final uri = Uri(scheme: 'tel', path: raw);
  try {
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}

/// Opens WhatsApp with a pre-filled Namaste message for the devotee.
Future<bool> whatsappDevotee(String? mobile, String message) async {
  final raw = _clean(mobile);
  if (raw.isEmpty) return false;
  final text = message.trim();
  final query = text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}';
  final uri = Uri.parse('https://wa.me/$raw$query');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Opens the venue address inside Google Maps turn-by-turn navigation.
Future<bool> openMaps(String query) async {
  if (query.trim().isEmpty) return false;
  final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

String _clean(String? value) => (value ?? '').replaceAll(RegExp(r'\D'), '');
