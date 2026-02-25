class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isEmailVerified;
  final bool hasProfile;
  final String? createdAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isEmailVerified,
    this.hasProfile = false,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? '',
      isEmailVerified: json['is_email_verified'] ?? false,
      hasProfile: json['has_profile'] ?? false,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'is_email_verified': isEmailVerified,
      'has_profile': hasProfile,
      'created_at': createdAt,
    };
  }
}

class AuthResponse {
  final String access;
  final String refresh;
  final User user;

  AuthResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      access: json['access'],
      refresh: json['refresh'],
      user: User.fromJson(json['user']),
    );
  }
}

class RegisterResponse {
  final bool success;
  final String message;
  final User? data;

  RegisterResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? User.fromJson(json['data']) : null,
    );
  }
}
