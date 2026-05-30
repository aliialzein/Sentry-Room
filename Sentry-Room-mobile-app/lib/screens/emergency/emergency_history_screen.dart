import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/auth_provider.dart';
import 'models/emergency_incident_log.dart';
import 'providers/emergency_incident_log_provider.dart';
import 'utils/emergency_report_builder.dart';

import '../home/widgets/home_widgets.dart';

class EmergencyHistoryScreen extends StatelessWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<EmergencyIncidentLogProvider>();
    final logs = historyProvider.logs;

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: HomeColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              title: const Text(
                'Emergency History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (logs.any((log) => !log.isSynced))
                  IconButton(
                    icon: const Icon(Icons.cloud_upload_outlined,
                        color: Colors.white),
                    tooltip: 'Sync pending incidents',
                    onPressed: () =>
                        _syncPendingIncidents(context, historyProvider),
                  ),
                if (logs.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    tooltip: 'Clear History',
                    onPressed: () =>
                        _confirmClearHistory(context, historyProvider),
                  ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: logs.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 72,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'No incident history yet.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Confirmed emergency actions will appear here for your reference.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final log = logs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: GlassPanel(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      IconBubble(
                                        icon: _statusIcon(log.status),
                                        color: _statusColor(log.status),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${log.emergencyTitle} · ${log.actionLabel}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              log.timestampLabel,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(
                                              Icons.share_rounded,
                                              color: HomeColors.accent,
                                              size: 22,
                                            ),
                                            tooltip: 'Share report',
                                            onPressed: () =>
                                                _shareIncident(context, log),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(
                                              Icons.copy_rounded,
                                              color: Colors.white70,
                                              size: 22,
                                            ),
                                            tooltip: 'Copy report',
                                            onPressed: () =>
                                                _copyIncident(context, log),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.white70,
                                              size: 22,
                                            ),
                                            tooltip: 'Delete entry',
                                            onPressed: () => _confirmDeleteItem(
                                                context,
                                                historyProvider,
                                                log.id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _buildDetailRow('Contact', log.contactName),
                                  if (log.contactPhone != null) ...[
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      'Phone',
                                      log.contactPhone!,
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                  if (log.contactEmail != null) ...[
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      'Email',
                                      log.contactEmail!,
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                      'Location', log.manualLocation),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('GPS', log.gpsLabel),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Status', log.statusLabel),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Sync',
                                      log.isSynced ? 'Synced' : 'Pending'),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: logs.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    TextDirection? textDirection,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textDirection: textDirection,
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

  Color _statusColor(EmergencyIncidentStatus status) {
    switch (status) {
      case EmergencyIncidentStatus.confirmed:
        return HomeColors.warning;
      case EmergencyIncidentStatus.openedExternalApp:
        return HomeColors.success;
      case EmergencyIncidentStatus.failedToOpenExternalApp:
        return HomeColors.danger;
      case EmergencyIncidentStatus.shared:
        return HomeColors.accent;
    }
  }

  IconData _statusIcon(EmergencyIncidentStatus status) {
    switch (status) {
      case EmergencyIncidentStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case EmergencyIncidentStatus.openedExternalApp:
        return Icons.open_in_new_rounded;
      case EmergencyIncidentStatus.failedToOpenExternalApp:
        return Icons.error_outline_rounded;
      case EmergencyIncidentStatus.shared:
        return Icons.share_rounded;
    }
  }

  void _confirmClearHistory(
    BuildContext context,
    EmergencyIncidentLogProvider provider,
  ) {
    showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmModal(
        title: 'Clear Incident History',
        message:
            'This will remove all locally stored emergency incidents. Do you want to continue?',
        confirmLabel: 'Clear',
        color: HomeColors.danger,
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        provider.clearLogs();
      }
    });
  }

  void _confirmDeleteItem(
    BuildContext context,
    EmergencyIncidentLogProvider provider,
    String id,
  ) {
    showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmModal(
        title: 'Delete Incident',
        message:
            'Remove this incident entry from local history? This cannot be undone.',
        confirmLabel: 'Delete',
        color: HomeColors.danger,
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        provider.removeLog(id);
      }
    });
  }

  void _shareIncident(BuildContext context, EmergencyIncidentLog log) {
    final summary = EmergencyReportBuilder.build(log);
    Share.share(summary);
  }

  void _copyIncident(BuildContext context, EmergencyIncidentLog log) {
    final report = EmergencyReportBuilder.build(log);
    Clipboard.setData(ClipboardData(text: report));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Incident report copied to clipboard'),
        backgroundColor: HomeColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _syncPendingIncidents(
    BuildContext context,
    EmergencyIncidentLogProvider provider,
  ) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Sign in to sync emergency incident history to the backend.'),
          backgroundColor: HomeColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final pendingCount = provider.logs.where((log) => !log.isSynced).length;
    if (pendingCount == 0) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final syncedCount =
          await provider.syncPendingIncidents(authToken: authProvider.token);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synced $syncedCount incident(s) to backend.'),
          backgroundColor: HomeColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString()}'),
          backgroundColor: HomeColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
