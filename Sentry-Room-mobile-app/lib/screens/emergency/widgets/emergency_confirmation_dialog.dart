import 'package:flutter/material.dart';
import '../models/emergency_action_type.dart';
import '../models/gps_location.dart';
import '../../home/widgets/home_widgets.dart';

class EmergencyConfirmationDialog extends StatelessWidget {
  final String emergencyTitle;
  final EmergencyActionType actionType;
  final String contactName;
  final String manualLocation;
  final GpsLocation? gpsLocation;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const EmergencyConfirmationDialog({
    super.key,
    required this.emergencyTitle,
    required this.actionType,
    required this.contactName,
    required this.manualLocation,
    this.gpsLocation,
    required this.onConfirm,
    required this.onCancel,
  });

  String get _actionLabel {
    switch (actionType) {
      case EmergencyActionType.call:
        return 'Call';
      case EmergencyActionType.sms:
        return 'Send SMS';
      case EmergencyActionType.email:
        return 'Send Email';
      case EmergencyActionType.shareLocation:
        return 'Share Location';
    }
  }

  IconData get _actionIcon {
    switch (actionType) {
      case EmergencyActionType.call:
        return Icons.call_rounded;
      case EmergencyActionType.sms:
        return Icons.sms_rounded;
      case EmergencyActionType.email:
        return Icons.email_rounded;
      case EmergencyActionType.shareLocation:
        return Icons.share_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: HomeColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: HomeColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: HomeColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _actionIcon,
                color: HomeColors.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            // Title
            const Text(
              'Confirm Action',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            // Details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Emergency:', emergencyTitle),
                  const SizedBox(height: 8),
                  _buildDetailRow('Action:', _actionLabel),
                  const SizedBox(height: 8),
                  _buildDetailRow('Contact:', contactName),
                  const SizedBox(height: 8),
                  _buildDetailRow('Location:', manualLocation),
                  if (gpsLocation != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'GPS:',
                      '${gpsLocation!.latitude.toStringAsFixed(4)}, ${gpsLocation!.longitude.toStringAsFixed(4)}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HomeColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: HomeColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: HomeColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action will open a communication app. Only proceed if you intend to contact this party immediately.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: HomeColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
