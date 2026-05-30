import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/emergency_type.dart';
import 'models/emergency_contact.dart';
import 'providers/emergency_settings_provider.dart';
import '../home/widgets/home_widgets.dart';

class EmergencySettingsScreen extends StatefulWidget {
  const EmergencySettingsScreen({super.key});

  @override
  State<EmergencySettingsScreen> createState() =>
      _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends State<EmergencySettingsScreen> {
  late TextEditingController _siteNameController;
  late TextEditingController _locationLabelController;
  late TextEditingController _locationNotesController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<EmergencySettingsProvider>();
    final settings = provider.settings;
    _siteNameController = TextEditingController(text: settings.siteName);
    _locationLabelController =
        TextEditingController(text: settings.locationLabel);
    _locationNotesController =
        TextEditingController(text: settings.locationNotes);
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _locationLabelController.dispose();
    _locationNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              backgroundColor: HomeColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              title: const Text(
                'Emergency Settings',
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
            ),
            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Location Settings Section
                  _buildSectionHeader('Location Settings'),
                  const SizedBox(height: 12),
                  _buildLocationForm(),
                  const SizedBox(height: 24),

                  // GPS Toggle
                  _buildGpsToggle(),
                  const SizedBox(height: 24),

                  // Emergency Contacts Section
                  _buildSectionHeader('Emergency Contacts'),
                  const SizedBox(height: 12),
                  _buildContactsForm(),
                  const SizedBox(height: 24),

                  // Reset Button
                  _buildResetButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLocationForm() {
    return Consumer<EmergencySettingsProvider>(
      builder: (context, provider, _) {
        return GlassPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: 'Site Name',
                controller: _siteNameController,
                onChanged: (value) => provider.setSiteName(value),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Location',
                controller: _locationLabelController,
                onChanged: (value) => provider.setLocationLabel(value),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Location Notes',
                controller: _locationNotesController,
                onChanged: (value) => provider.setLocationNotes(value),
                maxLines: 3,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextDirection? textDirection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textDirection: textDirection,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: HomeColors.accent,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          cursorColor: HomeColors.accent,
        ),
      ],
    );
  }

  Widget _buildGpsToggle() {
    return Consumer<EmergencySettingsProvider>(
      builder: (context, provider, _) {
        return GlassPanel(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const IconBubble(
                icon: Icons.location_on_rounded,
                color: HomeColors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enable GPS Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When enabled, you can share your current location in emergency reports.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: provider.settings.enableGpsLocation,
                onChanged: (value) => provider.setEnableGpsLocation(value),
                activeThumbColor: HomeColors.success,
                inactiveThumbColor: Colors.white.withValues(alpha: 0.4),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactsForm() {
    return Consumer<EmergencySettingsProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            for (final type in EmergencyType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildContactCard(provider, type),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContactCard(
    EmergencySettingsProvider provider,
    EmergencyType type,
  ) {
    final contact = provider.getContact(type) ??
        const EmergencyContact(
          name: '',
          role: '',
          phone: '',
          email: '',
        );

    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getEmergencyTypeLabel(type),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Name',
            controller: TextEditingController(text: contact.name),
            onChanged: (value) => provider.updateContact(
              type,
              contact.copyWith(name: value),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'Role',
            controller: TextEditingController(text: contact.role),
            onChanged: (value) => provider.updateContact(
              type,
              contact.copyWith(role: value),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'Phone (optional)',
            controller: TextEditingController(text: contact.phone ?? ''),
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            onChanged: (value) => provider.updateContact(
              type,
              contact.copyWith(phone: value.isEmpty ? null : value),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'Email (optional)',
            controller: TextEditingController(text: contact.email ?? ''),
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            onChanged: (value) => provider.updateContact(
              type,
              contact.copyWith(email: value.isEmpty ? null : value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return Center(
      child: FilledButton.icon(
        onPressed: () => _confirmReset(),
        icon: const Icon(Icons.restore_rounded),
        label: const Text('Reset to Defaults'),
        style: FilledButton.styleFrom(
          backgroundColor: HomeColors.warning,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: HomeColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HomeColors.border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reset All Settings?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All emergency settings will be restored to defaults. This cannot be undone.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        context
                            .read<EmergencySettingsProvider>()
                            .resetToDefaults();
                        _siteNameController.text = 'Sentry Room';
                        _locationLabelController.text = 'Building A, Floor 2';
                        _locationNotesController.text =
                            'Manual location. Update this from Emergency Settings.';
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings reset to defaults.'),
                            backgroundColor: HomeColors.success,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: HomeColors.danger,
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEmergencyTypeLabel(EmergencyType type) {
    switch (type) {
      case EmergencyType.fire:
        return 'Fire Emergency';
      case EmergencyType.security:
        return 'Security Threat';
      case EmergencyType.humidity:
        return 'High Humidity / Fan Issue';
      case EmergencyType.medical:
        return 'Medical Emergency';
      case EmergencyType.support:
        return 'General Support';
    }
  }
}
