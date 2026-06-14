class Person {
  final int id;
  final String fullName;
  final String? role;
  final bool isAuthorized;
  final String? imagePath;
  final String? notes;

  Person({
    required this.id,
    required this.fullName,
    this.role,
    required this.isAuthorized,
    this.imagePath,
    this.notes,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      fullName: json['full_name'] ?? 'Unknown',
      role: json['role'],
      isAuthorized: json['is_authorized'] ?? false,
      imagePath: json['image_path'],
      notes: json['notes'],
    );
  }
}

class Event {
  final int id;
  final String eventType;
  final String severity;
  final String message;
  final int? personId;
  final double? confidence;
  final String? snapshotPath;
  final Map<String, dynamic>? sensorPayload;
  final bool isAcknowledged;
  final DateTime? lastSeenAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.message,
    this.personId,
    this.confidence,
    this.snapshotPath,
    this.sensorPayload,
    required this.isAcknowledged,
    this.lastSeenAt,
    this.endedAt,
    required this.createdAt,
  });

  bool get hasCapturedUnknownFace {
    final payload = sensorPayload;
    if (payload == null) return false;

    final unknownFaceCount = payload['unknown_face_count'];
    if (unknownFaceCount is num && unknownFaceCount > 0) {
      return true;
    }

    final legacyEncodings = payload['unknown_face_encodings'];
    if (legacyEncodings is List && legacyEncodings.isNotEmpty) {
      return true;
    }

    final identities = payload['identities'];
    if (identities is List) {
      return identities.any(
        (identity) =>
            identity is Map && identity['status']?.toString() == 'unknown_face',
      );
    }

    return false;
  }

  bool get isFireRiskEvent {
    final payload = sensorPayload;
    if (eventType != 'environmental_alert' || payload == null) return false;
    return payload['emergency_type']?.toString() == 'fire' ||
        payload['fire_risk'] is Map;
  }

  bool get isFireEmergency {
    if (!isFireRiskEvent) return false;
    final fireRisk = sensorPayload?['fire_risk'];
    if (fireRisk is Map) {
      final isEmergency = fireRisk['is_emergency'];
      if (isEmergency is bool) return isEmergency;

      final gemini = fireRisk['gemini'];
      if (gemini is Map) {
        final risk = gemini['risk']?.toString().toLowerCase();
        if (risk == 'high') return true;
        if (gemini['fire_visible'] == true || gemini['smoke_visible'] == true) {
          return true;
        }
      }
    }
    return severity == 'critical';
  }

  Map<String, dynamic> get fireRiskDetails {
    final fireRisk = sensorPayload?['fire_risk'];
    if (fireRisk is Map<String, dynamic>) return fireRisk;
    if (fireRisk is Map) return Map<String, dynamic>.from(fireRisk);
    return {};
  }

  String get fireReason {
    final gemini = fireRiskDetails['gemini'];
    if (gemini is Map) {
      final reason = gemini['reason']?.toString();
      if (reason != null && reason.trim().isNotEmpty) return reason.trim();
    }
    return message;
  }

  String get identityCategory {
    if (isFireRiskEvent) {
      return isFireEmergency ? 'fire_emergency' : 'fire_warning';
    }

    final payload = sensorPayload;
    final identityKey = payload?['identity_key']?.toString();
    final detectedFaceCount = _numValue(payload?['detected_face_count']);
    final unknownFaceCount = _numValue(payload?['unknown_face_count']);
    final identity = _firstIdentity(payload);
    final status = identity?['status']?.toString();
    final isAuthorized = identity?['is_authorized'];

    if (identityKey == 'no_face' || detectedFaceCount == 0) {
      return 'no_face';
    }

    if (identityKey == 'unknown_face' ||
        (unknownFaceCount != null && unknownFaceCount > 0) ||
        status == 'unknown_face') {
      return 'unknown_face';
    }

    if (status == 'authorized' ||
        isAuthorized == true ||
        eventType == 'authorized_entry') {
      return 'authorized_person';
    }

    if (status == 'unauthorized' ||
        (isAuthorized == false && identityKey?.startsWith('person_') == true) ||
        (eventType == 'unauthorized_entry' && personId != null)) {
      return 'unauthorized_person';
    }

    if (eventType == 'unauthorized_entry') {
      return 'unauthorized_entry';
    }

    return 'event';
  }

  String get displayTypeLabel {
    switch (identityCategory) {
      case 'no_face':
        return 'No face visible';
      case 'unknown_face':
        return 'Unknown face';
      case 'authorized_person':
        return 'Authorized person';
      case 'unauthorized_person':
        return 'Unauthorized person';
      case 'unauthorized_entry':
        return 'Unauthorized entry';
      case 'fire_emergency':
        return 'Fire emergency risk';
      case 'fire_warning':
        return 'Possible fire risk';
      default:
        return _eventTypeLabel(eventType);
    }
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      eventType: json['event_type'] ?? 'unknown',
      severity: json['severity'] ?? 'info',
      message: json['message'] ?? '',
      personId: json['person_id'],
      confidence: json['confidence']?.toDouble(),
      snapshotPath: json['snapshot_path'],
      sensorPayload: json['sensor_payload'] is Map
          ? Map<String, dynamic>.from(json['sensor_payload'])
          : null,
      isAcknowledged: json['is_acknowledged'] ?? false,
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at']),
      endedAt:
          json['ended_at'] == null ? null : DateTime.parse(json['ended_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static num? _numValue(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static Map<String, dynamic>? _firstIdentity(Map<String, dynamic>? payload) {
    final identities = payload?['identities'];
    if (identities is! List) return null;

    for (final identity in identities) {
      if (identity is Map<String, dynamic>) return identity;
      if (identity is Map) return Map<String, dynamic>.from(identity);
    }

    return null;
  }

  static String _eventTypeLabel(String value) {
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class SensorReading {
  final int id;
  final String sensorType;
  final Map<String, dynamic> value;
  final String? source;
  final DateTime createdAt;

  SensorReading({
    required this.id,
    required this.sensorType,
    required this.value,
    this.source,
    required this.createdAt,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: json['id'],
      sensorType: json['sensor_type'] ?? 'unknown',
      value: json['value'] is Map ? json['value'] : {},
      source: json['source'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
