import 'package:flutter/material.dart';

import 'action_tile.dart';
import 'arm_disarm_control.dart';
import 'glass_panel.dart';
import 'home_colors.dart';
import 'panel_header.dart';

const _accent = HomeColors.accent;
const _success = HomeColors.success;
const _warning = HomeColors.warning;

class GlobalMonitoringPanel extends StatelessWidget {
  const GlobalMonitoringPanel({
    super.key,
    required this.isArmed,
    required this.modeLabel,
    required this.modeDescription,
    required this.modeColor,
    required this.modeIcon,
    required this.isSyncing,
    required this.isLocking,
    required this.onToggleArmed,
    required this.onLockRoom,
    required this.onSync,
    required this.onAlertSecurity,
  });

  final bool isArmed;
  final String modeLabel;
  final String modeDescription;
  final Color modeColor;
  final IconData modeIcon;
  final bool isSyncing;
  final bool isLocking;
  final VoidCallback onToggleArmed;
  final VoidCallback onLockRoom;
  final VoidCallback onSync;
  final VoidCallback onAlertSecurity;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeader(
            icon: Icons.shield_rounded,
            title: 'Security Mode',
            subtitle: 'Operation controls for the room perimeter',
          ),
          const SizedBox(height: 18),
          ArmDisarmControl(
            isArmed: isArmed,
            modeLabel: modeLabel,
            modeDescription: modeDescription,
            modeColor: modeColor,
            modeIcon: modeIcon,
            onChanged: onToggleArmed,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 660 ? 3 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: columns == 3 ? 1.12 : 1.25,
                children: [
                  ActionTile(
                    label: isLocking ? 'Locking' : 'Lock Room',
                    icon: isLocking
                        ? Icons.hourglass_top_rounded
                        : Icons.lock_outline_rounded,
                    color: _accent,
                    tooltip: 'Lock the room door',
                    onPressed: isLocking ? null : onLockRoom,
                  ),
                  ActionTile(
                    label: isSyncing ? 'Syncing' : 'Sync',
                    icon: isSyncing
                        ? Icons.sync_rounded
                        : Icons.cloud_sync_rounded,
                    color: _success,
                    tooltip: 'Refresh room telemetry',
                    onPressed: isSyncing ? null : onSync,
                  ),
                  ActionTile(
                    label: 'Alert Security',
                    icon: Icons.support_agent_rounded,
                    color: _warning,
                    tooltip: 'Send emergency alert confirmation',
                    onPressed: onAlertSecurity,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
