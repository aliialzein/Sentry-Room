import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/api_constants.dart';
import '../providers/sentry_provider.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sentry = context.watch<SentryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
      ),
      body: RefreshIndicator(
        onRefresh: sentry.refreshData,
        child: sentry.events.isEmpty
            ? const Center(child: Text('No activity recorded yet.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sentry.events.length,
                itemBuilder: (context, index) {
                  final event = sentry.events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    child: ExpansionTile(
                      leading: _getSeverityIcon(event.severity),
                      trailing: event.isAcknowledged
                          ? const Icon(Icons.verified_outlined)
                          : IconButton(
                              tooltip: 'Acknowledge event',
                              icon: const Icon(Icons.done_all),
                              onPressed: () async {
                                final success =
                                    await sentry.acknowledgeEvent(event.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Event acknowledged.'
                                          : (sentry.lastActionError ??
                                              'Failed to acknowledge event.'),
                                    ),
                                  ),
                                );
                              },
                            ),
                      title: Text(
                        event.message,
                        style: TextStyle(
                          fontWeight: event.isAcknowledged
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildIdentityBadge(
                              event.displayTypeLabel,
                              event.identityCategory,
                              event.severity,
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy - HH:mm:ss')
                                  .format(event.createdAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                  'Identity', event.displayTypeLabel),
                              _buildDetailRow('Type', event.eventType),
                              _buildDetailRow('Severity', event.severity),
                              if (event.lastSeenAt != null ||
                                  event.endedAt != null)
                                _buildDetailRow(
                                    'Status',
                                    event.endedAt == null
                                        ? 'Active'
                                        : 'Ended'),
                              if (event.lastSeenAt != null)
                                _buildDetailRow('Last seen',
                                    _formatTimestamp(event.lastSeenAt!)),
                              if (event.endedAt != null)
                                _buildDetailRow(
                                    'Ended', _formatTimestamp(event.endedAt!)),
                              if (event.confidence != null)
                                _buildDetailRow('Confidence',
                                    '${(event.confidence! * 100).toStringAsFixed(1)}%'),
                              if (event.snapshotPath != null)
                                _buildSnapshotPreview(event.snapshotPath!),
                              const SizedBox(height: 16),
                              if (!event.isAcknowledged)
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      sentry.acknowledgeEvent(event.id),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Acknowledge'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(40),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildIdentityBadge(
    String label,
    String category,
    String severity,
  ) {
    final color = _getIdentityColor(category, severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIdentityIcon(category), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotPreview(String snapshotPath) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            ApiConstants.snapshotUrl(snapshotPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const Text('Snapshot unavailable'),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    return DateFormat('MMM dd, yyyy - HH:mm:ss').format(value);
  }

  Widget _getSeverityIcon(String severity) {
    IconData iconData;
    Color color;
    switch (severity.toLowerCase()) {
      case 'critical':
        iconData = Icons.report_problem;
        color = Colors.red;
        break;
      case 'warning':
        iconData = Icons.warning;
        color = Colors.orange;
        break;
      default:
        iconData = Icons.info;
        color = Colors.blue;
    }
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  Color _getIdentityColor(String category, String severity) {
    switch (category) {
      case 'authorized_person':
        return Colors.green;
      case 'no_face':
        return Colors.orange;
      case 'unknown_face':
        return Colors.deepOrange;
      case 'fire_warning':
        return Colors.orange;
      case 'fire_emergency':
        return Colors.red;
      case 'unauthorized_person':
      case 'unauthorized_entry':
        return Colors.red;
      default:
        return _severityColor(severity);
    }
  }

  IconData _getIdentityIcon(String category) {
    switch (category) {
      case 'authorized_person':
        return Icons.verified_user_outlined;
      case 'no_face':
        return Icons.visibility_off_outlined;
      case 'unknown_face':
        return Icons.person_search_outlined;
      case 'fire_warning':
        return Icons.local_fire_department_outlined;
      case 'fire_emergency':
        return Icons.local_fire_department_rounded;
      case 'unauthorized_person':
      case 'unauthorized_entry':
        return Icons.gpp_maybe_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
