import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/ai_summary.dart';
import 'api_service.dart';

class AiReportService {
  static const Duration _requestTimeout = Duration(seconds: 30);

  final ApiService _apiService;

  AiReportService({ApiService? apiService})
      : _apiService = apiService ?? ApiService(ApiConstants.baseUrl);

  Future<AiSummary> loadAiSummary({
    required String range,
    required String? authToken,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      throw Exception('Authentication token is required to load AI summaries.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/ai-reports/summary')
        .replace(queryParameters: {'range': range});
    final response = await http
        .get(
          uri,
          headers: _apiService.buildJsonHeaders(accessToken: authToken),
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return AiSummary.fromJson(decoded);
      }
      if (decoded is Map) {
        return AiSummary.fromJson(Map<String, dynamic>.from(decoded));
      }
      throw Exception('Invalid AI summary response.');
    }

    if (response.statusCode == 429) {
      throw Exception('AI summary limit reached. Try again later.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Your session is not authorized to load AI summaries.');
    }

    throw Exception(_errorMessage(response, 'Failed to load AI summary.'));
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
