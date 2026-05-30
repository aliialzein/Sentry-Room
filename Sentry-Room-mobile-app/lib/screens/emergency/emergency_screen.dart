import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/emergency_type.dart';
import 'models/emergency_action_type.dart';
import 'models/emergency_contact.dart';
import 'models/emergency_incident_log.dart';
import 'models/gps_location.dart';
import 'providers/emergency_settings_provider.dart';
import 'providers/emergency_incident_log_provider.dart';
import 'emergency_history_screen.dart';
import 'emergency_settings_screen.dart';
import 'utils/emergency_report_builder.dart';
import 'widgets/emergency_card.dart';
import 'widgets/emergency_location_panel.dart';
import 'widgets/emergency_confirmation_dialog.dart';
import '../home/widgets/home_widgets.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  GpsLocation? _currentGpsLocation;
  bool _isRequestingGpsLocation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Consumer<EmergencySettingsProvider>(
          builder: (context, settingsProvider, _) {
            final settings = settingsProvider.settings;

            return CustomScrollView(
              slivers: [
                // Header with settings button
                SliverAppBar(
                  backgroundColor: HomeColors.background,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  title: const Text(
                    'Emergency Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.history_rounded,
                          color: Colors.white),
                      tooltip: 'Emergency History',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmergencyHistoryScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded,
                          color: Colors.white),
                      tooltip: 'Emergency Settings',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmergencySettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                // Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Warning notice
                      _buildWarningNotice(),
                      const SizedBox(height: 20),

                      // Location panel
                      EmergencyLocationPanel(
                        site: settings.siteName,
                        location: settings.locationLabel,
                        notes: settings.locationNotes,
                        gpsLocation:
                            _currentGpsLocation ?? settings.gpsLocation,
                        isRequestingGpsLocation: _isRequestingGpsLocation,
                        onRequestGpsLocation: settings.enableGpsLocation
                            ? () => _requestGpsLocation(settingsProvider)
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Emergency cards
                      for (final type in EmergencyType.values) ...[
                        _buildEmergencyCard(
                          settings: settings,
                          type: type,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWarningNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: HomeColors.danger.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.priority_high_rounded,
            color: HomeColors.danger,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use Responsibly',
                  style: TextStyle(
                    color: HomeColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Emergency actions open communication apps on your device. No calls, SMS, or emails are sent automatically. You must confirm and complete the action in the opened app.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard({
    required dynamic settings,
    required EmergencyType type,
  }) {
    final contact = settings.contacts[type];
    final details = _getEmergencyCardDetails(type);

    if (contact == null) {
      // Show fallback card for missing contact
      return GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBubble(
              icon: details.icon,
              color: HomeColors.warning,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact not configured',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return EmergencyCard(
      type: type,
      title: details.title,
      description: details.description,
      severity: details.severity,
      icon: details.icon,
      contact: contact,
      onActionPressed: (action) {
        _handleEmergencyAction(type, details.title, action, contact);
      },
    );
  }

  _EmergencyCardDetails _getEmergencyCardDetails(EmergencyType type) {
    switch (type) {
      case EmergencyType.fire:
        return const _EmergencyCardDetails(
          title: 'Fire Emergency',
          description: 'Report active fire or smoke',
          icon: Icons.local_fire_department_rounded,
          severity: 'CRITICAL',
        );
      case EmergencyType.security:
        return const _EmergencyCardDetails(
          title: 'Security Threat',
          description: 'Report unauthorized entry or security breach',
          icon: Icons.security_rounded,
          severity: 'CRITICAL',
        );
      case EmergencyType.humidity:
        return const _EmergencyCardDetails(
          title: 'High Humidity / Fan Issue',
          description: 'Report environmental control problems',
          icon: Icons.air_rounded,
          severity: 'HIGH',
        );
      case EmergencyType.medical:
        return const _EmergencyCardDetails(
          title: 'Medical Emergency',
          description: 'Report health-related emergency',
          icon: Icons.local_hospital_rounded,
          severity: 'CRITICAL',
        );
      case EmergencyType.support:
        return const _EmergencyCardDetails(
          title: 'General Support',
          description: 'Request general app or room support',
          icon: Icons.help_outline_rounded,
          severity: 'MEDIUM',
        );
    }
  }

  void _handleEmergencyAction(
    EmergencyType type,
    String title,
    EmergencyActionType action,
    EmergencyContact contact,
  ) async {
    final settings = context.read<EmergencySettingsProvider>().settings;
    final logProvider = context.read<EmergencyIncidentLogProvider>();
    final currentGps = _currentGpsLocation ?? settings.gpsLocation;
    final locationStr = '${settings.siteName}, ${settings.locationLabel}';

    showDialog(
      context: context,
      builder: (context) => EmergencyConfirmationDialog(
        emergencyTitle: title,
        actionType: action,
        contactName: contact.name,
        manualLocation: locationStr,
        gpsLocation: currentGps,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () async {
          Navigator.of(context).pop();

          final incident = EmergencyIncidentLog(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            emergencyType: type,
            emergencyTitle: title,
            actionType: action,
            contactName: contact.name,
            contactPhone: contact.phone,
            contactEmail: contact.email,
            manualLocation: locationStr,
            gpsLatitude: currentGps?.latitude,
            gpsLongitude: currentGps?.longitude,
            timestamp: DateTime.now(),
            status: EmergencyIncidentStatus.confirmed,
          );

          await logProvider.addLog(incident);
          final status = await _executeEmergencyAction(incident);
          await logProvider.updateLogStatus(incident.id, status);
        },
      ),
    );
  }

  Future<EmergencyIncidentStatus> _executeEmergencyAction(
    EmergencyIncidentLog incident,
  ) async {
    try {
      switch (incident.actionType) {
        case EmergencyActionType.call:
          final phone = incident.contactPhone?.trim();
          if (phone != null && phone.isNotEmpty) {
            final url = Uri(scheme: 'tel', path: phone);
            return _launchExternalEmergencyApp(
              url,
              'No phone dialer is available on this device or emulator.',
            );
          }
          _showError('No phone number is configured for this contact.');
          return EmergencyIncidentStatus.failedToOpenExternalApp;

        case EmergencyActionType.sms:
          final phone = incident.contactPhone?.trim();
          if (phone != null && phone.isNotEmpty) {
            final url = Uri(
              scheme: 'sms',
              path: phone,
              queryParameters: {
                'body': EmergencyReportBuilder.build(incident),
              },
            );
            return _launchExternalEmergencyApp(
              url,
              'No SMS app is available on this device or emulator.',
            );
          }
          _showError('No phone number is configured for this contact.');
          return EmergencyIncidentStatus.failedToOpenExternalApp;

        case EmergencyActionType.email:
          final email = incident.contactEmail?.trim();
          if (email != null && email.isNotEmpty) {
            final url = Uri(
              scheme: 'mailto',
              path: email,
              queryParameters: const {
                'subject': 'Emergency Report',
                'body': 'I am reporting an emergency from Sentry Room.\n\n',
              },
            );
            return _launchExternalEmergencyApp(
              url,
              'No email app is available on this device or emulator.',
            );
          }
          _showError('No email address is configured for this contact.');
          return EmergencyIncidentStatus.failedToOpenExternalApp;

        case EmergencyActionType.shareLocation:
          final report = EmergencyReportBuilder.build(incident);
          await Share.share(report);
          return EmergencyIncidentStatus.shared;
      }
    } catch (e) {
      _showError('Action failed: ${e.toString()}');
      return EmergencyIncidentStatus.failedToOpenExternalApp;
    }
  }

  Future<EmergencyIncidentStatus> _launchExternalEmergencyApp(
    Uri url,
    String failureMessage,
  ) async {
    try {
      // Android emulators may not include dialer, SMS, or email handlers.
      // Launching only opens the external app; the user must place/send manually.
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showError(failureMessage);
      }
      return launched
          ? EmergencyIncidentStatus.openedExternalApp
          : EmergencyIncidentStatus.failedToOpenExternalApp;
    } catch (_) {
      _showError(failureMessage);
      return EmergencyIncidentStatus.failedToOpenExternalApp;
    }
  }

  Future<void> _requestGpsLocation(
    EmergencySettingsProvider settingsProvider,
  ) async {
    if (_isRequestingGpsLocation) return;
    setState(() {
      _isRequestingGpsLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(
          'Location services are disabled. Enable location and try again.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Permission is requested only from this manual button action.
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
          'Location permission is permanently denied. Enable it in app settings.',
        );
        return;
      }

      if (permission == LocationPermission.unableToDetermine) {
        _showError('Unable to determine location permission.');
        return;
      }

      // One-shot foreground lookup only. Android emulators need a simulated
      // location configured in Extended Controls before GPS can resolve.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(const Duration(seconds: 18));

      if (!mounted) return;
      final location = GpsLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        _currentGpsLocation = location;
      });
      settingsProvider.setGpsLocation(location);
      _showSuccess('Current GPS location saved.');
    } on TimeoutException {
      _showError(
        'GPS lookup timed out. On an emulator, set a simulated location and try again.',
      );
    } on LocationServiceDisabledException {
      _showError(
        'Location services are disabled. Enable location and try again.',
      );
    } on PermissionDeniedException {
      _showError('Location permission was denied.');
    } catch (e) {
      _showError('Unable to retrieve GPS location: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingGpsLocation = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HomeColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HomeColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _EmergencyCardDetails {
  final String title;
  final String description;
  final IconData icon;
  final String severity;

  const _EmergencyCardDetails({
    required this.title,
    required this.description,
    required this.icon,
    required this.severity,
  });
}
