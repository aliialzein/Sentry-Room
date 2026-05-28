import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'home_colors.dart';
import 'icon_bubble.dart';
import 'status_badge.dart';

class EventRow extends StatelessWidget {
  final String title;
  final String detail;
  final DateTime time;
  final String severity;
  final IconData icon;
  final String statusLabel;

  const EventRow({
    super.key,
    required this.title,
    required this.detail,
    required this.time,
    required this.severity,
    required this.icon,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          IconBubble(icon: icon, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(time),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusBadge(
            label: statusLabel,
            color: color,
            icon: statusLabel == 'Open'
                ? Icons.radio_button_checked_rounded
                : Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return HomeColors.danger;
      case 'warning':
        return HomeColors.warning;
      default:
        return HomeColors.accent;
    }
  }
}
