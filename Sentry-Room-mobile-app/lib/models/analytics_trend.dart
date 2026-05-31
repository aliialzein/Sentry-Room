class AnalyticsTrend {
  final DateTime date;
  final int count;

  const AnalyticsTrend({
    required this.date,
    required this.count,
  });

  factory AnalyticsTrend.fromJson(Map<String, dynamic> json) {
    return AnalyticsTrend(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.now(),
      count: _readInt(json['count']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
