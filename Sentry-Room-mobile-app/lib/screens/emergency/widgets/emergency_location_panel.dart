import 'package:flutter/material.dart';
import '../../home/widgets/home_widgets.dart';
import '../models/gps_location.dart';

class EmergencyLocationPanel extends StatelessWidget {
  final String site;
  final String location;
  final String notes;
  final GpsLocation? gpsLocation;
  final bool isRequestingGpsLocation;
  final VoidCallback? onRequestGpsLocation;

  const EmergencyLocationPanel({
    super.key,
    required this.site,
    required this.location,
    required this.notes,
    this.gpsLocation,
    this.isRequestingGpsLocation = false,
    this.onRequestGpsLocation,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBubble(
                icon: Icons.location_on_rounded,
                color: HomeColors.accent,
              ),
              SizedBox(width: 12),
              Text(
                'Incident Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildLocationItem('Site', site),
          const SizedBox(height: 8),
          _buildLocationItem('Location', location),
          if (gpsLocation != null) ...[
            const SizedBox(height: 8),
            _buildLocationItem(
              'GPS',
              '${gpsLocation!.latitude.toStringAsFixed(4)}, ${gpsLocation!.longitude.toStringAsFixed(4)}',
            ),
          ],
          if (onRequestGpsLocation != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isRequestingGpsLocation ? null : onRequestGpsLocation,
              icon: isRequestingGpsLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.location_searching_rounded, size: 16),
              label: Text(
                isRequestingGpsLocation
                    ? 'Locating...'
                    : 'Use Current Location',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: HomeColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: HomeColors.warning.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: HomeColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notes,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
