import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'glass_panel.dart';
import 'header_chip.dart';
import 'header_icon_button.dart';
import 'status_badge.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.connectionLabel,
    required this.connectionColor,
    required this.connectionIcon,
    required this.userName,
    required this.isAdmin,
    required this.now,
    required this.onOpenCamera,
    required this.onOpenUserManagement,
    required this.onOpenProfile,
    required this.onOpenEmergency,
  });

  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final String connectionLabel;
  final Color connectionColor;
  final IconData connectionIcon;
  final String userName;
  final bool isAdmin;
  final DateTime now;
  final VoidCallback onOpenCamera;
  final VoidCallback onOpenUserManagement;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenEmergency;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(
                    label: statusLabel,
                    color: statusColor,
                    icon: statusIcon,
                  ),
                  StatusBadge(
                    label: connectionLabel,
                    color: connectionColor,
                    icon: connectionIcon,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Welcome, $userName',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: isCompact ? 24 : 30,
                      height: 1.05,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Room security command center',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          );

          final tools = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              HeaderChip(
                icon: Icons.schedule_rounded,
                label: DateFormat('HH:mm:ss').format(now),
                tooltip: DateFormat('EEEE, MMM d, yyyy').format(now),
              ),
              HeaderIconButton(
                tooltip: 'Open emergency center',
                icon: Icons.emergency_rounded,
                onPressed: onOpenEmergency,
              ),
              HeaderIconButton(
                tooltip: 'Open live camera',
                icon: Icons.videocam_rounded,
                onPressed: onOpenCamera,
              ),
              if (isAdmin)
                HeaderIconButton(
                  tooltip: 'Open user management',
                  icon: Icons.manage_accounts_rounded,
                  onPressed: onOpenUserManagement,
                ),
              HeaderIconButton(
                tooltip: 'Open profile',
                icon: Icons.account_circle_outlined,
                onPressed: onOpenProfile,
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 18),
                tools,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 24),
              tools,
            ],
          );
        },
      ),
    );
  }
}
