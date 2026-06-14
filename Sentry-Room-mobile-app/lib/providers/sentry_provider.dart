import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../models/sentry_models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/websocket_service.dart';

class SentryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService(ApiConstants.baseUrl);
  final WebSocketService _webSocketService = WebSocketService();

  List<Event> _events = [];
  List<Person> _persons = [];
  Map<String, dynamic> _liveStatus = {};
  bool _isLoading = false;
  String _securityMode = 'working_hours';
  String? _lastActionError;

  final Set<int> _seenEventIds = {};
  Timer? _refreshTimer;
  StreamSubscription<Map<String, dynamic>>? _alertSubscription;

  List<Event> get events => _events;
  List<Person> get persons => _persons;
  Map<String, dynamic> get liveStatus => _liveStatus;
  bool get isLoading => _isLoading;
  String get securityMode => _securityMode;
  bool get isArmed => _securityMode != 'disarmed';
  String? get lastActionError => _lastActionError;

  SentryProvider() {
    refreshData();
    startPolling();
    startLiveAlerts();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getEvents(),
        _apiService.getPersons(),
        _apiService.getLiveStatus(),
      ]);

      final newEvents = results[0] as List<Event>;
      _persons = results[1] as List<Person>;
      _liveStatus = results[2] as Map<String, dynamic>;
      _securityMode =
          _liveStatus['security_mode']?.toString() ?? _securityMode;

      _processNewEvents(newEvents);
      _events = newEvents;
    } catch (error) {
      debugPrint('Error refreshing data: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processNewEvents(List<Event> newEvents) {
    if (_events.isEmpty) {
      for (final event in newEvents) {
        _seenEventIds.add(event.id);
      }
      return;
    }

    for (final event in newEvents) {
      if (_seenEventIds.contains(event.id)) continue;

      _seenEventIds.add(event.id);
      _notifyForEvent(
        event.id,
        event.eventType,
        event.severity,
        event.message,
        title: event.displayTypeLabel,
      );
    }
  }

  void startPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      refreshData();
    });
  }

  void startLiveAlerts() {
    _alertSubscription?.cancel();
    _webSocketService.connect(ApiConstants.wsAlertsUrl);
    _alertSubscription = _webSocketService.messages.listen((message) {
      final eventId = message['event_id'];
      if (eventId is int && !_seenEventIds.contains(eventId)) {
        _seenEventIds.add(eventId);
        _notifyForEvent(
          eventId,
          message['type']?.toString() ?? '',
          message['severity']?.toString() ?? '',
          message['message']?.toString() ?? 'New Sentry Room event',
        );
      }

      refreshData();
    });
  }

  Future<bool> updateSecurityMode(String mode) async {
    try {
      _lastActionError = null;
      final response = await _apiService.updateSecurityMode(mode);
      _securityMode = response['mode']?.toString() ?? mode;
      _liveStatus = {
        ..._liveStatus,
        'security_mode': _securityMode,
      };
      notifyListeners();
      return true;
    } catch (error) {
      _lastActionError = _cleanError(error);
      debugPrint('Error updating security mode: $_lastActionError');
      return false;
    }
  }

  void _notifyForEvent(
    int id,
    String eventType,
    String severity,
    String message, {
    String? title,
  }) {
    if (eventType == 'unauthorized_entry') {
      NotificationService.showNotification(
        id: id,
        title: title ?? 'Security Alert',
        body: message,
      );
      return;
    }

    if (eventType == 'environmental_alert' &&
        (severity == 'warning' || severity == 'critical')) {
      NotificationService.showNotification(
        id: id,
        title: title ?? 'Environmental Alert',
        body: message,
      );
      return;
    }

    if (severity == 'critical') {
      NotificationService.showNotification(
        id: id,
        title: 'Critical Alert',
        body: message,
      );
      return;
    }

  }

  Future<bool> acknowledgeEvent(int eventId) async {
    try {
      _lastActionError = null;
      await _apiService.acknowledgeEvent(eventId);
      await refreshData();
      return true;
    } catch (error) {
      _lastActionError = _cleanError(error);
      debugPrint('Error acknowledging event: $_lastActionError');
      return false;
    }
  }

  Future<bool> createPerson(String fullName, String? role) async {
    try {
      _lastActionError = null;
      await _apiService.createPerson(fullName, role);
      await refreshData();
      return true;
    } catch (error) {
      _lastActionError = _cleanError(error);
      debugPrint('Error creating person: $_lastActionError');
      return false;
    }
  }

  Future<bool> enrollPersonFromCamera(String fullName, String? role) async {
    try {
      _lastActionError = null;
      await _apiService.enrollPersonFromCamera(fullName, role);
      await refreshData();
      return true;
    } catch (error) {
      _lastActionError = _cleanError(error);
      debugPrint('Error enrolling person from camera: $_lastActionError');
      return false;
    }
  }

  Future<bool> updatePersonAuthorization(
    int personId,
    bool isAuthorized,
  ) async {
    try {
      _lastActionError = null;
      await _apiService.updatePersonAuthorization(personId, isAuthorized);
      await refreshData();
      return true;
    } catch (error) {
      _lastActionError = _cleanError(error);
      debugPrint('Error updating person: $_lastActionError');
      return false;
    }
  }

  Future<bool> authorizePerson(int personId) async {
    try {
      _lastActionError = null;
      await _apiService.updatePersonAuthorization(personId, true);
      await refreshData();
      return true;
    } catch (error) {
      _lastActionError = _cleanError(error);
      debugPrint('Error authorizing person: $_lastActionError');
      return false;
    }
  }

  Future<bool> authorizePersonFromEvent({
    required int eventId,
    required String fullName,
    String? role,
    String? notes,
  }) async {
    try {
      _lastActionError = null;
      await _apiService.authorizePersonFromEvent(
        eventId: eventId,
        fullName: fullName,
        role: role,
        notes: notes,
      );
      await refreshData();
      return true;
    } catch (error) {
      _lastActionError = _cleanError(error);
      debugPrint('Error authorizing person from event: $_lastActionError');
      return false;
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '');
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _alertSubscription?.cancel();
    _webSocketService.dispose();
    super.dispose();
  }
}
