import 'package:flutter/material.dart';

import 'action_tile.dart';
import 'arm_disarm_control.dart';
import 'glass_panel.dart';
import 'home_colors.dart';
import 'panel_header.dart';

const _accent = HomeColors.accent;
const _success = HomeColors.success;
const _warning = HomeColors.warning;
const _danger = HomeColors.danger;

class GlobalMonitoringPanel extends StatelessWidget {
  const GlobalMonitoringPanel({
    super.key,
    required this.notifyAllUsers,
    required this.isArmed,
    required this.isSyncing,
    required this.isLocking,
    required this.onNotifyAllUsersChanged,
    required this.onToggleArmed,
    required this.onLockRoom,
    required this.onPanicMode,
    required this.onSync,
    required this.onAlertSecurity,
    required this.onLockdown,
  });

  final bool notifyAllUsers;
  final bool isArmed;
  final bool isSyncing;
  final bool isLocking;
  final ValueChanged<bool> onNotifyAllUsersChanged;
  final VoidCallback onToggleArmed;
  final VoidCallback onLockRoom;
  final VoidCallback onPanicMode;
  final VoidCallback onSync;
  final VoidCallback onAlertSecurity;
  final VoidCallback onLockdown;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeader(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Global Monitoring',
            subtitle: 'Security controls for the room perimeter',
            trailing: Semantics(
              label: 'Monitoring enabled toggle',
              child: Switch.adaptive(
                value: notifyAllUsers,
                activeThumbColor: _accent,
                onChanged: onNotifyAllUsersChanged,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ArmDisarmControl(
            isArmed: isArmed,
            onChanged: onToggleArmed,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 660 ? 5 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: columns == 5 ? 0.96 : 1.25,
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
                    label: 'Panic Mode',
                    icon: Icons.emergency_share_outlined,
                    color: _danger,
                    isPrimary: true,
                    tooltip: 'Trigger panic mode confirmation',
                    onPressed: onPanicMode,
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
                  ActionTile(
                    label: 'Lockdown',
                    icon: Icons.gpp_maybe_rounded,
                    color: _danger,
                    tooltip: 'Start lockdown confirmation',
                    onPressed: onLockdown,
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
