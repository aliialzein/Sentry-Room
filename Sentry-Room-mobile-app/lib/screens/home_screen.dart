import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'emergency/emergency_screen.dart';
import '../models/sentry_models.dart';
import '../providers/auth_provider.dart';
import '../providers/sentry_provider.dart';
import 'home/widgets/home_widgets.dart';
import 'camera_screen.dart';
import 'events_screen.dart';
import 'people_screen.dart';
import 'profile_screen.dart';
import 'user_management_screen.dart';

const _background = HomeColors.background;
const _accent = HomeColors.accent;
const _success = HomeColors.success;
const _warning = HomeColors.warning;
const _danger = HomeColors.danger;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _UnauthorizedAlertResult {
  acknowledged,
  authorized,
}

enum _FireAlertResult {
  acknowledged,
  openEmergency,
  viewEvents,
}

class _CommandActivity {
  final String title;
  final String detail;
  final String severity;
  final IconData icon;
  final DateTime time;

  const _CommandActivity({
    required this.title,
    required this.detail,
    required this.severity,
    required this.icon,
    required this.time,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<int> _alertedUnauthorizedEventIds = {};
  final Set<int> _alertedFireEventIds = {};
  final List<_CommandActivity> _localActivity = [];

  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  DateTime? _lastSyncAt;
  int? _activeAlertEventId;
  bool _isSyncing = false;
  bool _isRecording = false;
  bool _isSnapshotLoading = false;
  bool _isLocking = false;

  @override
  void initState() {
    super.initState();
    _lastSyncAt = DateTime.now();
    _localActivity.addAll([
      _CommandActivity(
        title: 'Monitoring armed',
        detail: 'Sentry Room command center is active.',
        severity: 'info',
        icon: Icons.shield_rounded,
        time: _now,
      ),
      _CommandActivity(
        title: 'Door secured',
        detail: 'Primary room lock is in secure state.',
        severity: 'info',
        icon: Icons.lock_rounded,
        time: _now.subtract(const Duration(minutes: 3)),
      ),
    ]);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _queueUnauthorizedAlert(
    BuildContext context,
    SentryProvider sentry,
    AuthProvider auth,
  ) {
    if (_activeAlertEventId != null) return;

    Event? unauthorizedEvent;
    for (final event in sentry.events) {
      if (event.eventType == 'unauthorized_entry' &&
          !event.isAcknowledged &&
          !_alertedUnauthorizedEventIds.contains(event.id)) {
        unauthorizedEvent = event;
        break;
      }
    }

    if (unauthorizedEvent == null) return;

    _activeAlertEventId = unauthorizedEvent.id;
    _alertedUnauthorizedEventIds.add(unauthorizedEvent.id);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final result = await showDialog<_UnauthorizedAlertResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _UnauthorizedEntryDialog(
          event: unauthorizedEvent!,
          isAdmin: auth.isAdmin,
          canAddPerson: unauthorizedEvent!.hasCapturedUnknownFace,
        ),
      );

      if (!mounted) return;

      setState(() {
        if (_activeAlertEventId == unauthorizedEvent!.id) {
          _activeAlertEventId = null;
        }
      });

      if (result == _UnauthorizedAlertResult.authorized) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Person authorized successfully.')),
        );
      } else if (result == _UnauthorizedAlertResult.acknowledged) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Event acknowledged.')),
        );
      }
    });
  }

  void _queueFireAlert(BuildContext context, SentryProvider sentry) {
    if (_activeAlertEventId != null) return;

    Event? fireEvent;
    for (final event in sentry.events) {
      if (event.isFireRiskEvent &&
          !event.isAcknowledged &&
          !_alertedFireEventIds.contains(event.id)) {
        fireEvent = event;
        break;
      }
    }

    if (fireEvent == null) return;

    _activeAlertEventId = fireEvent.id;
    _alertedFireEventIds.add(fireEvent.id);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final result = await showDialog<_FireAlertResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _FireRiskDialog(event: fireEvent!),
      );

      if (!mounted) return;

      setState(() {
        if (_activeAlertEventId == fireEvent!.id) {
          _activeAlertEventId = null;
        }
      });

      if (result == _FireAlertResult.acknowledged) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Fire alert acknowledged.')),
        );
      } else if (result == _FireAlertResult.openEmergency) {
        _openEmergency(context);
      } else if (result == _FireAlertResult.viewEvents) {
        _openEvents(context);
      }
    });
  }

  void _openCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  void _openPeople(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PeopleScreen()),
    );
  }

  void _openEvents(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventsScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openEmergency(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyScreen()),
    );
  }

  void _openAnalytics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentry = context.watch<SentryProvider>();
    final auth = context.watch<AuthProvider>();
    final activeAlerts = _activeAlertCount(sentry);
    final connection = _connectionStatus(sentry);
    final systemColor =
        activeAlerts > 0 ? _danger : _securityModeColor(sentry.securityMode);
    final userName = auth.fullName ?? auth.username ?? 'Operator';

    _queueFireAlert(context, sentry);
    _queueUnauthorizedAlert(context, sentry, auth);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _syncNow(sentry),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeHeader(
                            statusLabel: activeAlerts > 0
                                ? '$activeAlerts active alert${activeAlerts == 1 ? '' : 's'}'
                                : _securityModeLabel(sentry.securityMode),
                            statusColor: systemColor,
                            statusIcon: activeAlerts > 0
                                ? Icons.report_problem_rounded
                                : _securityModeIcon(sentry.securityMode),
                            connectionLabel: connection.label,
                            connectionColor: connection.color,
                            connectionIcon: connection.icon,
                            userName: userName,
                            isAdmin: auth.isAdmin,
                            now: _now,
                            onOpenCamera: () => _openCamera(context),
                            onOpenEmergency: () => _openEmergency(context),
                            onOpenAnalytics: () => _openAnalytics(context),
                            onOpenUserManagement: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserManagementScreen(),
                              ),
                            ),
                            onOpenProfile: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildDashboardGrid(context, auth, sentry),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        isAdmin: auth.isAdmin,
        onOpenCamera: () => _openCamera(context),
        onOpenPeople: () => _openPeople(context),
        onOpenEvents: () => _openEvents(context),
        onOpenAnalytics: () => _openAnalytics(context),
        onOpenSettings: () => _openSettings(context),
      ),
    );
  }

  Widget _buildDashboardGrid(
    BuildContext context,
    AuthProvider auth,
    SentryProvider sentry,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1050;
        final medium = constraints.maxWidth >= 760;
        final sideBySide = wide || medium;

        final commandPanel = auth.isAdmin
            ? GlobalMonitoringPanel(
                isArmed: sentry.isArmed,
                modeLabel: _securityModeLabel(sentry.securityMode),
                modeDescription: _securityModeDescription(sentry.securityMode),
                modeColor: _securityModeColor(sentry.securityMode),
                modeIcon: _securityModeIcon(sentry.securityMode),
                isSyncing: _isSyncing,
                isLocking: _isLocking,
                onToggleArmed: () => _toggleSecurityMode(sentry),
                onLockRoom: () => _confirmAndRun(
                  title: 'Lock room?',
                  message:
                      'This will mark the room as locked in the command center. Connect this to the door lock API when hardware control ready.',
                  confirmLabel: 'Lock Room',
                  color: _warning,
                  onConfirm: () {
                    _setSecurityMode(sentry, 'locked');
                  },
                ),
                onSync: () => _syncNow(sentry),
                onAlertSecurity: () => _confirmAndRun(
                  title: 'Alert security team?',
                  message:
                      'This will create a local command-center alert. Connect it to SMS, email, or dispatch APIs later.',
                  confirmLabel: 'Alert',
                  color: _warning,
                  onConfirm: () => _mockEmergencyAction(
                    'Security team alerted',
                    'Emergency call placeholder was activated.',
                    Icons.support_agent_rounded,
                  ),
                ),
              )
            : ViewerMonitoringPanel(
                isArmed: sentry.isArmed,
                modeLabel: _securityModeLabel(sentry.securityMode),
                modeDescription: _securityModeDescription(sentry.securityMode),
                modeColor: _securityModeColor(sentry.securityMode),
                modeIcon: _securityModeIcon(sentry.securityMode),
                isSyncing: _isSyncing,
                onSync: () => _syncNow(sentry),
              );

        final topContent = sideBySide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: wide ? 7 : 6, child: commandPanel),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: wide ? 5 : 4,
                    child: LiveCameraCard(
                      isRecording: _isRecording,
                      isSnapshotLoading: _isSnapshotLoading,
                      onViewCamera: () => _openCamera(context),
                      onSnapshot: _takeSnapshot,
                      onToggleRecording: _toggleRecording,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  commandPanel,
                  const SizedBox(height: 16),
                  LiveCameraCard(
                    isRecording: _isRecording,
                    isSnapshotLoading: _isSnapshotLoading,
                    onViewCamera: () => _openCamera(context),
                    onSnapshot: _takeSnapshot,
                    onToggleRecording: _toggleRecording,
                  ),
                ],
              );

        final lowerContent = sideBySide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AccessControlCard(
                      authorizedCount: sentry.persons
                          .where((person) => person.isAuthorized)
                          .length,
                      totalPeople: sentry.persons.length,
                      isArmed: sentry.isArmed,
                      onAddVisitor: () {
                        _showFeedback(
                            'Visitor enrollment form opens from Manage Access.');
                        _openPeople(context);
                      },
                      onManageAccess: () => _openPeople(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRecentEventsCard(context, sentry)),
                ],
              )
            : Column(
                children: [
                  AccessControlCard(
                    authorizedCount: sentry.persons
                        .where((person) => person.isAuthorized)
                        .length,
                    totalPeople: sentry.persons.length,
                    isArmed: sentry.isArmed,
                    onAddVisitor: () {
                      _showFeedback(
                          'Visitor enrollment form opens from Manage Access.');
                      _openPeople(context);
                    },
                    onManageAccess: () => _openPeople(context),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentEventsCard(context, sentry),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            topContent,
            const SizedBox(height: 18),
            _buildEnvironmentStatus(context, sentry, constraints.maxWidth),
            const SizedBox(height: 18),
            lowerContent,
          ],
        );
      },
    );
  }

  Widget _buildEnvironmentStatus(
    BuildContext context,
    SentryProvider sentry,
    double availableWidth,
  ) {
    final readings = sentry.liveStatus['latest_readings'] as Map? ?? {};
    final env = readings['temperature_humidity'] as Map? ?? {};
    final temperature = _readNumber(env['temperature_c']);
    final humidity = _readNumber(env['humidity_percent']);
    final activeAlerts = _activeAlertCount(sentry);
    final columns = availableWidth >= 1050
        ? 3
        : availableWidth >= 640
            ? 2
            : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Environment Status',
          actionLabel: _lastSyncAt == null
              ? 'Awaiting sync'
              : 'Updated ${DateFormat('HH:mm').format(_lastSyncAt!)}',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1
              ? 1.65
              : columns == 2
                  ? 1.3
                  : 1.25,
          children: [
            StatusMetricCard(
              title: 'Temperature',
              value:
                  temperature == null ? '--' : temperature.toStringAsFixed(1),
              unit: 'C',
              icon: Icons.thermostat_rounded,
              color: _metricColor(_temperatureState(temperature)),
              state: _temperatureState(temperature),
              helper: 'Normal 18-30 C',
              minLabel: '18',
              maxLabel: '30',
              progress: _progressFromRange(temperature, 10, 40),
            ),
            StatusMetricCard(
              title: 'Humidity',
              value: humidity == null ? '--' : humidity.toStringAsFixed(0),
              unit: '%',
              icon: Icons.water_drop_rounded,
              color: _metricColor(_humidityState(humidity)),
              state: _humidityState(humidity),
              helper: 'Normal 30-70%',
              minLabel: '30',
              maxLabel: '70',
              progress: _progressFromRange(humidity, 0, 100),
            ),
            StatusMetricCard(
              title: 'Security Alerts',
              value: activeAlerts.toString(),
              unit: activeAlerts == 1 ? 'alert' : 'alerts',
              icon: Icons.notifications_active_rounded,
              color: activeAlerts > 0 ? _danger : _success,
              state: activeAlerts > 0
                  ? MetricState.critical
                  : MetricState.normal,
              helper: 'Unacknowledged warnings',
              minLabel: '0',
              maxLabel: '5+',
              progress: (activeAlerts / 5).clamp(0, 1).toDouble(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentEventsCard(BuildContext context, SentryProvider sentry) {
    final realEvents = sentry.events.take(4).toList();
    final localEvents =
        _localActivity.take(realEvents.isEmpty ? 4 : 2).toList();
    final isEmpty = realEvents.isEmpty && localEvents.isEmpty;
    final children = <Widget>[];

    if (sentry.isLoading && realEvents.isEmpty) {
      children.add(const LoadingStrip(label: 'Loading security events...'));
    } else if (isEmpty) {
      children.add(
        EmptyState(
          icon: Icons.event_available_rounded,
          title: 'No events recorded',
          message:
              'Security activity will appear here after the first sensor or camera event.',
          actionLabel: 'Sync Now',
          onPressed: () => _syncNow(sentry),
        ),
      );
    } else {
      children.addAll([
        for (final activity in localEvents)
          EventRow(
            title: activity.title,
            detail: activity.detail,
            time: activity.time,
            severity: activity.severity,
            icon: activity.icon,
            statusLabel: 'Done',
          ),
        for (final event in realEvents)
          EventRow(
            title: _eventTitle(event),
            detail: event.message,
            time: event.createdAt,
            severity: event.severity,
            icon: _eventIcon(event),
            statusLabel: event.isAcknowledged ? 'Ack' : 'Open',
          ),
      ]);
    }

    return RecentEventsCard(
      subtitle: sentry.isLoading
          ? 'Refreshing activity'
          : 'Latest room activity',
      onViewAllEvents: () => _openEvents(context),
      children: children,
    );
  }

  Future<void> _syncNow(SentryProvider sentry) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await sentry.refreshData();
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _lastSyncAt = DateTime.now();
    });
    _addLocalActivity(
      'Sync completed',
      'Dashboard telemetry refreshed from backend.',
      'info',
      Icons.cloud_done_rounded,
    );
    _showFeedback('Dashboard synced.');
  }

  Future<void> _setSecurityMode(SentryProvider sentry, String mode) async {
    setState(() => _isLocking = true);
    final success = await sentry.updateSecurityMode(mode);
    if (!mounted) return;
    setState(() => _isLocking = false);

    if (!success) {
      _showFeedback(sentry.lastActionError ?? 'Failed to update mode.');
      return;
    }

    _addLocalActivity(
      'Mode changed',
      'Security mode set to ${_securityModeLabel(mode)}.',
      'info',
      _securityModeIcon(mode),
    );
    _showFeedback('Mode set to ${_securityModeLabel(mode)}.');
  }

  void _toggleSecurityMode(SentryProvider sentry) {
    final nextMode = sentry.isArmed ? 'disarmed' : 'working_hours';
    _setSecurityMode(sentry, nextMode);
  }

  Future<void> _takeSnapshot() async {
    setState(() => _isSnapshotLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isSnapshotLoading = false);
    _addLocalActivity(
      'Snapshot captured',
      'Camera snapshot placeholder action completed.',
      'info',
      Icons.photo_camera_rounded,
    );
    _showFeedback('Snapshot action completed.');
    // TODO: Connect this to GET /api/camera/snapshot and evidence storage.
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    _addLocalActivity(
      _isRecording ? 'Recording started' : 'Recording stopped',
      'Camera recording placeholder toggled.',
      _isRecording ? 'warning' : 'info',
      _isRecording
          ? Icons.fiber_manual_record_rounded
          : Icons.stop_circle_rounded,
    );
    _showFeedback(_isRecording ? 'Recording started.' : 'Recording stopped.');
    // TODO: Connect this to a camera recording endpoint.
  }

  void _mockEmergencyAction(String title, String detail, IconData icon) {
    _addLocalActivity(title, detail, 'critical', icon);
    _showFeedback(title);
    // TODO: Send this action to an emergency dispatch or alert backend endpoint.
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required String confirmLabel,
    required Color color,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmModal(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        color: color,
      ),
    );

    if (confirmed == true) {
      onConfirm();
    }
  }

  void _addLocalActivity(
    String title,
    String detail,
    String severity,
    IconData icon,
  ) {
    if (!mounted) return;
    setState(() {
      _localActivity.insert(
        0,
        _CommandActivity(
          title: title,
          detail: detail,
          severity: severity,
          icon: icon,
          time: DateTime.now(),
        ),
      );
      if (_localActivity.length > 8) {
        _localActivity.removeLast();
      }
    });
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _activeAlertCount(SentryProvider sentry) {
    final count = sentry.liveStatus['active_unacknowledged_events'];
    if (count is int) return count;
    return sentry.events
        .where((event) => !event.isAcknowledged && event.severity != 'info')
        .length;
  }

  _ConnectionStatus _connectionStatus(SentryProvider sentry) {
    if (sentry.isLoading && sentry.liveStatus.isEmpty) {
      return const _ConnectionStatus(
        label: 'Connecting',
        color: _warning,
        icon: Icons.sync_rounded,
      );
    }

    final database = sentry.liveStatus['database']?.toString();
    if (database == 'offline') {
      return const _ConnectionStatus(
        label: 'Backend limited',
        color: _warning,
        icon: Icons.cloud_off_rounded,
      );
    }

    return const _ConnectionStatus(
      label: 'Connected',
      color: _success,
      icon: Icons.cloud_done_rounded,
    );
  }

  double? _readNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  MetricState _temperatureState(double? value) {
    if (value == null) return MetricState.standby;
    if (value < 14 || value > 36) return MetricState.critical;
    if (value < 18 || value > 30) return MetricState.warning;
    return MetricState.normal;
  }

  MetricState _humidityState(double? value) {
    if (value == null) return MetricState.standby;
    if (value < 20 || value > 85) return MetricState.critical;
    if (value < 30 || value > 70) return MetricState.warning;
    return MetricState.normal;
  }

  double _progressFromRange(double? value, double min, double max) {
    if (value == null) return 0;
    return ((value - min) / (max - min)).clamp(0, 1).toDouble();
  }

  Color _metricColor(MetricState state) {
    switch (state) {
      case MetricState.normal:
        return _success;
      case MetricState.warning:
        return _warning;
      case MetricState.critical:
        return _danger;
      case MetricState.standby:
        return _accent;
    }
  }

  String _eventTitle(Event event) {
    return event.displayTypeLabel;
  }

  IconData _eventIcon(Event event) {
    switch (event.identityCategory) {
      case 'authorized_person':
        return Icons.verified_user_rounded;
      case 'no_face':
        return Icons.visibility_off_rounded;
      case 'unknown_face':
        return Icons.person_search_rounded;
      case 'fire_warning':
      case 'fire_emergency':
        return Icons.local_fire_department_rounded;
      case 'unauthorized_person':
      case 'unauthorized_entry':
        return Icons.gpp_maybe_rounded;
    }

    if (event.severity == 'critical' ||
        event.eventType.contains('unauthorized')) {
      return Icons.security_rounded;
    }
    if (event.eventType.contains('authorized')) return Icons.login_rounded;
    if (event.eventType.contains('motion')) return Icons.sensors_rounded;
    if (event.eventType.contains('environment')) {
      return Icons.thermostat_rounded;
    }
    return Icons.info_outline_rounded;
  }

  String _securityModeLabel(String mode) {
    switch (mode) {
      case 'disarmed':
        return 'System disarmed';
      case 'locked':
        return 'Room locked';
      case 'working_hours':
      default:
        return 'Working hours';
    }
  }

  String _securityModeDescription(String mode) {
    switch (mode) {
      case 'disarmed':
        return 'Setup mode. Alerts are visible, but active response is paused.';
      case 'locked':
        return 'Room closed. Person activity should be treated as suspicious.';
      case 'working_hours':
      default:
        return 'Daytime monitoring with reduced alert noise.';
    }
  }

  IconData _securityModeIcon(String mode) {
    switch (mode) {
      case 'disarmed':
        return Icons.shield_outlined;
      case 'locked':
        return Icons.lock_rounded;
      case 'working_hours':
      default:
        return Icons.shield_rounded;
    }
  }

  Color _securityModeColor(String mode) {
    switch (mode) {
      case 'disarmed':
        return _warning;
      case 'working_hours':
        return _success;
      case 'locked':
        return _accent;
      default:
        return _success;
    }
  }
}

class _ConnectionStatus {
  final String label;
  final Color color;
  final IconData icon;

  const _ConnectionStatus({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _FireRiskDialog extends StatefulWidget {
  final Event event;

  const _FireRiskDialog({required this.event});

  @override
  State<_FireRiskDialog> createState() => _FireRiskDialogState();
}

class _FireRiskDialogState extends State<_FireRiskDialog> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _acknowledge() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final sentry = context.read<SentryProvider>();
    final success = await sentry.acknowledgeEvent(widget.event.id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(_FireAlertResult.acknowledged);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = sentry.lastActionError ??
          'Failed to acknowledge fire alert. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final emergency = widget.event.isFireEmergency;
    final color = emergency ? _danger : _warning;
    final trigger = _triggerPayload(widget.event);

    return AlertDialog(
      icon: Icon(
        emergency
            ? Icons.local_fire_department_rounded
            : Icons.warning_amber_rounded,
        color: color,
        size: 50,
      ),
      title: Text(
        widget.event.displayTypeLabel,
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.event.fireReason,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _FireDetailRow(
              label: 'Temperature',
              value: _valueWithUnit(trigger['temperature_c'], 'C'),
            ),
            _FireDetailRow(
              label: 'Humidity',
              value: _valueWithUnit(trigger['humidity_percent'], '%'),
            ),
            _FireDetailRow(
              label: 'Light',
              value: _plainValue(trigger['light_value']),
            ),
            _FireDetailRow(
              label: 'Trigger',
              value: _plainValue(trigger['trigger_reason']),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: color),
              ),
            ],
          ],
        ),
      ),
      actions: _buildActions(emergency),
    );
  }

  List<Widget> _buildActions(bool emergency) {
    if (_isSubmitting) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: _acknowledge,
        child: const Text('Acknowledge'),
      ),
      ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pop(
          emergency ? _FireAlertResult.openEmergency : _FireAlertResult.viewEvents,
        ),
        icon: Icon(
          emergency
              ? Icons.local_fire_department_rounded
              : Icons.history_rounded,
        ),
        label: Text(emergency ? 'Open Fire Emergency' : 'View Events'),
      ),
    ];
  }

  Map<String, dynamic> _triggerPayload(Event event) {
    final trigger = event.fireRiskDetails['trigger'];
    if (trigger is Map<String, dynamic>) return trigger;
    if (trigger is Map) return Map<String, dynamic>.from(trigger);
    return {};
  }

  String _valueWithUnit(dynamic value, String unit) {
    if (value == null) return 'Unavailable';
    if (value is num) return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}$unit';
    return '$value$unit';
  }

  String _plainValue(dynamic value) {
    if (value == null) return 'Unavailable';
    return value.toString();
  }
}

class _FireDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _FireDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnauthorizedEntryDialog extends StatefulWidget {
  final Event event;
  final bool isAdmin;
  final bool canAddPerson;

  const _UnauthorizedEntryDialog({
    required this.event,
    required this.isAdmin,
    required this.canAddPerson,
  });

  @override
  State<_UnauthorizedEntryDialog> createState() =>
      _UnauthorizedEntryDialogState();
}

class _UnauthorizedEntryDialogState extends State<_UnauthorizedEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _roleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _showAuthorizeForm = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _roleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _acknowledgeOnly() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final sentry = context.read<SentryProvider>();
    final success = await sentry.acknowledgeEvent(widget.event.id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(_UnauthorizedAlertResult.acknowledged);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = sentry.lastActionError ??
          'Failed to acknowledge event. Please try again.';
    });
  }

  Future<void> _authorizePerson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final sentry = context.read<SentryProvider>();
    final success = await sentry.authorizePersonFromEvent(
      eventId: widget.event.id,
      fullName: _fullNameController.text.trim(),
      role: _roleController.text.trim(),
      notes: _emptyToNull(_notesController.text),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(_UnauthorizedAlertResult.authorized);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = sentry.lastActionError ??
          'Failed to authorize person. Please try again.';
    });
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final alertColor = _alertColor(widget.event.identityCategory);

    return AlertDialog(
      icon: Icon(
        _alertIcon(widget.event.identityCategory),
        color: alertColor,
        size: 48,
      ),
      title: Text(
        widget.event.displayTypeLabel,
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.event.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: alertColor),
              ),
            ],
            if (_showAuthorizeForm) ...[
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _roleController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.work_outline_rounded),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter role';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: _buildActions(),
    );
  }

  Color _alertColor(String category) {
    switch (category) {
      case 'no_face':
        return _warning;
      case 'unknown_face':
      case 'unauthorized_person':
      case 'unauthorized_entry':
        return _danger;
      default:
        return _danger;
    }
  }

  IconData _alertIcon(String category) {
    switch (category) {
      case 'no_face':
        return Icons.visibility_off_rounded;
      case 'unknown_face':
        return Icons.person_search_rounded;
      case 'unauthorized_person':
      case 'unauthorized_entry':
        return Icons.gpp_maybe_rounded;
      default:
        return Icons.gpp_maybe_rounded;
    }
  }

  List<Widget> _buildActions() {
    if (_isSubmitting) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ];
    }

    if (_showAuthorizeForm) {
      return [
        TextButton(
          onPressed: () => setState(() => _showAuthorizeForm = false),
          child: const Text('Back'),
        ),
        ElevatedButton.icon(
          onPressed: _authorizePerson,
          icon: const Icon(Icons.verified_user_rounded),
          label: const Text('Authorize'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: _acknowledgeOnly,
        child: const Text('Acknowledge Only'),
      ),
      if (widget.isAdmin && widget.canAddPerson)
        ElevatedButton.icon(
          onPressed: () => setState(() => _showAuthorizeForm = true),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add Authorized Person'),
        ),
    ];
  }
}
