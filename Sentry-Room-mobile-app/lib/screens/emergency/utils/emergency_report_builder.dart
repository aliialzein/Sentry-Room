import '../models/emergency_incident_log.dart';

class EmergencyReportBuilder {
  static String build(EmergencyIncidentLog log) {
    return buildFromParts(
      emergencyTitle: log.emergencyTitle,
      actionLabel: log.actionLabel,
      contactName: log.contactName,
      manualLocation: log.manualLocation,
      gpsLat: log.gpsLatitude,
      gpsLon: log.gpsLongitude,
      timestampLabel: log.timestampLabel,
      statusLabel: log.statusLabel,
    );
  }

  static String buildFromParts({
    required String emergencyTitle,
    required String actionLabel,
    required String contactName,
    required String manualLocation,
    double? gpsLat,
    double? gpsLon,
    required String timestampLabel,
    required String statusLabel,
  }) {
    final gpsLine = (gpsLat != null && gpsLon != null)
        ? 'GPS: ${gpsLat.toStringAsFixed(4)}, ${gpsLon.toStringAsFixed(4)}'
        : 'GPS: Not available';

    return '''Sentry Room Emergency Report
Type: $emergencyTitle
Action: $actionLabel
Contact: $contactName
Manual Location: $manualLocation
$gpsLine
Time: $timestampLabel
Status: $statusLabel
Notes: Manual emergency action started from the Sentry Room app.''';
  }
}
