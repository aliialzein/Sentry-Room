import 'package:flutter/material.dart';

import 'command_button.dart';
import 'glass_panel.dart';
import 'home_colors.dart';
import 'mini_stat.dart';
import 'panel_header.dart';

class AccessControlCard extends StatelessWidget {
  const AccessControlCard({
    super.key,
    required this.authorizedCount,
    required this.totalPeople,
    required this.isArmed,
    required this.onAddVisitor,
    required this.onManageAccess,
  });

  final int authorizedCount;
  final int totalPeople;
  final bool isArmed;
  final VoidCallback onAddVisitor;
  final VoidCallback onManageAccess;

  @override
  Widget build(BuildContext context) {
    final doorStatus = isArmed ? 'Secured' : 'Standby';
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(
            icon: Icons.badge_rounded,
            title: 'Access Control',
            subtitle: 'Door and authorized-person oversight',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MiniStat(
                  label: 'Door',
                  value: doorStatus,
                  icon: isArmed ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: isArmed ? HomeColors.success : HomeColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MiniStat(
                  label: 'Authorized',
                  value: '$authorizedCount/$totalPeople',
                  icon: Icons.verified_user_rounded,
                  color: HomeColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CommandButton(
                label: 'Add Visitor',
                icon: Icons.person_add_alt_1_rounded,
                color: HomeColors.success,
                onPressed: onAddVisitor,
              ),
              CommandButton(
                label: 'Manage Access',
                icon: Icons.manage_accounts_rounded,
                color: HomeColors.accent,
                onPressed: onManageAccess,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
