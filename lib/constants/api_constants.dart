import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    // If running on Web (Chrome/Edge), use loopback explicitly.
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    // If running on Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    // Default for physical devices or desktop
    // For physical phone, you must change this to your Laptop's IP
    return 'http://127.0.0.1:8000';
  }

  static String get cameraStreamUrl => '$baseUrl/api/camera/stream';

  static String get cameraSnapshotUrl => '$baseUrl/api/camera/snapshot';
}
