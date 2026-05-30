import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_settings.dart';
import '../models/emergency_type.dart';
import '../models/emergency_contact.dart';
import '../models/gps_location.dart';

/// EmergencySettingsProvider manages the configuration for the Emergency Center.
class EmergencySettingsProvider extends ChangeNotifier {
  static const String _storageKey = 'emergency_settings';

  EmergencySettings _settings = EmergencySettings.defaultSettings();
  bool _loaded = false;

  EmergencySettingsProvider() {
    _loadSettings();
  }

  EmergencySettings get settings => _settings;
  bool get isLoaded => _loaded;

  /// Update the site name.
  void setSiteName(String siteName) {
    _settings = _settings.copyWith(siteName: siteName.trim());
    notifyListeners();
    _saveSettings();
  }

  /// Update the location label.
  void setLocationLabel(String locationLabel) {
    _settings = _settings.copyWith(locationLabel: locationLabel.trim());
    notifyListeners();
    _saveSettings();
  }

  /// Update the location notes.
  void setLocationNotes(String locationNotes) {
    _settings = _settings.copyWith(locationNotes: locationNotes.trim());
    notifyListeners();
    _saveSettings();
  }

  /// Toggle GPS location feature.
  void setEnableGpsLocation(bool enabled) {
    _settings = _settings.copyWith(enableGpsLocation: enabled);
    notifyListeners();
    _saveSettings();
  }

  /// Update the current stored GPS coordinates.
  void setGpsLocation(GpsLocation? location) {
    _settings = _settings.copyWith(gpsLocation: location);
    notifyListeners();
    _saveSettings();
  }

  /// Update a contact for a specific emergency type.
  void updateContact(EmergencyType type, EmergencyContact contact) {
    final cleanedContact = EmergencyContact(
      name: contact.name.trim(),
      role: contact.role.trim(),
      phone: contact.phone?.trim().isEmpty ?? true ? null : contact.phone?.trim(),
      email: contact.email?.trim().isEmpty ?? true ? null : contact.email?.trim(),
    );

    _settings = _settings.updateContact(type, cleanedContact);
    notifyListeners();
    _saveSettings();
  }

  /// Get contact for a specific emergency type.
  EmergencyContact? getContact(EmergencyType type) {
    return _settings.contacts[type];
  }

  /// Reset to default settings.
  void resetToDefaults() {
    _settings = EmergencySettings.defaultSettings();
    notifyListeners();
    _saveSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        _loaded = true;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _settings = EmergencySettings.fromJson(decoded);
      }
    } catch (_) {
      _settings = EmergencySettings.defaultSettings();
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_settings.toJson());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Ignore persistence errors; keep runtime settings functional.
    }
  }
}
