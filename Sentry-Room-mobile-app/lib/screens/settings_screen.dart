import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSaving = false;

  Future<void> _updateSettings({
    bool? criticalAlerts,
    bool? cameraAlerts,
    bool? eventNotifications,
    bool? compactDashboard,
    bool? saveActivityLocally,
  }) async {
    final auth = context.read<AuthProvider>();

    setState(() => _isSaving = true);

    final success = await auth.updateSettings(
      criticalAlerts: criticalAlerts ?? auth.criticalAlerts,
      cameraAlerts: cameraAlerts ?? auth.cameraAlerts,
      eventNotifications: eventNotifications ?? auth.eventNotifications,
      compactDashboard: compactDashboard ?? auth.compactDashboard,
      saveActivityLocally: saveActivityLocally ?? auth.saveActivityLocally,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Setting updated.'
              : auth.errorMessage ?? 'Failed to update setting.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: _danger, size: 42),
        title: const Text('Logout?'),
        content: const Text(
          'Your session will be cleared and you will return to the login screen.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: FilledButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final auth = context.read<AuthProvider>();
    await auth.logout();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openPeople() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PeopleScreen()),
    );
  }

  void _openEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventsScreen()),
    );
  }

  void _openUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.fullName ?? auth.username ?? 'Operator';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D18),
        foregroundColor: Colors.white,
        title: const Text('Settings'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: _isSaving ? null : _openProfile,
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(auth, userName),
                        const SizedBox(height: 18),
                        _buildAccountSection(auth),
                        const SizedBox(height: 18),
                        _buildPreferencesSection(auth),
                        const SizedBox(height: 18),
                        _buildSecuritySection(auth),
                        if (auth.isAdmin) ...[
                          const SizedBox(height: 18),
                          _buildAdminSection(),
                        ],
                        const SizedBox(height: 18),
                        _buildAboutSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, String userName) {
    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _IconBubble(
            icon: Icons.settings_suggest_rounded,
            color: _accent,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control Center Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Manage account, alerts, preferences, and admin shortcuts for $userName.',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusBadge(
            label: auth.isAdmin ? 'Admin' : 'Viewer',
            color: auth.isAdmin ? _warning : _accent,
            icon: auth.isAdmin
                ? Icons.admin_panel_settings_rounded
                : Icons.visibility_rounded,
          ),
        ],
      ),
    );
  }
  Widget _buildAdminSection() {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Admin Tools',
            subtitle: 'Quick access to administrator screens',
          ),
          const SizedBox(height: 14),
          _ActionRow(
            icon: Icons.manage_accounts_rounded,
            title: 'User Management',
            subtitle: 'Update user roles and account status.',
            color: _warning,
            onTap: _openUserManagement,
          ),
          _ActionRow(
            icon: Icons.people_alt_outlined,
            title: 'Manage Access',
            subtitle: 'View and manage authorized people.',
            color: _accent,
            onTap: _openPeople,
          ),
          _ActionRow(
            icon: Icons.history_rounded,
            title: 'Events & Logs',
            subtitle: 'Review room security events.',
            color: _success,
            onTap: _openEvents,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(AuthProvider auth) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.person_rounded,
            title: 'Account',
            subtitle: 'Profile identity and current session',
          ),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.badge_outlined,
            title: auth.fullName?.isNotEmpty == true
                ? auth.fullName!
                : 'No full name',
            subtitle: auth.username ?? 'No username',
            color: _accent,
          ),
          const SizedBox(height: 10),
          _InfoTile(
            icon: Icons.email_outlined,
            title: auth.email ?? 'No email saved',
            subtitle: 'Account email',
            color: _success,
          ),
          const SizedBox(height: 10),
          _InfoTile(
            icon: Icons.verified_user_outlined,
            title: auth.role ?? (auth.isAdmin ? 'Admin' : 'Viewer'),
            subtitle: auth.isActive ? 'Active account' : 'Inactive account',
            color: auth.isActive ? _success : _danger,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CommandButton(
                label: 'Edit Profile',
                icon: Icons.edit_rounded,
                color: _accent,
                onPressed: _isSaving ? null : _openProfile,
              ),
              _CommandButton(
                label: 'Logout',
                icon: Icons.logout_rounded,
                color: _danger,
                onPressed: _isSaving ? null : _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(AuthProvider auth) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.tune_rounded,
            title: 'App Preferences',
            subtitle: 'Settings saved through AuthProvider',
          ),
          const SizedBox(height: 14),
          _SettingSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Critical Alerts',
            subtitle: 'Show warnings for unauthorized or dangerous activity.',
            value: auth.criticalAlerts,
            color: _danger,
            enabled: !_isSaving,
            onChanged: (value) => _updateSettings(criticalAlerts: value),
          ),
          _SettingSwitchTile(
            icon: Icons.videocam_outlined,
            title: 'Camera Alerts',
            subtitle: 'Enable camera-related notification preferences.',
            value: auth.cameraAlerts,
            color: _accent,
            enabled: !_isSaving,
            onChanged: (value) => _updateSettings(cameraAlerts: value),
          ),
          _SettingSwitchTile(
            icon: Icons.history_rounded,
            title: 'Event Notifications',
            subtitle: 'Notify when new room events are detected.',
            value: auth.eventNotifications,
            color: _warning,
            enabled: !_isSaving,
            onChanged: (value) => _updateSettings(eventNotifications: value),
          ),
          _SettingSwitchTile(
            icon: Icons.space_dashboard_outlined,
            title: 'Compact Dashboard',
            subtitle: 'Prepare a denser dashboard layout preference.',
            value: auth.compactDashboard,
            color: _success,
            enabled: !_isSaving,
            onChanged: (value) => _updateSettings(compactDashboard: value),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(AuthProvider auth) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.shield_rounded,
            title: 'Security Preferences',
            subtitle: 'Local preference controls for the security dashboard',
          ),
          const SizedBox(height: 14),
          _SettingSwitchTile(
            icon: Icons.storage_rounded,
            title: 'Save Activity Locally',
            subtitle: 'Keep settings and session values on this device.',
            value: auth.saveActivityLocally,
            color: _success,
            enabled: !_isSaving,
            onChanged: (value) => _updateSettings(saveActivityLocally: value),
          ),
          const SizedBox(height: 12),
          const _NoticeBox(
            icon: Icons.cloud_sync_outlined,
            title: 'Ready for backend sync',
            message:
                'The frontend is now organized through AuthProvider. When backend settings endpoints are added, only AuthProvider needs to call ApiService.',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PanelHeader(
            icon: Icons.info_outline_rounded,
            title: 'About Sentry Room',
            subtitle: 'Room security monitoring application',
          ),
          SizedBox(height: 14),
          _InfoTile(
            icon: Icons.security_rounded,
            title: 'Sentry Room',
            subtitle: 'Security command center prototype',
            color: _accent,
          ),
          SizedBox(height: 10),
          _InfoTile(
            icon: Icons.devices_rounded,
            title: 'Local Settings',
            subtitle: 'Preferences are currently stored on this device',
            color: _success,
          ),
        ],
      ),
    );
  }
  
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
      child: Row(
        children: [
          _IconBubble(icon: icon, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeThumbColor: color,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
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
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _NoticeBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
