import 'package:flutter/material.dart';

import 'camera_grid_painter.dart';
import 'command_button.dart';
import 'glass_panel.dart';
import 'home_colors.dart';
import 'panel_header.dart';
import 'status_badge.dart';

const _accent = HomeColors.accent;
const _success = HomeColors.success;
const _warning = HomeColors.warning;
const _danger = HomeColors.danger;

class LiveCameraCard extends StatelessWidget {
  const LiveCameraCard({
    super.key,
    required this.isRecording,
    required this.isSnapshotLoading,
    required this.onViewCamera,
    required this.onSnapshot,
    required this.onToggleRecording,
  });

  final bool isRecording;
  final bool isSnapshotLoading;
  final VoidCallback onViewCamera;
  final VoidCallback onSnapshot;
  final VoidCallback onToggleRecording;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeader(
            icon: Icons.videocam_rounded,
            title: 'Live Camera',
            subtitle: isRecording ? 'Recording active' : 'Stream ready',
            trailing: StatusBadge(
              label: isRecording ? 'Recording' : 'Online',
              color: isRecording ? _danger : _success,
              icon: isRecording ? Icons.fiber_manual_record : Icons.circle,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B1220),
                    Color(0xFF111B2F),
                    Color(0xFF050816),
                  ],
                ),
                border: Border.all(color: Colors.white10),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CameraGridPainter(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          size: 42,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preview standby',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: StatusBadge(
                      label: 'CAM-01',
                      color: _accent,
                      icon: Icons.camera_alt_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CommandButton(
                label: 'View Camera',
                icon: Icons.open_in_full_rounded,
                color: _accent,
                onPressed: onViewCamera,
              ),
              CommandButton(
                label: isSnapshotLoading ? 'Capturing' : 'Snapshot',
                icon: Icons.photo_camera_rounded,
                color: _success,
                onPressed: isSnapshotLoading ? null : onSnapshot,
              ),
              CommandButton(
                label: isRecording ? 'Stop Record' : 'Record',
                icon: isRecording
                    ? Icons.stop_circle_rounded
                    : Icons.fiber_manual_record_rounded,
                color: isRecording ? _danger : _warning,
                onPressed: onToggleRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
