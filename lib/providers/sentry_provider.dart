import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sentry_models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../constants/api_constants.dart';

class SentryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService(ApiConstants.baseUrl);

  List<Event> _events = [];
  List<Person> _persons = [];
  Map<String, dynamic> _liveStatus = {};
  bool _isLoading = false;
  String? _lastActionError;

  // Settings
  bool _notifyAllUsers = false;
  final Set<int> _seenEventIds = {};

  List<Event> get events => _events;
  List<Person> get persons => _persons;
  Map<String, dynamic> get liveStatus => _liveStatus;
  bool get isLoading => _isLoading;
  bool get notifyAllUsers => _notifyAllUsers;
  String? get lastActionError => _lastActionError;

  Timer? _refreshTimer;

  SentryProvider() {
    refreshData(); // Call refreshData immediately
    startPolling();
  }

  void setNotifyAllUsers(bool value) {
    _notifyAllUsers = value;
    notifyListeners();
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

      _processNewEvents(newEvents);
      _events = newEvents;
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processNewEvents(List<Event> newEvents) {
    if (_events.isEmpty) {
      // First load, just mark all as seen
      for (var e in newEvents) {
        _seenEventIds.add(e.id);
      }
      return;
    }

    for (var event in newEvents) {
      if (!_seenEventIds.contains(event.id)) {
        _seenEventIds.add(event.id);

        // Notification Logic
        if (event.eventType == 'unauthorized_entry') {
          NotificationService.showNotification(
            id: event.id,
            title: '⚠️ SECURITY ALERT',
            body: event.message,
          );
        } else if (event.severity == 'danger' || event.severity == 'critical') {
          NotificationService.showNotification(
            id: event.id,
            title: '🔥 CRITICAL ALERT',
            body: event.message,
          );
        } else if (event.eventType == 'entry') {
          // Admin notification for authorized entry if enabled
          if (_notifyAllUsers) {
            NotificationService.showNotification(
              id: event.id,
              title: 'Entry Detected',
              body: event.message,
            );
          }
        }
      }
    }
  }

  void startPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      refreshData();
    });
  }

  Future<bool> acknowledgeEvent(int eventId) async {
    try {
      _lastActionError = null;
      await _apiService.acknowledgeEvent(eventId);
      await refreshData();
      return true;
    } catch (e) {
      _lastActionError = _cleanError(e);
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
    } catch (e) {
      _lastActionError = _cleanError(e);
      debugPrint('Error creating person: $_lastActionError');
      return false;
    }
  }

  Future<bool> updatePersonAuthorization(
      int personId, bool isAuthorized) async {
    try {
      _lastActionError = null;
      await _apiService.updatePersonAuthorization(personId, isAuthorized);
      await refreshData();
      return true;
    } catch (e) {
      _lastActionError = _cleanError(e);
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
    } catch (e) {
      _lastActionError = _cleanError(e);
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
    } catch (e) {
      _lastActionError = _cleanError(e);
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
    super.dispose();
  }
}
