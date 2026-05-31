class AnalyticsSummary {
  final int totalIncidents;
  final int pendingSync;
  final int successfulActions;
  final int failedActions;
  final String? mostCommonType;

  const AnalyticsSummary({
    required this.totalIncidents,
    required this.pendingSync,
    required this.successfulActions,
    required this.failedActions,
    required this.mostCommonType,
  });

  const AnalyticsSummary.empty()
      : totalIncidents = 0,
        pendingSync = 0,
        successfulActions = 0,
        failedActions = 0,
        mostCommonType = null;

  AnalyticsSummary copyWith({
    int? totalIncidents,
    int? pendingSync,
    int? successfulActions,
    int? failedActions,
    String? mostCommonType,
  }) {
    return AnalyticsSummary(
      totalIncidents: totalIncidents ?? this.totalIncidents,
      pendingSync: pendingSync ?? this.pendingSync,
      successfulActions: successfulActions ?? this.successfulActions,
      failedActions: failedActions ?? this.failedActions,
      mostCommonType: mostCommonType ?? this.mostCommonType,
    );
  }

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalIncidents: _readInt(json['totalIncidents']),
      pendingSync: _readInt(json['pendingSync']),
      successfulActions: _readInt(json['successfulActions']),
      failedActions: _readInt(json['failedActions']),
      mostCommonType: json['mostCommonType']?.toString(),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
