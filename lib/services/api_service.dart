import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sentry_models.dart';

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<Map<String, dynamic>> getStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/api/status'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load status');
  }

  Future<Map<String, dynamic>> getLiveStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/api/live-status'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load live status');
  }

  Future<List<Person>> getPersons() async {
    final response = await http.get(Uri.parse('$baseUrl/api/persons'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => Person.fromJson(item)).toList();
    }
    throw Exception('Failed to load persons');
  }

  Future<Person> createPerson(String fullName, String? role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/persons'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'full_name': fullName,
        'role': role,
        'is_authorized': true,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Person.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create person');
  }

  Future<List<Event>> getEvents({int limit = 50}) async {
    final response = await http.get(Uri.parse('$baseUrl/api/events?limit=$limit'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => Event.fromJson(item)).toList();
    }
    throw Exception('Failed to load events');
  }

  Future<Event> acknowledgeEvent(int eventId) async {
    final response = await http.patch(Uri.parse('$baseUrl/api/events/$eventId/acknowledge'));
    if (response.statusCode == 200) {
      return Event.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to acknowledge event');
  }

  Future<void> updatePersonAuthorization(int personId, bool isAuthorized) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/persons/$personId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'is_authorized': isAuthorized}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update authorization');
    }
  }
}
