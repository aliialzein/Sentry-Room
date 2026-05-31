class AiSummary {
  final String range;
  final DateTime generatedAt;
  final String summary;
  final List<String> keyFindings;
  final List<String> recommendations;

  const AiSummary({
    required this.range,
    required this.generatedAt,
    required this.summary,
    required this.keyFindings,
    required this.recommendations,
  });

  factory AiSummary.fromJson(Map<String, dynamic> json) {
    return AiSummary(
      range: json['range']?.toString() ?? 'daily',
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
      summary: json['summary']?.toString() ?? 'AI summary unavailable.',
      keyFindings: _readStringList(json['keyFindings']),
      recommendations: _readStringList(json['recommendations']),
    );
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
