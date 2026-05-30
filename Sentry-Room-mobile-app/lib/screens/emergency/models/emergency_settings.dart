import '../models/emergency_type.dart';
import '../models/emergency_contact.dart';
import '../models/gps_location.dart';

/// EmergencySettings holds configurable emergency center data.
/// TODO: These settings should later be persisted to local storage or backend.
class EmergencySettings {
  final String siteName;
  final String locationLabel;
  final String locationNotes;
  final bool enableGpsLocation;
  final GpsLocation? gpsLocation;
  final Map<EmergencyType, EmergencyContact> contacts;

  const EmergencySettings({
    required this.siteName,
    required this.locationLabel,
    required this.locationNotes,
    required this.enableGpsLocation,
    required this.gpsLocation,
    required this.contacts,
  });

  /// Factory constructor for default fallback config (matching Phase 1).
  /// TODO: Later replace with backend or persistent storage load.
  factory EmergencySettings.defaultSettings() {
    return const EmergencySettings(
      siteName: 'Sentry Room',
      locationLabel: 'Building A, Floor 2',
      locationNotes: 'Manual location. Update this from Emergency Settings.',
      enableGpsLocation: false,
      gpsLocation: null,
      contacts: {
        EmergencyType.fire: EmergencyContact(
          name: 'Fire Response',
          role: 'Emergency fire contact',
          phone: '112',
          email: 'fire-response@example.com',
        ),
        EmergencyType.security: EmergencyContact(
          name: 'Security / Police',
          role: 'Security escalation contact',
          phone: '112',
          email: 'security@example.com',
        ),
        EmergencyType.humidity: EmergencyContact(
          name: 'Maintenance Support',
          role: 'Ventilation and fan support',
          phone: '+96100000000',
          email: 'maintenance@example.com',
        ),
        EmergencyType.medical: EmergencyContact(
          name: 'Medical Response',
          role: 'Emergency medical contact',
          phone: '112',
          email: 'medical@example.com',
        ),
        EmergencyType.support: EmergencyContact(
          name: 'Sentry Room Support',
          role: 'General app and room support',
          phone: '+96100000000',
          email: 'support@example.com',
        ),
      },
    );
  }

  factory EmergencySettings.fromJson(Map<String, dynamic> json) {
    final defaultSettings = EmergencySettings.defaultSettings();

    final rawContacts = json['contacts'];
    final contacts = <EmergencyType, EmergencyContact>{};
    if (rawContacts is Map) {
      for (final type in EmergencyType.values) {
        final rawContact = rawContacts[type.name];
        if (rawContact is Map<String, dynamic>) {
          contacts[type] = EmergencyContact.fromJson(rawContact);
        } else {
          contacts[type] = defaultSettings.contacts[type]!;
        }
      }
    } else {
      contacts.addAll(defaultSettings.contacts);
    }

    GpsLocation? gpsLocation;
    final rawGps = json['gpsLocation'];
    if (rawGps is Map<String, dynamic> && rawGps['latitude'] != null && rawGps['longitude'] != null) {
      try {
        gpsLocation = GpsLocation.fromJson(rawGps);
      } catch (_) {
        gpsLocation = null;
      }
    }

    return EmergencySettings(
      siteName: json['siteName']?.toString().trim() ?? defaultSettings.siteName,
      locationLabel: json['locationLabel']?.toString().trim() ?? defaultSettings.locationLabel,
      locationNotes: json['locationNotes']?.toString().trim() ?? defaultSettings.locationNotes,
      enableGpsLocation: json['enableGpsLocation'] is bool
          ? json['enableGpsLocation'] as bool
          : defaultSettings.enableGpsLocation,
      gpsLocation: gpsLocation,
      contacts: contacts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siteName': siteName,
      'locationLabel': locationLabel,
      'locationNotes': locationNotes,
      'enableGpsLocation': enableGpsLocation,
      'gpsLocation': gpsLocation?.toJson(),
      'contacts': contacts.map((key, value) => MapEntry(key.name, value.toJson())),
    };
  }

  /// Create a copy with optional field overrides.
  EmergencySettings copyWith({
    String? siteName,
    String? locationLabel,
    String? locationNotes,
    bool? enableGpsLocation,
    GpsLocation? gpsLocation,
    Map<EmergencyType, EmergencyContact>? contacts,
  }) {
    return EmergencySettings(
      siteName: siteName ?? this.siteName,
      locationLabel: locationLabel ?? this.locationLabel,
      locationNotes: locationNotes ?? this.locationNotes,
      enableGpsLocation: enableGpsLocation ?? this.enableGpsLocation,
      gpsLocation: gpsLocation ?? this.gpsLocation,
      contacts: contacts ?? this.contacts,
    );
  }

  /// Update or add a contact for a specific emergency type.
  EmergencySettings updateContact(
    EmergencyType type,
    EmergencyContact contact,
  ) {
    final updatedContacts = Map<EmergencyType, EmergencyContact>.from(contacts);
    updatedContacts[type] = contact;
    return copyWith(contacts: updatedContacts);
  }
}
