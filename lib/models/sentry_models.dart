class Person {
  final int id;
  final String fullName;
  final String? role;
  final bool isAuthorized;
  final String? notes;

  Person({
    required this.id,
    required this.fullName,
    this.role,
    required this.isAuthorized,
    this.notes,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      fullName: json['full_name'] ?? 'Unknown',
      role: json['role'],
      isAuthorized: json['is_authorized'] ?? false,
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
  final bool isAcknowledged;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.message,
    this.personId,
    this.confidence,
    this.snapshotPath,
    required this.isAcknowledged,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      eventType: json['event_type'] ?? 'unknown',
      severity: json['severity'] ?? 'info',
      message: json['message'] ?? '',
      personId: json['person_id'],
      confidence: json['confidence']?.toDouble(),
      snapshotPath: json['snapshot_path'],
      isAcknowledged: json['is_acknowledged'] ?? false,
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
