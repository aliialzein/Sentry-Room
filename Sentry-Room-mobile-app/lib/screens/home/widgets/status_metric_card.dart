import 'package:flutter/material.dart';

import 'glass_panel.dart';
import 'icon_bubble.dart';
import 'metric_state.dart';
import 'status_badge.dart';

class StatusMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final MetricState state;
  final String helper;
  final String minLabel;
  final String maxLabel;
  final double progress;

  const StatusMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.state,
    required this.helper,
    required this.minLabel,
    required this.maxLabel,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconBubble(icon: icon, color: color),
              const Spacer(),
              StatusBadge(
                label: _stateLabel(state),
                color: color,
                icon: _stateIcon(state),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Text(maxLabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  String _stateLabel(MetricState state) {
    switch (state) {
      case MetricState.normal:
        return 'Normal';
      case MetricState.warning:
        return 'Warning';
      case MetricState.critical:
        return 'Critical';
      case MetricState.standby:
        return 'Standby';
    }
  }

  IconData _stateIcon(MetricState state) {
    switch (state) {
      case MetricState.normal:
        return Icons.check_circle_rounded;
      case MetricState.warning:
        return Icons.warning_rounded;
      case MetricState.critical:
        return Icons.report_rounded;
      case MetricState.standby:
        return Icons.hourglass_empty_rounded;
    }
  }
}
