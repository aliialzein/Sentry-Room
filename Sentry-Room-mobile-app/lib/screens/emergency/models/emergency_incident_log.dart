import '../../../utils/date_utils.dart';
import 'emergency_action_type.dart';
import 'emergency_type.dart';

enum EmergencyIncidentStatus {
  confirmed,
  openedExternalApp,
  failedToOpenExternalApp,
  shared,
}

class EmergencyIncidentLog {
  final String id;
  final EmergencyType emergencyType;
  final String emergencyTitle;
  final EmergencyActionType actionType;
  final String contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String manualLocation;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final DateTime timestamp;
  final EmergencyIncidentStatus status;
  final bool isSynced;

  const EmergencyIncidentLog({
    required this.id,
    required this.emergencyType,
    required this.emergencyTitle,
    required this.actionType,
    required this.contactName,
    this.contactPhone,
    this.contactEmail,
    required this.manualLocation,
    this.gpsLatitude,
    this.gpsLongitude,
    required this.timestamp,
    required this.status,
    this.isSynced = false,
  });

  String get actionLabel {
    switch (actionType) {
      case EmergencyActionType.call:
        return 'Call';
      case EmergencyActionType.sms:
        return 'SMS';
      case EmergencyActionType.email:
        return 'Email';
      case EmergencyActionType.shareLocation:
        return 'Share';
    }
  }

  String get statusLabel {
    switch (status) {
      case EmergencyIncidentStatus.confirmed:
        return 'Confirmed';
      case EmergencyIncidentStatus.openedExternalApp:
        return 'Opened External App';
      case EmergencyIncidentStatus.failedToOpenExternalApp:
        return 'Failed to Open App';
      case EmergencyIncidentStatus.shared:
        return 'Shared';
    }
  }

  String get timestampLabel => DateUtils.formatFull(timestamp);

  String get gpsLabel {
    if (gpsLatitude == null || gpsLongitude == null) {
      return 'Not available';
    }
    return '${gpsLatitude!.toStringAsFixed(4)}, ${gpsLongitude!.toStringAsFixed(4)}';
  }

  EmergencyIncidentLog copyWith({
    EmergencyIncidentStatus? status,
    bool? isSynced,
  }) {
    return EmergencyIncidentLog(
      id: id,
      emergencyType: emergencyType,
      emergencyTitle: emergencyTitle,
      actionType: actionType,
      contactName: contactName,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      manualLocation: manualLocation,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      timestamp: timestamp,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emergencyType': emergencyType.name,
      'emergencyTitle': emergencyTitle,
      'actionType': actionType.name,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'manualLocation': manualLocation,
      'gpsLatitude': gpsLatitude,
      'gpsLongitude': gpsLongitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'isSynced': isSynced,
    };
  }

  factory EmergencyIncidentLog.fromJson(Map<String, dynamic> json) {
    return EmergencyIncidentLog(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      emergencyType: EmergencyType.values.firstWhere(
        (value) => value.name == json['emergencyType'],
        orElse: () => EmergencyType.support,
      ),
      emergencyTitle: json['emergencyTitle']?.toString() ?? 'Unknown',
      actionType: EmergencyActionType.values.firstWhere(
        (value) => value.name == json['actionType'],
        orElse: () => EmergencyActionType.shareLocation,
      ),
      contactName: json['contactName']?.toString() ?? 'Unknown',
      contactPhone: json['contactPhone']?.toString(),
      contactEmail: json['contactEmail']?.toString(),
      manualLocation: json['manualLocation']?.toString() ?? '',
      gpsLatitude: _parseDouble(json['gpsLatitude']),
      gpsLongitude: _parseDouble(json['gpsLongitude']),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      status: EmergencyIncidentStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => EmergencyIncidentStatus.confirmed,
      ),
      isSynced: json['isSynced'] == true,
    );
  }

  static double? _parseDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed;
  }
}
