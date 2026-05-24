// lib/core/models/auth_response.dart

import '../models/escort_model.dart';

class AuthResponse {
  final String      accessToken;
  final String      refreshToken;
  final EscortModel escort;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.escort,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken:  json['accessToken'],
    refreshToken: json['refreshToken'],
    escort:       EscortModel.fromJson(json['escort']),
  );
}