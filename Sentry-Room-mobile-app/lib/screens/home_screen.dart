<<<<<<< HEAD
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sentry_models.dart';
import '../providers/auth_provider.dart';
import '../providers/sentry_provider.dart';
import 'camera_screen.dart';
import 'events_screen.dart';
import 'people_screen.dart';
import 'profile_screen.dart';
import 'user_management_screen.dart';

const _background = Color(0xFF070B16);
const _surface = Color(0xFF111827);
const _border = Color(0x1FFFFFFF);
const _accent = Color(0xFF38BDF8);
const _success = Color(0xFF34D399);
const _warning = Color(0xFFFBBF24);
const _danger = Color(0xFFFB7185);
=======
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/sentry_provider.dart';
import '../models/sentry_models.dart';
import 'people_screen.dart';
import 'events_screen.dart';
import 'user_management_screen.dart';
import 'camera_screen.dart';
import 'profile_screen.dart';
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _UnauthorizedAlertResult {
  acknowledged,
  authorized,
}

<<<<<<< HEAD
enum _MetricState {
  normal,
  warning,
  critical,
  standby,
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
  final List<_CommandActivity> _localActivity = [];

  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  DateTime? _lastSyncAt;
  int? _activeAlertEventId;
  bool _isArmed = true;
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
=======
class _HomeScreenState extends State<HomeScreen> {
  final Set<int> _alertedUnauthorizedEventIds = {};
  int? _activeAlertEventId;
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be

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

  void _openCamera(BuildContext context) {
    Navigator.push(
<<<<<<< HEAD
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
=======
        context, MaterialPageRoute(builder: (_) => const CameraScreen()));
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
  }

  void _openPeople(BuildContext context) {
    Navigator.push(
<<<<<<< HEAD
      context,
      MaterialPageRoute(builder: (_) => const PeopleScreen()),
    );
=======
        context, MaterialPageRoute(builder: (_) => const PeopleScreen()));
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
  }

  void _openEvents(BuildContext context) {
    Navigator.push(
<<<<<<< HEAD
      context,
      MaterialPageRoute(builder: (_) => const EventsScreen()),
    );
=======
        context, MaterialPageRoute(builder: (_) => const EventsScreen()));
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
  }

  @override
  Widget build(BuildContext context) {
    final sentry = context.watch<SentryProvider>();
    final auth = context.watch<AuthProvider>();

    _queueUnauthorizedAlert(context, sentry, auth);

    return Scaffold(
<<<<<<< HEAD
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
                          _buildHeader(context, auth, sentry),
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
=======
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, auth),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (auth.isAdmin) ...[
                    _buildAdminControlPanel(context, sentry),
                    const SizedBox(height: 28),
                  ],
                  Text('Environment Status',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildLiveStatusGrid(context, sentry),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Security Log', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EventsScreen()));
                  }),
                  const SizedBox(height: 16),
                  _buildEventList(context, sentry),
                ],
              ),
            ),
          ),
        ],
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
      ),
      bottomNavigationBar: _buildBottomNav(context, auth),
    );
  }

<<<<<<< HEAD
  Widget _buildHeader(
    BuildContext context,
    AuthProvider auth,
    SentryProvider sentry,
  ) {
    final activeAlerts = _activeAlertCount(sentry);
    final connection = _connectionStatus(sentry);
    final systemColor =
        activeAlerts > 0 ? _danger : (_isArmed ? _success : _warning);
    final userName = auth.fullName ?? auth.username ?? 'Operator';

    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusBadge(
                    label: activeAlerts > 0
                        ? '$activeAlerts active alert${activeAlerts == 1 ? '' : 's'}'
                        : (_isArmed ? 'System armed' : 'System disarmed'),
                    color: systemColor,
                    icon: activeAlerts > 0
                        ? Icons.report_problem_rounded
                        : Icons.verified_user_rounded,
                  ),
                  _StatusBadge(
                    label: connection.label,
                    color: connection.color,
                    icon: connection.icon,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Welcome, $userName',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: isCompact ? 24 : 30,
                      height: 1.05,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Room security command center',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          );

          final tools = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _HeaderChip(
                icon: Icons.schedule_rounded,
                label: DateFormat('HH:mm:ss').format(_now),
                tooltip: DateFormat('EEEE, MMM d, yyyy').format(_now),
              ),
              _HeaderIconButton(
                tooltip: 'Open live camera',
                icon: Icons.videocam_rounded,
                onPressed: () => _openCamera(context),
              ),
              if (auth.isAdmin)
                _HeaderIconButton(
                  tooltip: 'Open user management',
                  icon: Icons.manage_accounts_rounded,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementScreen(),
                    ),
                  ),
                ),
              _HeaderIconButton(
                tooltip: 'Open profile',
                icon: Icons.account_circle_outlined,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 18),
                tools,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 24),
              tools,
            ],
          );
        },
=======
  Widget _buildAppBar(BuildContext context, AuthProvider auth) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text('Welcome, ${auth.fullName ?? auth.username}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                Colors.transparent
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded),
          tooltip: 'Live Camera',
          onPressed: () => _openCamera(context),
        ),
        if (auth.isAdmin)
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: 'User Management',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const UserManagementScreen())),
          ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          tooltip: 'Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminControlPanel(BuildContext context, SentryProvider sentry) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.01)
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.blueAccent),
                    SizedBox(width: 12),
                    Text('Global Monitoring',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Switch.adaptive(
                  value: sentry.notifyAllUsers,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: (val) => sentry.setNotifyAllUsers(val),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(context, Icons.lock_outline, 'Lock Room'),
                _buildQuickAction(
                    context, Icons.emergency_share_outlined, 'Panic Mode',
                    color: Colors.redAccent),
                _buildQuickAction(context, Icons.refresh_rounded, 'Sync',
                    onTap: sentry.refreshData),
              ],
            )
          ],
        ),
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
      ),
    );
  }

<<<<<<< HEAD
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
            ? _buildGlobalMonitoringPanel(context, sentry)
            : _buildViewerMonitoringPanel(context, sentry);

        final topContent = sideBySide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: wide ? 7 : 6, child: commandPanel),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: wide ? 5 : 4, child: _buildLiveCameraCard(context)),
                ],
              )
            : Column(
                children: [
                  commandPanel,
                  const SizedBox(height: 16),
                  _buildLiveCameraCard(context),
                ],
              );

        final lowerContent = sideBySide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildAccessControlCard(context, sentry)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRecentEventsCard(context, sentry)),
                ],
              )
            : Column(
                children: [
                  _buildAccessControlCard(context, sentry),
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
=======
  Widget _buildQuickAction(BuildContext context, IconData icon, String label,
      {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor:
                (color ?? Colors.blueAccent).withValues(alpha: 0.1),
            child: Icon(icon, color: color ?? Colors.blueAccent, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildLiveStatusGrid(BuildContext context, SentryProvider sentry) {
    final readings = sentry.liveStatus['latest_readings'] as Map? ?? {};
    final env = readings['temperature_humidity'] as Map? ?? {};
    final distance = readings['distance'] as Map? ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatusCard(
            context,
            'Temperature',
            env['temperature_c']?.toString() ?? '--',
            '°C',
            Icons.thermostat_rounded,
            Colors.orangeAccent),
        _buildStatusCard(
            context,
            'Humidity',
            env['humidity_percent']?.toString() ?? '--',
            '%',
            Icons.water_drop_rounded,
            Colors.cyanAccent),
        _buildStatusCard(
            context,
            'Security Status',
            sentry.liveStatus['active_unacknowledged_events']?.toString() ??
                '0',
            'Alerts',
            Icons.gpp_maybe_rounded,
            Colors.redAccent),
        _buildStatusCard(
            context,
            'Room Range',
            distance['distance_cm']?.toString() ?? '--',
            'cm',
            Icons.sensors_rounded,
            Colors.greenAccent),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, String value,
      String unit, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.3)),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                Text('$title ($unit)',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(
            onPressed: onTap,
            child: const Text('View All',
                style: TextStyle(color: Colors.blueAccent))),
      ],
    );
  }

  Widget _buildEventList(BuildContext context, SentryProvider sentry) {
    if (sentry.events.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No recent activity recorded.')));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sentry.events.take(5).length,
      itemBuilder: (context, index) {
        final event = sentry.events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1E33),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _getEventIconBox(event.eventType, event.severity),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.message,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(DateFormat('HH:mm').format(event.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),
              if (!event.isAcknowledged)
                const CircleAvatar(
                    radius: 4, backgroundColor: Colors.blueAccent),
            ],
          ),
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
        );
      },
    );
  }

<<<<<<< HEAD
  Widget _buildGlobalMonitoringPanel(
    BuildContext context,
    SentryProvider sentry,
  ) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Global Monitoring',
            subtitle: 'Security controls for the room perimeter',
            trailing: Semantics(
              label: 'Monitoring enabled toggle',
              child: Switch.adaptive(
                value: sentry.notifyAllUsers,
                activeThumbColor: _accent,
                onChanged: (value) {
                  sentry.setNotifyAllUsers(value);
                  _addLocalActivity(
                    value
                        ? 'Monitoring notifications enabled'
                        : 'Monitoring notifications muted',
                    'Operator changed global notification routing.',
                    'info',
                    Icons.notifications_active_rounded,
                  );
                  _showFeedback(
                    value
                        ? 'Monitoring notifications enabled.'
                        : 'Monitoring notifications muted.',
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ArmDisarmControl(
            isArmed: _isArmed,
            onChanged: () {
              setState(() => _isArmed = !_isArmed);
              _addLocalActivity(
                _isArmed ? 'System armed' : 'System disarmed',
                _isArmed
                    ? 'Sensors and alerts are active.'
                    : 'Security monitoring is in standby.',
                _isArmed ? 'info' : 'warning',
                _isArmed ? Icons.shield_rounded : Icons.shield_outlined,
              );
              _showFeedback(_isArmed ? 'System armed.' : 'System disarmed.');
            },
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
                  _ActionTile(
                    label: _isLocking ? 'Locking' : 'Lock Room',
                    icon: _isLocking
                        ? Icons.hourglass_top_rounded
                        : Icons.lock_outline_rounded,
                    color: _accent,
                    tooltip: 'Lock the room door',
                    onPressed: _isLocking
                        ? null
                        : () => _confirmAndRun(
                              title: 'Lock room?',
                              message:
                                  'This will mark the room as locked in the command center. Connect this to the door lock API when hardware control is ready.',
                              confirmLabel: 'Lock Room',
                              color: _warning,
                              onConfirm: _lockRoom,
                            ),
                  ),
                  _ActionTile(
                    label: 'Panic Mode',
                    icon: Icons.emergency_share_outlined,
                    color: _danger,
                    isPrimary: true,
                    tooltip: 'Trigger panic mode confirmation',
                    onPressed: () => _confirmAndRun(
                      title: 'Trigger panic mode?',
                      message:
                          'Panic Mode should notify security and mark the room as critical. This dashboard action is currently mocked until an emergency endpoint is connected.',
                      confirmLabel: 'Trigger',
                      color: _danger,
                      onConfirm: () => _mockEmergencyAction(
                        'Panic mode triggered',
                        'Security escalation placeholder was activated.',
                        Icons.emergency_share_rounded,
                      ),
                    ),
                  ),
                  _ActionTile(
                    label: _isSyncing ? 'Syncing' : 'Sync',
                    icon: _isSyncing
                        ? Icons.sync_rounded
                        : Icons.cloud_sync_rounded,
                    color: _success,
                    tooltip: 'Refresh room telemetry',
                    onPressed: _isSyncing ? null : () => _syncNow(sentry),
                  ),
                  _ActionTile(
                    label: 'Alert Security',
                    icon: Icons.support_agent_rounded,
                    color: _warning,
                    tooltip: 'Send emergency alert confirmation',
                    onPressed: () => _confirmAndRun(
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
                  ),
                  _ActionTile(
                    label: 'Lockdown',
                    icon: Icons.gpp_maybe_rounded,
                    color: _danger,
                    tooltip: 'Start lockdown confirmation',
                    onPressed: () => _confirmAndRun(
                      title: 'Start lockdown?',
                      message:
                          'Lockdown is a critical action. This visual control is ready for a future backend endpoint.',
                      confirmLabel: 'Lockdown',
                      color: _danger,
                      onConfirm: () => _mockEmergencyAction(
                        'Lockdown started',
                        'Critical lockdown placeholder was activated.',
                        Icons.gpp_maybe_rounded,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewerMonitoringPanel(
    BuildContext context,
    SentryProvider sentry,
  ) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.visibility_rounded,
            title: 'Monitoring Overview',
            subtitle: 'Live room status and security activity',
          ),
          const SizedBox(height: 18),
          _ArmDisarmControl(
            isArmed: _isArmed,
            isReadOnly: true,
            onChanged: () {},
          ),
          const SizedBox(height: 18),
          _ActionTile(
            label: _isSyncing ? 'Syncing' : 'Sync Dashboard',
            icon: Icons.cloud_sync_rounded,
            color: _success,
            tooltip: 'Refresh room telemetry',
            onPressed: _isSyncing ? null : () => _syncNow(sentry),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentStatus(
    BuildContext context,
    SentryProvider sentry,
    double availableWidth,
  ) {
    final readings = sentry.liveStatus['latest_readings'] as Map? ?? {};
    final env = readings['temperature_humidity'] as Map? ?? {};
    final distance = readings['distance'] as Map? ?? {};
    final temperature = _readNumber(env['temperature_c']);
    final humidity = _readNumber(env['humidity_percent']);
    final roomRange = _readNumber(distance['distance_cm']);
    final activeAlerts = _activeAlertCount(sentry);
    final columns = availableWidth >= 1050
        ? 4
        : availableWidth >= 640
            ? 2
            : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
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
          childAspectRatio: columns == 1 ? 2.35 : 1.35,
          children: [
            _StatusMetricCard(
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
            _StatusMetricCard(
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
            _StatusMetricCard(
              title: 'Motion Range',
              value: roomRange == null ? '--' : roomRange.toStringAsFixed(0),
              unit: 'cm',
              icon: Icons.sensors_rounded,
              color: _metricColor(_distanceState(roomRange)),
              state: _distanceState(roomRange),
              helper: 'Alert below 30 cm',
              minLabel: '30',
              maxLabel: '120',
              progress: _progressFromRange(roomRange, 0, 160),
            ),
            _StatusMetricCard(
              title: 'Security Alerts',
              value: activeAlerts.toString(),
              unit: activeAlerts == 1 ? 'alert' : 'alerts',
              icon: Icons.notifications_active_rounded,
              color: activeAlerts > 0 ? _danger : _success,
              state: activeAlerts > 0
                  ? _MetricState.critical
                  : _MetricState.normal,
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

  Widget _buildLiveCameraCard(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.videocam_rounded,
            title: 'Live Camera',
            subtitle: _isRecording ? 'Recording active' : 'Stream ready',
            trailing: _StatusBadge(
              label: _isRecording ? 'Recording' : 'Online',
              color: _isRecording ? _danger : _success,
              icon: _isRecording ? Icons.fiber_manual_record : Icons.circle,
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
                      painter: _CameraGridPainter(),
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
                    child: _StatusBadge(
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
              _CommandButton(
                label: 'View Camera',
                icon: Icons.open_in_full_rounded,
                color: _accent,
                onPressed: () => _openCamera(context),
              ),
              _CommandButton(
                label: _isSnapshotLoading ? 'Capturing' : 'Snapshot',
                icon: Icons.photo_camera_rounded,
                color: _success,
                onPressed: _isSnapshotLoading ? null : _takeSnapshot,
              ),
              _CommandButton(
                label: _isRecording ? 'Stop Record' : 'Record',
                icon: _isRecording
                    ? Icons.stop_circle_rounded
                    : Icons.fiber_manual_record_rounded,
                color: _isRecording ? _danger : _warning,
                onPressed: _toggleRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessControlCard(BuildContext context, SentryProvider sentry) {
    final authorizedCount =
        sentry.persons.where((person) => person.isAuthorized).length;
    final totalPeople = sentry.persons.length;
    final doorStatus = _isArmed ? 'Secured' : 'Standby';

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.badge_rounded,
            title: 'Access Control',
            subtitle: 'Door and authorized-person oversight',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Door',
                  value: doorStatus,
                  icon: _isArmed ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: _isArmed ? _success : _warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Authorized',
                  value: '$authorizedCount/$totalPeople',
                  icon: Icons.verified_user_rounded,
                  color: _accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CommandButton(
                label: 'Add Visitor',
                icon: Icons.person_add_alt_1_rounded,
                color: _success,
                onPressed: () {
                  _showFeedback(
                      'Visitor enrollment form opens from Manage Access.');
                  _openPeople(context);
                },
              ),
              _CommandButton(
                label: 'Manage Access',
                icon: Icons.manage_accounts_rounded,
                color: _accent,
                onPressed: () => _openPeople(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEventsCard(BuildContext context, SentryProvider sentry) {
    final realEvents = sentry.events.take(4).toList();
    final localEvents =
        _localActivity.take(realEvents.isEmpty ? 4 : 2).toList();
    final isEmpty = realEvents.isEmpty && localEvents.isEmpty;

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.history_rounded,
            title: 'Recent Events',
            subtitle: sentry.isLoading
                ? 'Refreshing activity'
                : 'Latest room activity',
            trailing: TextButton(
              onPressed: () => _openEvents(context),
              child: const Text('View All Events'),
            ),
          ),
          const SizedBox(height: 12),
          if (sentry.isLoading && realEvents.isEmpty)
            const _LoadingStrip(label: 'Loading security events...')
          else if (isEmpty)
            _EmptyState(
              icon: Icons.event_available_rounded,
              title: 'No events recorded',
              message:
                  'Security activity will appear here after the first sensor or camera event.',
              actionLabel: 'Sync Now',
              onPressed: () => _syncNow(sentry),
            )
          else ...[
            for (final activity in localEvents)
              _EventRow(
                title: activity.title,
                detail: activity.detail,
                time: activity.time,
                severity: activity.severity,
                icon: activity.icon,
                statusLabel: 'Done',
              ),
            for (final event in realEvents)
              _EventRow(
                title: _eventTitle(event),
                detail: event.message,
                time: event.createdAt,
                severity: event.severity,
                icon: _eventIcon(event.eventType, event.severity),
                statusLabel: event.isAcknowledged ? 'Ack' : 'Open',
              ),
          ],
        ],
      ),
=======
  Widget _getEventIconBox(String type, String severity) {
    Color color = Colors.blue;
    IconData icon = Icons.info_outline;

    if (severity == 'critical' || type.contains('unauthorized')) {
      color = Colors.redAccent;
      icon = Icons.security_rounded;
    } else if (type.contains('entry')) {
      color = Colors.greenAccent;
      icon = Icons.login_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 20),
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
    );
  }

  Widget _buildBottomNav(BuildContext context, AuthProvider auth) {
<<<<<<< HEAD
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.grid_view_rounded),
        selectedIcon: Icon(Icons.grid_view_rounded),
        label: 'Monitor',
      ),
      const NavigationDestination(
        icon: Icon(Icons.videocam_outlined),
        selectedIcon: Icon(Icons.videocam_rounded),
        label: 'Camera',
      ),
      if (auth.isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.people_alt_outlined),
          selectedIcon: Icon(Icons.people_alt_rounded),
          label: 'Access',
        ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history_rounded),
        label: 'Events',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_suggest_outlined),
        selectedIcon: Icon(Icons.settings_suggest_rounded),
        label: 'Settings',
      ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF080D18),
        border: Border(top: BorderSide(color: _border)),
      ),
      child: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: _accent.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: destinations,
        onDestinationSelected: (index) {
          if (index == 0) return;
          if (index == 1) {
            _openCamera(context);
            return;
          }

          if (auth.isAdmin) {
            if (index == 2) {
              _openPeople(context);
            } else if (index == 3) {
              _openEvents(context);
            } else {
              _showFeedback(
                  'Settings screen is ready for backend preferences.');
            }
            return;
          }

          if (index == 2) {
            _openEvents(context);
          } else {
            _showFeedback('Settings screen is ready for backend preferences.');
          }
        },
      ),
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

  Future<void> _lockRoom() async {
    setState(() => _isLocking = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _isLocking = false;
      _isArmed = true;
    });
    _addLocalActivity(
      'Door locked',
      'Primary room lock command completed locally.',
      'info',
      Icons.lock_rounded,
    );
    _showFeedback('Room marked as locked.');
    // TODO: Connect this action to the physical door-lock backend endpoint.
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
      builder: (context) => _ConfirmModal(
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

  _MetricState _temperatureState(double? value) {
    if (value == null) return _MetricState.standby;
    if (value < 14 || value > 36) return _MetricState.critical;
    if (value < 18 || value > 30) return _MetricState.warning;
    return _MetricState.normal;
  }

  _MetricState _humidityState(double? value) {
    if (value == null) return _MetricState.standby;
    if (value < 20 || value > 85) return _MetricState.critical;
    if (value < 30 || value > 70) return _MetricState.warning;
    return _MetricState.normal;
  }

  _MetricState _distanceState(double? value) {
    if (value == null) return _MetricState.standby;
    if (value < 30) return _MetricState.critical;
    if (value < 60) return _MetricState.warning;
    return _MetricState.normal;
  }

  double _progressFromRange(double? value, double min, double max) {
    if (value == null) return 0;
    return ((value - min) / (max - min)).clamp(0, 1).toDouble();
  }

  Color _metricColor(_MetricState state) {
    switch (state) {
      case _MetricState.normal:
        return _success;
      case _MetricState.warning:
        return _warning;
      case _MetricState.critical:
        return _danger;
      case _MetricState.standby:
        return _accent;
    }
  }

  String _eventTitle(Event event) {
    return event.eventType
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  IconData _eventIcon(String type, String severity) {
    if (severity == 'critical' || type.contains('unauthorized')) {
      return Icons.security_rounded;
    }
    if (type.contains('authorized')) return Icons.login_rounded;
    if (type.contains('motion')) return Icons.sensors_rounded;
    if (type.contains('environment')) return Icons.thermostat_rounded;
    return Icons.info_outline_rounded;
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

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBubble(icon: icon, color: _accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
=======
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0A0E21),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white24,
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded), label: 'Monitor'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.videocam_rounded), label: 'Camera'),
        if (auth.isAdmin)
          const BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded), label: 'Access'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded), label: 'Events'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.settings_suggest_rounded), label: 'Settings'),
      ],
      onTap: (index) {
        if (index == 0) return;
        if (index == 1) {
          _openCamera(context);
          return;
        }

        if (auth.isAdmin) {
          if (index == 2) _openPeople(context);
          if (index == 3) _openEvents(context);
        } else {
          if (index == 2) _openEvents(context);
        }
      },
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
    );
  }
}

<<<<<<< HEAD
class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionLabel;

  const _SectionTitle({
    required this.title,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        Text(
          actionLabel,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;

  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.07),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _ArmDisarmControl extends StatelessWidget {
  final bool isArmed;
  final bool isReadOnly;
  final VoidCallback onChanged;

  const _ArmDisarmControl({
    required this.isArmed,
    required this.onChanged,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isArmed ? _success : _warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _IconBubble(
            icon: isArmed ? Icons.shield_rounded : Icons.shield_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArmed ? 'System Armed' : 'System Disarmed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isArmed
                      ? 'Door, camera, and sensor alerts are active.'
                      : 'Alerts are visible, but active response is paused.',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (!isReadOnly) ...[
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: onChanged,
              icon: Icon(isArmed
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_rounded),
              label: Text(isArmed ? 'Disarm' : 'Arm'),
              style: FilledButton.styleFrom(
                foregroundColor: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String tooltip;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            focusColor: color.withValues(alpha: 0.22),
            child: Ink(
              decoration: BoxDecoration(
                color: (isPrimary ? color : Colors.white).withValues(
                  alpha: enabled ? (isPrimary ? 0.16 : 0.055) : 0.025,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: enabled ? 0.28 : 0.08),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IconBubble(
                      icon: icon,
                      color: enabled ? color : Colors.white30,
                      size: 42,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _CommandButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.11),
        disabledForegroundColor: Colors.white38,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _StatusMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final _MetricState state;
  final String helper;
  final String minLabel;
  final String maxLabel;
  final double progress;

  const _StatusMetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.state,
    required this.helper,
    required this.minLabel,
    required this.maxLabel,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _IconBubble(icon: icon, color: color),
              const Spacer(),
              _StatusBadge(
                label: _stateLabel(state),
                color: color,
                icon: _stateIcon(state),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Text(maxLabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  String _stateLabel(_MetricState state) {
    switch (state) {
      case _MetricState.normal:
        return 'Normal';
      case _MetricState.warning:
        return 'Warning';
      case _MetricState.critical:
        return 'Critical';
      case _MetricState.standby:
        return 'Standby';
    }
  }

  IconData _stateIcon(_MetricState state) {
    switch (state) {
      case _MetricState.normal:
        return Icons.check_circle_rounded;
      case _MetricState.warning:
        return Icons.warning_rounded;
      case _MetricState.critical:
        return Icons.report_rounded;
      case _MetricState.standby:
        return Icons.hourglass_empty_rounded;
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final String title;
  final String detail;
  final DateTime time;
  final String severity;
  final IconData icon;
  final String statusLabel;

  const _EventRow({
    required this.title,
    required this.detail,
    required this.time,
    required this.severity,
    required this.icon,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _IconBubble(icon: icon, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(time),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusBadge(
            label: statusLabel,
            color: color,
            icon: statusLabel == 'Open'
                ? Icons.radio_button_checked_rounded
                : Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return _danger;
      case 'warning':
        return _warning;
      default:
        return _accent;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: icon, color: _accent),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: Colors.white54, height: 1.35),
          ),
          const SizedBox(height: 14),
          _CommandButton(
            label: actionLabel,
            icon: Icons.sync_rounded,
            color: _accent,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _LoadingStrip extends StatelessWidget {
  final String label;

  const _LoadingStrip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBubble({
    required this.icon,
    required this.color,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class _ConfirmModal extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color color;

  const _ConfirmModal({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: color, size: 42),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, height: 1.35),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check_rounded),
          label: Text(confirmLabel),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    final glowPaint = Paint()
      ..color = _accent.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (double x = size.width / 4; x < size.width; x += size.width / 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = size.height / 3; y < size.height; y += size.height / 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
        const Radius.circular(14),
      ),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

=======
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
class _UnauthorizedEntryDialog extends StatefulWidget {
  final Event event;
  final bool isAdmin;

  const _UnauthorizedEntryDialog({
    required this.event,
    required this.isAdmin,
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
    return AlertDialog(
<<<<<<< HEAD
      icon: const Icon(
        Icons.gpp_maybe_rounded,
        color: _danger,
        size: 48,
      ),
=======
      icon: const Icon(Icons.gpp_maybe_rounded,
          color: Colors.redAccent, size: 48),
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
      title: const Text(
        'Unauthorized Entry',
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
<<<<<<< HEAD
                style: const TextStyle(color: _danger),
=======
                style: const TextStyle(color: Colors.redAccent),
>>>>>>> 2c364f3a32ae1b8136e9f783c079459330e907be
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
      if (widget.isAdmin)
        ElevatedButton.icon(
          onPressed: () => setState(() => _showAuthorizeForm = true),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Authorize This Person'),
        ),
    ];
  }
}
