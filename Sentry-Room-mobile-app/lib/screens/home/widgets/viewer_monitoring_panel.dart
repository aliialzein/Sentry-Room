import 'package:flutter/material.dart';

import 'action_tile.dart';
import 'arm_disarm_control.dart';
import 'glass_panel.dart';
import 'home_colors.dart';
import 'panel_header.dart';

class ViewerMonitoringPanel extends StatelessWidget {
  const ViewerMonitoringPanel({
    super.key,
    required this.isArmed,
    required this.modeLabel,
    required this.modeDescription,
    required this.modeColor,
    required this.modeIcon,
    required this.isSyncing,
    required this.onSync,
  });

  final bool isArmed;
  final String modeLabel;
  final String modeDescription;
  final Color modeColor;
  final IconData modeIcon;
  final bool isSyncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(
            icon: Icons.visibility_rounded,
            title: 'Monitoring Overview',
            subtitle: 'Live room status and security activity',
          ),
          const SizedBox(height: 18),
          ArmDisarmControl(
            isArmed: isArmed,
            modeLabel: modeLabel,
            modeDescription: modeDescription,
            modeColor: modeColor,
            modeIcon: modeIcon,
            isReadOnly: true,
            onChanged: () {},
          ),
          const SizedBox(height: 18),
          ActionTile(
            label: isSyncing ? 'Syncing' : 'Sync Dashboard',
            icon: Icons.cloud_sync_rounded,
            color: HomeColors.success,
            tooltip: 'Refresh room telemetry',
            onPressed: isSyncing ? null : onSync,
          ),
        ],
      ),
    );
  }
}
