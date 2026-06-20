import 'package:flutter/foundation.dart';

/// URL base da API BaileSul.
abstract final class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api';
      default:
        return 'http://localhost:3000/api';
    }
  }

  static String get serverOrigin {
    final Uri uri = Uri.parse(baseUrl);
    final int? port = uri.hasPort ? uri.port : null;
    if (port != null) {
      return '${uri.scheme}://${uri.host}:$port';
    }
    return '${uri.scheme}://${uri.host}';
  }

  static String resolveMediaUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '$serverOrigin$raw';
    return raw;
  }
}
