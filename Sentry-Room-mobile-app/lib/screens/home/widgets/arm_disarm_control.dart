import 'package:flutter/material.dart';

import 'home_colors.dart';
import 'icon_bubble.dart';

class ArmDisarmControl extends StatelessWidget {
  final bool isArmed;
  final bool isReadOnly;
  final VoidCallback onChanged;

  const ArmDisarmControl({
    super.key,
    required this.isArmed,
    required this.onChanged,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isArmed ? HomeColors.success : HomeColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          IconBubble(
            icon: isArmed ? Icons.shield_rounded : Icons.shield_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArmed ? 'System Armed' : 'System Disarmed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isArmed
                      ? 'Door, camera, and sensor alerts are active.'
                      : 'Alerts are visible, but active response is paused.',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (!isReadOnly) ...[
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: onChanged,
              icon: Icon(isArmed
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_rounded),
              label: Text(isArmed ? 'Disarm' : 'Arm'),
              style: FilledButton.styleFrom(
                foregroundColor: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
