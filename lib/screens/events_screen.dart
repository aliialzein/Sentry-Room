import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sentry_provider.dart';
import '../models/sentry_models.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sentry = context.watch<SentryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implementation for filtering events
            },
          ),
        ],
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
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    child: ExpansionTile(
                      leading: _getSeverityIcon(event.severity),
                      title: Text(
                        event.message,
                        style: TextStyle(
                          fontWeight: event.isAcknowledged ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy - HH:mm:ss').format(event.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Type', event.eventType),
                              _buildDetailRow('Severity', event.severity),
                              if (event.confidence != null)
                                _buildDetailRow('Confidence', '${(event.confidence! * 100).toStringAsFixed(1)}%'),
                              if (event.snapshotPath != null)
                                _buildDetailRow('Snapshot', event.snapshotPath!),
                              const SizedBox(height: 16),
                              if (!event.isAcknowledged)
                                ElevatedButton.icon(
                                  onPressed: () => sentry.acknowledgeEvent(event.id),
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
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _getSeverityIcon(String severity) {
    IconData iconData;
    Color color;
    switch (severity.toLowerCase()) {
      case 'danger':
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
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color, size: 20),
    );
  }
}
