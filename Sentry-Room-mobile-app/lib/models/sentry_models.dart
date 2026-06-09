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
