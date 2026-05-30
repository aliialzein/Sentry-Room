import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_service.dart';
import '../screens/emergency/models/emergency_incident_log.dart';

class EmergencyIncidentApiService {
  final ApiService _apiService;

  EmergencyIncidentApiService(this._apiService);

  Future<Map<String, dynamic>> createIncident(
    EmergencyIncidentLog log, {
    required String? authToken,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/emergency-incidents'),
      headers: _apiService.buildJsonHeaders(accessToken: authToken),
      body: json.encode({
        'emergency_type': log.emergencyType.name,
        'emergency_title': log.emergencyTitle,
        'action_type': log.actionType.name,
        'contact_name': log.contactName,
        'contact_phone': log.contactPhone,
        'contact_email': log.contactEmail,
        'manual_location': log.manualLocation,
        'gps_latitude': log.gpsLatitude,
        'gps_longitude': log.gpsLongitude,
        'status': _statusToBackendValue(log.status),
        'source': 'mobile_app',
        'details': {
          'manual_report_summary': log.emergencyTitle,
        },
        'recorded_at': log.timestamp.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    final errorData = json.decode(response.body);
    throw Exception(errorData['detail'] ?? 'Failed to sync emergency incident.');
  }

  String _statusToBackendValue(EmergencyIncidentStatus status) {
    switch (status) {
      case EmergencyIncidentStatus.confirmed:
        return 'confirmed';
      case EmergencyIncidentStatus.openedExternalApp:
        return 'opened_external_app';
      case EmergencyIncidentStatus.failedToOpenExternalApp:
        return 'failed_to_open_external_app';
      case EmergencyIncidentStatus.shared:
        return 'shared';
    }
  }
}
