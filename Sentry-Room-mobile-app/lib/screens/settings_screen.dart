import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/api_constants.dart';
import '../widgets/home_colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'events_screen.dart';
import 'people_screen.dart';
import 'profile_screen.dart';
import 'user_management_screen.dart';

const _surface = HomeColors.surface;
const _border = HomeColors.border;
const _background = HomeColors.background;
const _accent = HomeColors.accent;
const _success = HomeColors.success;
const _warning = HomeColors.warning;
const _danger = HomeColors.danger;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService(ApiConstants.baseUrl);
  final TextEditingController _noFacePromptController =
      TextEditingController();
  final TextEditingController _unknownFacePromptController =
      TextEditingController();
  final TextEditingController _knownPersonPromptController =
      TextEditingController();
  final TextEditingController _aiTimeoutController =
      TextEditingController(text: '10');
  final TextEditingController _aiMaxWordsController =
      TextEditingController(text: '10');
  final TextEditingController _reportEmailController =
      TextEditingController();
  final TextEditingController _reportTimeController =
      TextEditingController(text: '23:00');

  bool _isSaving = false;
  bool _isLoadingAiAlerts = false;
  bool _isSavingAiAlerts = false;
  bool _isLoadingDailyReport = false;
  bool _isSavingDailyReport = false;
  bool _isSendingDailyReport = false;
  bool _aiAlertsEnabled = true;
  String? _aiAlertError;
  String? _dailyReportError;
  String _reportTimezone = 'Asia/Beirut';

  @override
  void initState() {
    super.initState();
    _loadAiAlertSettings();
    _loadDailyReportSettings();
  }

  @override
  void dispose() {
    _noFacePromptController.dispose();
    _unknownFacePromptController.dispose();
    _knownPersonPromptController.dispose();
    _aiTimeoutController.dispose();
    _aiMaxWordsController.dispose();
    _reportEmailController.dispose();
    _reportTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadAiAlertSettings() async {
    setState(() {
      _isLoadingAiAlerts = true;
      _aiAlertError = null;
    });

    try {
      final settings = await _apiService.getAiAlertSettings();
      if (!mounted) return;

      setState(() {
        _aiAlertsEnabled = settings['enabled'] == true;
        _aiTimeoutController.text =
            (settings['timeout_seconds'] ?? 10).toString();
        _aiMaxWordsController.text = (settings['max_words'] ?? 10).toString();
        _noFacePromptController.text =
            settings['no_face_prompt']?.toString() ?? '';
        _unknownFacePromptController.text =
            settings['unknown_face_prompt']?.toString() ?? '';
        _knownPersonPromptController.text =
            settings['known_person_prompt']?.toString() ?? '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _aiAlertError = error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoadingAiAlerts = false);
      }
    }
  }

  Future<void> _saveAiAlertSettings() async {
    final timeoutSeconds =
        double.tryParse(_aiTimeoutController.text.trim()) ?? 10;
    final maxWords = int.tryParse(_aiMaxWordsController.text.trim()) ?? 10;

    setState(() {
      _isSavingAiAlerts = true;
      _aiAlertError = null;
    });

    try {
      final settings = await _apiService.updateAiAlertSettings(
        enabled: _aiAlertsEnabled,
        timeoutSeconds: timeoutSeconds.clamp(1, 30).toDouble(),
        maxWords: maxWords.clamp(4, 20).toInt(),
        noFacePrompt: _noFacePromptController.text.trim(),
        unknownFacePrompt: _unknownFacePromptController.text.trim(),
        knownPersonPrompt: _knownPersonPromptController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _aiAlertsEnabled = settings['enabled'] == true;
        _aiTimeoutController.text =
            (settings['timeout_seconds'] ?? timeoutSeconds).toString();
        _aiMaxWordsController.text = (settings['max_words'] ?? maxWords).toString();
        _noFacePromptController.text =
            settings['no_face_prompt']?.toString() ?? '';
        _unknownFacePromptController.text =
            settings['unknown_face_prompt']?.toString() ?? '';
        _knownPersonPromptController.text =
            settings['known_person_prompt']?.toString() ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI alert prompts saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceAll('Exception: ', '');
      setState(() => _aiAlertError = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingAiAlerts = false);
      }
    }
  }

  Future<void> _loadDailyReportSettings() async {
    setState(() {
      _isLoadingDailyReport = true;
      _dailyReportError = null;
    });

    try {
      final settings = await _apiService.getDailyReportSettings();
      if (!mounted) return;

      setState(() {
        _reportEmailController.text =
            settings['report_email_to']?.toString() ?? '';
        _reportTimeController.text =
            settings['report_time']?.toString() ?? '23:00';
        _reportTimezone = settings['timezone']?.toString() ?? 'Asia/Beirut';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() =>
          _dailyReportError = error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoadingDailyReport = false);
      }
    }
  }

  Future<void> _saveDailyReportSettings() async {
    final reportTime = _normalizeReportTime(_reportTimeController.text);
    if (reportTime == null) {
      setState(() => _dailyReportError = 'Enter report time as HH:mm.');
      return;
    }

    setState(() {
      _isSavingDailyReport = true;
      _dailyReportError = null;
    });

    try {
      final settings = await _apiService.updateDailyReportSettings(
        reportEmailTo: _reportEmailController.text.trim(),
        reportTime: reportTime,
        timezone: _reportTimezone,
      );

      if (!mounted) return;
      setState(() {
        _reportEmailController.text =
            settings['report_email_to']?.toString() ?? '';
        _reportTimeController.text =
            settings['report_time']?.toString() ?? reportTime;
        _reportTimezone = settings['timezone']?.toString() ?? _reportTimezone;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily report settings saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceAll('Exception: ', '');
      setState(() => _dailyReportError = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingDailyReport = false);
      }
    }
  }

  Future<void> _sendDailyReportEmail() async {
    setState(() {
      _isSendingDailyReport = true;
      _dailyReportError = null;
    });

    try {
      final result = await _apiService.sendDailyReportEmail();
      if (!mounted) return;

      final recipient = result['recipient']?.toString() ?? 'recipient';
      final count = result['event_count']?.toString() ?? '0';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report sent to $recipient with $count events.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceAll('Exception: ', '');
      setState(() => _dailyReportError = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingDailyReport = false);
      }
    }
  }

  String? _normalizeReportTime(String value) {
    final trimmed = value.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    final paddedHour = hour.toString().padLeft(2, '0');
    final paddedMinute = minute.toString().padLeft(2, '0');
    return '$paddedHour:$paddedMinute';
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
                        if (auth.isAdmin) ...[
                          const SizedBox(height: 18),
                          _buildDailyReportSection(),
                          const SizedBox(height: 18),
                          _buildAiAlertSection(),
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

  Widget _buildAiAlertSection() {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.auto_awesome_rounded,
            title: 'AI Alert Prompts',
            subtitle: _isLoadingAiAlerts
                ? 'Loading prompt settings from server'
                : 'Gemini descriptions for critical camera alerts',
            trailing: Switch.adaptive(
              value: _aiAlertsEnabled,
              activeThumbColor: _accent,
              onChanged: _isSavingAiAlerts
                  ? null
                  : (value) => setState(() => _aiAlertsEnabled = value),
            ),
          ),
          if (_aiAlertError != null) ...[
            const SizedBox(height: 12),
            _NoticeBox(
              icon: Icons.error_outline_rounded,
              title: 'AI settings unavailable',
              message: _aiAlertError!,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PromptField(
                  controller: _aiTimeoutController,
                  label: 'Timeout seconds',
                  icon: Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                  enabled: !_isSavingAiAlerts,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PromptField(
                  controller: _aiMaxWordsController,
                  label: 'Max words',
                  icon: Icons.short_text_rounded,
                  keyboardType: TextInputType.number,
                  enabled: !_isSavingAiAlerts,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PromptField(
            controller: _noFacePromptController,
            label: 'No visible face prompt',
            icon: Icons.visibility_off_outlined,
            hint: 'Example: mention if the person is near the door.',
            enabled: !_isSavingAiAlerts,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _PromptField(
            controller: _unknownFacePromptController,
            label: 'Unknown face prompt',
            icon: Icons.person_search_rounded,
            hint: 'Example: mention bags, laptops, or server racks.',
            enabled: !_isSavingAiAlerts,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _PromptField(
            controller: _knownPersonPromptController,
            label: 'Known person prompt',
            icon: Icons.badge_outlined,
            hint: 'Example: focus on what they are touching.',
            enabled: !_isSavingAiAlerts,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CommandButton(
                label: _isSavingAiAlerts ? 'Saving' : 'Save AI Prompts',
                icon: Icons.save_outlined,
                color: _accent,
                onPressed: _isSavingAiAlerts ? null : _saveAiAlertSettings,
              ),
              _CommandButton(
                label: 'Reload',
                icon: Icons.refresh_rounded,
                color: _success,
                onPressed:
                    _isSavingAiAlerts || _isLoadingAiAlerts ? null : _loadAiAlertSettings,
              ),
            ],
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

  Widget _buildDailyReportSection() {
    final busy = _isLoadingDailyReport ||
        _isSavingDailyReport ||
        _isSendingDailyReport;

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.mark_email_read_outlined,
            title: 'Daily Entry Report',
            subtitle: _isLoadingDailyReport
                ? 'Loading report settings from server'
                : 'Gemini summary and raw event counts by email',
          ),
          if (_dailyReportError != null) ...[
            const SizedBox(height: 12),
            _NoticeBox(
              icon: Icons.error_outline_rounded,
              title: 'Report email unavailable',
              message: _dailyReportError!,
            ),
          ],
          const SizedBox(height: 14),
          _PromptField(
            controller: _reportEmailController,
            label: 'Report email',
            icon: Icons.alternate_email_rounded,
            hint: 'admin@example.com',
            keyboardType: TextInputType.emailAddress,
            enabled: !busy,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PromptField(
                  controller: _reportTimeController,
                  label: 'Report time',
                  icon: Icons.schedule_rounded,
                  hint: '23:00',
                  keyboardType: TextInputType.datetime,
                  enabled: !busy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  icon: Icons.public_rounded,
                  title: _reportTimezone,
                  subtitle: 'Report timezone',
                  color: _accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CommandButton(
                label: _isSavingDailyReport ? 'Saving' : 'Save Report',
                icon: Icons.save_outlined,
                color: _accent,
                onPressed: busy ? null : _saveDailyReportSettings,
              ),
              _CommandButton(
                label: _isSendingDailyReport ? 'Sending' : 'Send Today',
                icon: Icons.send_rounded,
                color: _success,
                onPressed: busy ? null : _sendDailyReportEmail,
              ),
              _CommandButton(
                label: 'Reload',
                icon: Icons.refresh_rounded,
                color: _warning,
                onPressed: busy ? null : _loadDailyReportSettings,
              ),
            ],
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

class _PromptField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final bool enabled;
  final int maxLines;

  const _PromptField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _accent),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.045),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _accent.withValues(alpha: 0.75)),
        ),
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
