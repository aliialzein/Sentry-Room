import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sentry_models.dart';

class ApiService {
  static const Duration _requestTimeout = Duration(seconds: 10);

  final String baseUrl;

  ApiService(this.baseUrl);

  String _errorMessage(http.Response response, String fallback) {
    if (response.body.isEmpty) {
      return '$fallback (${response.statusCode})';
    }

    try {
      final errorData = json.decode(response.body);
      final detail = errorData['detail'];
      if (detail != null) {
        return detail.toString();
      }
    } catch (_) {
      return '$fallback (${response.statusCode})';
    }

    return '$fallback (${response.statusCode})';
  }

  Map<String, String> buildJsonHeaders({String? accessToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }




  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'identifier': identifier,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to login');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to register');
    }
  }




  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/api/users'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load users');
  }

  Future<void> updateUserRole(int userId, String role) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/users/$userId/role'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'role': role}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user role');
    }
  }

  Future<void> updateUserStatus(int userId, bool isActive) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/users/$userId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'is_active': isActive}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user status');
    }
  }

  // --- Sentry/Person Endpoints ---

  Future<Map<String, dynamic>> getStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/api/status'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load status');
  }

  Future<Map<String, dynamic>> getLiveStatus() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/live-status'))
        .timeout(_requestTimeout);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception(_errorMessage(response, 'Failed to load live status'));
  }

  Future<List<Person>> getPersons() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/persons'))
        .timeout(_requestTimeout);
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => Person.fromJson(item)).toList();
    }
    throw Exception(_errorMessage(response, 'Failed to load persons'));
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
    final response = await http
        .get(Uri.parse('$baseUrl/api/events?limit=$limit'))
        .timeout(_requestTimeout);
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => Event.fromJson(item)).toList();
    }
    throw Exception(_errorMessage(response, 'Failed to load events'));
  }

  Future<void> acknowledgeEvent(int eventId) async {
    final response = await http
        .patch(Uri.parse('$baseUrl/api/events/$eventId/acknowledge'))
        .timeout(_requestTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception(_errorMessage(response, 'Failed to acknowledge event'));
  }

  Future<void> authorizePersonFromEvent({
    required int eventId,
    required String fullName,
    String? role,
    String? notes,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/events/$eventId/authorize-person'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'full_name': fullName,
            'role': role,
            'notes': notes,
          }),
        )
        .timeout(_requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(_errorMessage(response, 'Failed to authorize person'));
  }

  Future<void> updatePersonAuthorization(
      int personId, bool isAuthorized) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/persons/$personId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'is_authorized': isAuthorized}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update authorization');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    required String username,
    required String email,
    required String fullName,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/users/$userId/profile'),
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'full_name': fullName,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data as Map<String, dynamic>;
    }

    throw Exception(data['detail'] ?? 'Failed to update profile.');
  }
}
