import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../../../services/api_service.dart';
import '../../../services/emergency_incident_api_service.dart';
import '../models/emergency_incident_log.dart';

class EmergencyIncidentLogProvider extends ChangeNotifier {
  static const String _storageKey = 'sentry_room_emergency_incident_logs';

  final List<EmergencyIncidentLog> _logs = [];
  final EmergencyIncidentApiService _apiService = EmergencyIncidentApiService(
    ApiService(ApiConstants.baseUrl),
  );

  bool _isSyncing = false;
  String? _syncError;
  DateTime? _lastSyncedAt;

  EmergencyIncidentLogProvider() {
    loadLogs();
  }

  List<EmergencyIncidentLog> get logs => List.unmodifiable(_logs);
  List<EmergencyIncidentLog> get recentLogs => List.unmodifiable(_logs);
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> loadLogs() async {
    await _loadLogs();
  }

  Future<void> addLog(EmergencyIncidentLog log) async {
    _logs.insert(0, log);
    notifyListeners();
    await _saveLogs();
  }

  Future<void> updateLogStatus(
    String id,
    EmergencyIncidentStatus status,
  ) async {
    final index = _logs.indexWhere((log) => log.id == id);
    if (index == -1) {
      return;
    }

    _logs[index] = _logs[index].copyWith(status: status);
    notifyListeners();
    await _saveLogs();
  }

  Future<void> clearLogs() async {
    _logs.clear();
    notifyListeners();
    await _saveLogs();
  }

  Future<void> removeLog(String id) async {
    _logs.removeWhere((log) => log.id == id);
    notifyListeners();
    await _saveLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }

      _logs.clear();
      for (final item in decoded) {
        if (item is Map) {
          _logs.add(EmergencyIncidentLog.fromJson(Map<String, dynamic>.from(item)));
        }
      }

      notifyListeners();
    } catch (_) {
      _logs.clear();
      notifyListeners();
    }
  }

  Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_logs.map((log) => log.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Ignore persistence errors and keep in-memory history.
    }
  }

  Future<int> syncPendingIncidents({String? authToken}) async {
    final pendingLogs = _logs.where((log) => !log.isSynced).toList();
    if (pendingLogs.isEmpty) {
      return 0;
    }

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    var synced = 0;
    final errors = <String>[];

    for (final log in pendingLogs) {
      try {
        await _apiService.createIncident(log, authToken: authToken);
        await _updateLogSyncStatus(log.id, true);
        synced += 1;
      } catch (e) {
        errors.add(e.toString());
      }
    }

    _lastSyncedAt = DateTime.now();
    _isSyncing = false;
    _syncError = errors.isNotEmpty ? errors.join('; ') : null;
    notifyListeners();

    if (errors.isNotEmpty) {
      throw Exception('Completed sync with ${errors.length} error(s).');
    }

    return synced;
  }

  Future<void> _updateLogSyncStatus(String id, bool isSynced) async {
    final index = _logs.indexWhere((log) => log.id == id);
    if (index == -1) {
      return;
    }

    _logs[index] = _logs[index].copyWith(isSynced: isSynced);
    notifyListeners();
    await _saveLogs();
  }
}
