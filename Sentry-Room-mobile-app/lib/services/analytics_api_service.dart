import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/analytics_action.dart';
import '../models/analytics_summary.dart';
import '../models/analytics_trend.dart';
import '../models/analytics_type.dart';
import 'api_service.dart';

class AnalyticsApiService {
  static const Duration _requestTimeout = Duration(seconds: 10);

  final ApiService _apiService;

  AnalyticsApiService(this._apiService);

  Future<AnalyticsSummary> fetchSummary({
    required String range,
    required String? authToken,
  }) async {
    final data = await _getMap('/api/analytics/summary', range, authToken);
    return AnalyticsSummary.fromJson(data);
  }

  Future<List<AnalyticsTrend>> fetchTrends({
    required String range,
    required String? authToken,
  }) async {
    final data = await _getList('/api/analytics/trends', range, authToken);
    return data.map(AnalyticsTrend.fromJson).toList();
  }

  Future<List<AnalyticsType>> fetchByType({
    required String range,
    required String? authToken,
  }) async {
    final data = await _getList('/api/analytics/by-type', range, authToken);
    return data.map(AnalyticsType.fromJson).toList();
  }

  Future<List<AnalyticsAction>> fetchByAction({
    required String range,
    required String? authToken,
  }) async {
    final data = await _getList('/api/analytics/by-action', range, authToken);
    return data.map(AnalyticsAction.fromJson).toList();
  }

  Future<Map<String, dynamic>> _getMap(
    String path,
    String range,
    String? authToken,
  ) async {
    final response = await _get(path, range, authToken);
    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Invalid analytics response.');
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path,
    String range,
    String? authToken,
  ) async {
    final response = await _get(path, range, authToken);
    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid analytics response.');
    }
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<http.Response> _get(
    String path,
    String range,
    String? authToken,
  ) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path').replace(
      queryParameters: {'range': range},
    );
    final response = await http
        .get(
          uri,
          headers: _apiService.buildJsonHeaders(accessToken: authToken),
        )
        .timeout(_requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    throw Exception(_errorMessage(response, 'Failed to load analytics.'));
  }

  String _errorMessage(http.Response response, String fallback) {
    if (response.body.isEmpty) {
      return '$fallback (${response.statusCode})';
    }

    try {
      final errorData = json.decode(response.body);
      final detail = errorData['detail'];
      if (detail != null) {
        return detail.toString();
      }
    } catch (_) {
      return '$fallback (${response.statusCode})';
    }

    return '$fallback (${response.statusCode})';
  }
}
