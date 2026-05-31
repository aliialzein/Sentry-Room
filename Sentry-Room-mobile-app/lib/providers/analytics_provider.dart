import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../models/analytics_action.dart';
import '../models/analytics_summary.dart';
import '../models/analytics_trend.dart';
import '../models/analytics_type.dart';
import '../services/analytics_api_service.dart';
import '../services/api_service.dart';

enum AnalyticsRange {
  daily,
  weekly,
  monthly,
}

extension AnalyticsRangeX on AnalyticsRange {
  String get apiValue {
    switch (this) {
      case AnalyticsRange.daily:
        return 'daily';
      case AnalyticsRange.weekly:
        return 'weekly';
      case AnalyticsRange.monthly:
        return 'monthly';
    }
  }

  String get label {
    switch (this) {
      case AnalyticsRange.daily:
        return 'Daily';
      case AnalyticsRange.weekly:
        return 'Weekly';
      case AnalyticsRange.monthly:
        return 'Monthly';
    }
  }
}

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsApiService _apiService = AnalyticsApiService(
    ApiService(ApiConstants.baseUrl),
  );

  AnalyticsRange _selectedRange = AnalyticsRange.daily;
  AnalyticsSummary _summary = const AnalyticsSummary.empty();
  List<AnalyticsTrend> _trends = [];
  List<AnalyticsType> _types = [];
  List<AnalyticsAction> _actions = [];
  bool _isLoading = false;
  String? _errorMessage;

  AnalyticsRange get selectedRange => _selectedRange;
  AnalyticsSummary get summary => _summary;
  List<AnalyticsTrend> get trends => List.unmodifiable(_trends);
  List<AnalyticsType> get types => List.unmodifiable(_types);
  List<AnalyticsAction> get actions => List.unmodifiable(_actions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasAnalyticsData {
    return _summary.totalIncidents > 0 ||
        _trends.any((trend) => trend.count > 0) ||
        _types.isNotEmpty ||
        _actions.isNotEmpty;
  }

  Future<void> loadAnalytics({required String? authToken}) async {
    if (authToken == null || authToken.isEmpty) {
      _errorMessage = 'Authentication token is required to load analytics.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final range = _selectedRange.apiValue;
      final results = await Future.wait([
        _apiService.fetchSummary(range: range, authToken: authToken),
        _apiService.fetchTrends(range: range, authToken: authToken),
        _apiService.fetchByType(range: range, authToken: authToken),
        _apiService.fetchByAction(range: range, authToken: authToken),
      ]);

      _summary = results[0] as AnalyticsSummary;
      _trends = results[1] as List<AnalyticsTrend>;
      _types = results[2] as List<AnalyticsType>;
      _actions = _normalizeActions(results[3] as List<AnalyticsAction>);
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeRange(
    AnalyticsRange range, {
    required String? authToken,
  }) async {
    if (_selectedRange == range && hasAnalyticsData) {
      return;
    }

    _selectedRange = range;
    notifyListeners();
    await loadAnalytics(authToken: authToken);
  }

  List<AnalyticsAction> _normalizeActions(List<AnalyticsAction> actions) {
    final counts = <String, int>{
      for (final action in actions) action.action: action.count,
    };

    return [
      AnalyticsAction(action: 'Call', count: counts['Call'] ?? 0),
      AnalyticsAction(action: 'SMS', count: counts['SMS'] ?? 0),
      AnalyticsAction(action: 'Email', count: counts['Email'] ?? 0),
      AnalyticsAction(action: 'Share', count: counts['Share'] ?? 0),
    ];
  }
}
