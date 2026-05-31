class AnalyticsType {
  final String type;
  final int count;

  const AnalyticsType({
    required this.type,
    required this.count,
  });

  factory AnalyticsType.fromJson(Map<String, dynamic> json) {
    return AnalyticsType(
      type: json['type']?.toString() ?? 'Unknown',
      count: _readInt(json['count']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
