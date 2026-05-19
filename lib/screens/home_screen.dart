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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _UnauthorizedAlertResult {
  acknowledged,
  authorized,
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<int> _alertedUnauthorizedEventIds = {};
  int? _activeAlertEventId;

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
        context, MaterialPageRoute(builder: (_) => const CameraScreen()));
  }

  void _openPeople(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PeopleScreen()));
  }

  void _openEvents(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const EventsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final sentry = context.watch<SentryProvider>();
    final auth = context.watch<AuthProvider>();

    _queueUnauthorizedAlert(context, sentry, auth);

    return Scaffold(
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
      ),
      bottomNavigationBar: _buildBottomNav(context, auth),
    );
  }

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
          onPressed: () => auth.logout(),
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
      ),
    );
  }

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
        );
      },
    );
  }

  Widget _getEventIconBox(String type, String severity) {
    Color color = Colors.blue;
    IconData icon = Icons.info_outline;

    if (severity == 'danger' || type.contains('unauthorized')) {
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
    );
  }

  Widget _buildBottomNav(BuildContext context, AuthProvider auth) {
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
    );
  }
}

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
      icon: const Icon(Icons.gpp_maybe_rounded,
          color: Colors.redAccent, size: 48),
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
                style: const TextStyle(color: Colors.redAccent),
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
