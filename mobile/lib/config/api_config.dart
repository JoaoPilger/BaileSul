import 'package:flutter/foundation.dart';

/// URL base da API BaileSul.
///
/// Em builds de release/profile (o app/desktop instalado de verdade) sempre
/// aponta para o backend em produção, que é compartilhado entre o app móvel
/// e o executável desktop (mesmo backend no Render + banco no Supabase).
/// Em debug, aponta para um backend local — útil ao desenvolver a UI sem
/// depender de rede, mas nunca usado no app publicado.
abstract final class ApiConfig {
  static const String _prodUrl = 'https://bailesul.onrender.com/api';

  static String get baseUrl {
    if (kReleaseMode || kProfileMode) {
      return _prodUrl;
    }

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
