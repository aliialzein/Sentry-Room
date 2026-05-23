import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'SENTRY_API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static String get wsAlertsUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme, path: '/api/ws/alerts').toString();
  }

  static String get cameraStreamUrl => '$baseUrl/api/camera/stream';

  static String get cameraSnapshotUrl => '$baseUrl/api/camera/snapshot';

  static String snapshotUrl(String snapshotPath) {
    final normalized = snapshotPath.replaceAll('\\', '/');
    const evidencePrefix = 'data/evidence/';

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    if (normalized.startsWith(evidencePrefix)) {
      return '$baseUrl/evidence/${normalized.substring(evidencePrefix.length)}';
    }

    return '$baseUrl/$normalized';
  }
}
