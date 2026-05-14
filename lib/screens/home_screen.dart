import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/sentry_provider.dart';
import '../models/sentry_models.dart';
import 'people_screen.dart';
import 'events_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _handleUnauthorizedAlert(BuildContext context, Event event) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Unauthorized Alert',
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return ScaleTransition(
          scale: anim1,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gpp_maybe_rounded, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 20),
                    const Text(
                      'SECURITY BREACH',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('DISMISS', style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (event.personId != null) {
                                context.read<SentryProvider>().authorizePerson(event.personId!);
                              }
                              context.read<SentryProvider>().acknowledgeEvent(event.id);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 10,
                            ),
                            child: const Text('AUTHORIZE', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentry = context.watch<SentryProvider>();
    final auth = context.watch<AuthProvider>();

    // Detect new unauthorized events
    final unauthorizedEvent = sentry.events.firstWhere(
      (e) => e.eventType == 'unauthorized_entry' && !e.isAcknowledged,
      orElse: () => Event(id: -1, eventType: '', severity: '', message: '', isAcknowledged: true, createdAt: DateTime.now()),
    );

    if (unauthorizedEvent.id != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUnauthorizedAlert(context, unauthorizedEvent);
      });
    }

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
                  _buildAdminControlPanel(context, sentry),
                  const SizedBox(height: 28),
                  Text('Environment Status', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildLiveStatusGrid(context, sentry),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Security Log', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
                  }),
                  const SizedBox(height: 16),
                  _buildEventList(context, sentry),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider auth) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text('Welcome, ${auth.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary.withOpacity(0.2), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {},
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
            colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, color: Colors.blueAccent),
                    SizedBox(width: 12),
                    Text('Global Monitoring', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Switch.adaptive(
                  value: sentry.notifyAllUsers,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) => sentry.setNotifyAllUsers(val),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(context, Icons.lock_outline, 'Lock Room'),
                _buildQuickAction(context, Icons.emergency_share_outlined, 'Panic Mode', color: Colors.redAccent),
                _buildQuickAction(context, Icons.refresh_rounded, 'Sync', onTap: sentry.refreshData),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: (color ?? Colors.blueAccent).withOpacity(0.1),
            child: Icon(icon, color: color ?? Colors.blueAccent, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildLiveStatusGrid(BuildContext context, SentryProvider sentry) {
    final readings = sentry.liveStatus['latest_readings'] as Map? ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatusCard(context, 'Temperature', readings['temperature_c']?.toString() ?? '--', '°C', Icons.thermostat_rounded, Colors.orangeAccent),
        _buildStatusCard(context, 'Humidity', readings['humidity_percent']?.toString() ?? '--', '%', Icons.water_drop_rounded, Colors.cyanAccent),
        _buildStatusCard(context, 'Security Status', sentry.liveStatus['active_unacknowledged_events']?.toString() ?? '0', 'Alerts', Icons.gpp_maybe_rounded, Colors.redAccent),
        _buildStatusCard(context, 'Room Occupancy', 'Detected', 'Live', Icons.people_outline_rounded, Colors.greenAccent),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, String value, String unit, IconData icon, Color color) {
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
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.3)),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text('$title ($unit)', style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(onPressed: onTap, child: const Text('View All', style: TextStyle(color: Colors.blueAccent))),
      ],
    );
  }

  Widget _buildEventList(BuildContext context, SentryProvider sentry) {
    if (sentry.events.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No recent activity recorded.')));
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
                    Text(event.message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(DateFormat('HH:mm').format(event.createdAt), style: const TextStyle(fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),
              if (!event.isAcknowledged)
                const CircleAvatar(radius: 4, backgroundColor: Colors.blueAccent),
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0A0E21),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white24,
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Monitor'),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'People'),
        BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Events'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_suggest_rounded), label: 'Settings'),
      ],
      onTap: (index) {
        if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const PeopleScreen()));
        if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
      },
    );
  }
}
