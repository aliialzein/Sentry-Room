import '../models/emergency_type.dart';
import '../models/emergency_contact.dart';
import '../models/gps_location.dart';
import '../utils/emergency_report_builder.dart';
import '../../../utils/date_utils.dart';

class IncidentSummaryBox {
  final EmergencyType type;
  final EmergencyContact contact;
  final String site;
  final String location;
  final GpsLocation? gpsLocation;

  const IncidentSummaryBox({
    required this.type,
    required this.contact,
    required this.site,
    required this.location,
    this.gpsLocation,
  });

  String get _emergencyTypeLabel {
    switch (type) {
      case EmergencyType.fire:
        return 'Fire Emergency';
      case EmergencyType.security:
        return 'Security Threat';
      case EmergencyType.humidity:
        return 'High Humidity / Fan Issue';
      case EmergencyType.medical:
        return 'Medical Emergency';
      case EmergencyType.support:
        return 'General Support';
    }
  }

  String get incidentSummary {
    final now = DateTime.now();
    final time = DateUtils.formatFull(now);

    return EmergencyReportBuilder.buildFromParts(
      emergencyTitle: _emergencyTypeLabel,
      actionLabel: 'Manual',
      contactName: contact.name,
      manualLocation: '$site, $location',
      gpsLat: gpsLocation?.latitude,
      gpsLon: gpsLocation?.longitude,
      timestampLabel: time,
      statusLabel: 'Confirmed',
    );
  }
}
