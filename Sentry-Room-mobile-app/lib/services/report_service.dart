import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/api_constants.dart';
import 'api_service.dart';
import 'report_storage/report_storage.dart' as report_storage;

class PdfReportFile {
  final Uint8List bytes;
  final String filename;

  const PdfReportFile({
    required this.bytes,
    required this.filename,
  });
}

class ReportService {
  static const Duration _requestTimeout = Duration(seconds: 30);

  final ApiService _apiService;

  ReportService({ApiService? apiService})
      : _apiService = apiService ?? ApiService(ApiConstants.baseUrl);

  Future<PdfReportFile> generatePdfReport({
    required String range,
    required String? authToken,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      throw Exception('Authentication token is required to generate reports.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/reports/pdf').replace(
      queryParameters: {'range': range},
    );
    final headers = _apiService.buildJsonHeaders(accessToken: authToken)
      ..['accept'] = 'application/pdf';

    final response = await http
        .get(uri, headers: headers)
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      return PdfReportFile(
        bytes: response.bodyBytes,
        filename: _filenameFromHeaders(response.headers) ??
            'sentry-room-emergency-analytics-$range.pdf',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Your session is not authorized to export reports.');
    }

    throw Exception(_errorMessage(response, 'Failed to generate PDF report.'));
  }

  Future<void> previewPdfReport(PdfReportFile report) async {
    await Printing.layoutPdf(
      name: report.filename,
      onLayout: (_) async => report.bytes,
    );
  }

  Future<void> sharePdfReport(PdfReportFile report) async {
    await Share.shareXFiles(
      [
        XFile.fromData(
          report.bytes,
          mimeType: 'application/pdf',
          name: report.filename,
        ),
      ],
      text: 'Sentry Room Emergency Analytics Report',
      subject: 'Sentry Room Emergency Analytics Report',
    );
  }

  Future<String> downloadPdfReport(PdfReportFile report) {
    return report_storage.savePdfReport(report.bytes, report.filename);
  }

  String? _filenameFromHeaders(Map<String, String> headers) {
    final contentDisposition = headers['content-disposition'];
    if (contentDisposition == null || contentDisposition.isEmpty) {
      return null;
    }

    final match = RegExp(r'filename="?([^";]+)"?').firstMatch(contentDisposition);
    return match?.group(1);
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
