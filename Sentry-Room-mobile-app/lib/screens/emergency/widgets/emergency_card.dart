import 'package:flutter/material.dart';
import '../models/emergency_type.dart';
import '../models/emergency_action_type.dart';
import '../models/emergency_contact.dart';
import '../../home/widgets/home_widgets.dart';
import 'emergency_action_button.dart';

class EmergencyCard extends StatelessWidget {
  final EmergencyType type;
  final String title;
  final String description;
  final String severity;
  final IconData icon;
  final EmergencyContact contact;
  final ValueChanged<EmergencyActionType> onActionPressed;

  const EmergencyCard({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.icon,
    required this.contact,
    required this.onActionPressed,
  });

  Color _getSeverityColor() {
    switch (severity.toLowerCase()) {
      case 'critical':
        return HomeColors.danger;
      case 'high':
        return HomeColors.warning;
      case 'medium':
        return HomeColors.accent;
      default:
        return HomeColors.success;
    }
  }

  IconData _getSeverityIcon() {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.warning_rounded;
      case 'high':
        return Icons.error_outline_rounded;
      case 'medium':
        return Icons.info_outlined;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor();
    final severityIcon = _getSeverityIcon();

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBubble(icon: icon, color: severityColor, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: severity,
                color: severityColor,
                icon: severityIcon,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Contact info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  contact.role,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Action buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (contact.phone != null && contact.phone!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: EmergencyActionButton(
                      icon: Icons.call_rounded,
                      label: 'Call',
                      onPressed: () => onActionPressed(EmergencyActionType.call),
                    ),
                  ),
                if (contact.phone != null && contact.phone!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: EmergencyActionButton(
                      icon: Icons.sms_rounded,
                      label: 'SMS',
                      onPressed: () => onActionPressed(EmergencyActionType.sms),
                    ),
                  ),
                if (contact.email != null && contact.email!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: EmergencyActionButton(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      onPressed: () => onActionPressed(EmergencyActionType.email),
                    ),
                  ),
                EmergencyActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onPressed: () =>
                      onActionPressed(EmergencyActionType.shareLocation),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
