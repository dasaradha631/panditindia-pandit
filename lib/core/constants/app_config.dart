class AppConfig {
  static const String baseUrl = 'https://api.panditindia.com';

  static String assetUrl(String path) {
    final clean = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$clean';
  }

  static const String appName = 'PanditIndia Acharya';
  static const String tagline = 'Vedic Service Partner';

  /// Toll-free helpline — digit-only form for `tel:` URIs (same as web
  /// `tel:18008908334`). Do NOT put `+`, spaces or dashes here.
  static const String supportPhone = '18008908334';

  /// Human-readable form for on-screen display.
  static const String supportPhoneDisplay = '1800-890-VEDA (8334)';

  /// WhatsApp support line — digits only, for `wa.me/<number>` (same as web
  /// `https://wa.me/919876543210`).
  static const String supportWhatsApp = '919876543210';

  static const String supportEmail = 'info@panditindia.com';
  static const Duration requestTimeout = Duration(seconds: 15);
}
