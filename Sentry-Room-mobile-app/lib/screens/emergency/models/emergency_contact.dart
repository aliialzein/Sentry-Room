class EmergencyContact {
  final String name;
  final String role;
  final String? phone;
  final String? email;

  const EmergencyContact({
    required this.name,
    required this.role,
    this.phone,
    this.email,
  });

  EmergencyContact copyWith({
    String? name,
    String? role,
    String? phone,
    String? email,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'phone': phone,
      'email': email,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    String? normalize(Object? value) {
      if (value == null) return null;
      final trimmed = value.toString().trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return EmergencyContact(
      name: json['name']?.toString().trim() ?? '',
      role: json['role']?.toString().trim() ?? '',
      phone: normalize(json['phone']),
      email: normalize(json['email']),
    );
  }
}
