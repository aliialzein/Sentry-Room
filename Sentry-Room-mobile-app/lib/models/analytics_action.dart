class AnalyticsAction {
  final String action;
  final int count;

  const AnalyticsAction({
    required this.action,
    required this.count,
  });

  factory AnalyticsAction.fromJson(Map<String, dynamic> json) {
    return AnalyticsAction(
      action: json['action']?.toString() ?? 'Unknown',
      count: _readInt(json['count']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
