import 'package:flutter/material.dart';

import 'icon_bubble.dart';

class ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String tooltip;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const ActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            focusColor: color.withValues(alpha: 0.22),
            child: Ink(
              decoration: BoxDecoration(
                color: (isPrimary ? color : Colors.white).withValues(
                  alpha: enabled ? (isPrimary ? 0.16 : 0.055) : 0.025,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: enabled ? 0.28 : 0.08),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconBubble(
                      icon: icon,
                      color: enabled ? color : Colors.white30,
                      size: 42,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
