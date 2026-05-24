// lib/core/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/auth_response.dart';
import '../models/escort_model.dart';

class AuthService {

  // ── Login ──────────────────────────────────────────────────
  Future<AuthResponse> login({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'motDePasse': motDePasse}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(body);
      }

      throw AuthException(
        message:    body['message'] ?? 'Email ou mot de passe incorrect.',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const AuthException(
        message:    'Impossible de joindre le serveur. Vérifiez votre connexion.',
        statusCode: 0,
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        message:    'Une erreur inattendue est survenue.',
        statusCode: 0,
      );
    }
  }

  // ── Register ───────────────────────────────────────────────
  Future<AuthResponse> register({
    required String pseudo,
    required String email,
    required String telephone,
    required String motDePasse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pseudo':     pseudo,
          'email':      email,
          'telephone':  telephone,
          'motDePasse': motDePasse,
        }),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return AuthResponse.fromJson(body);
      }

      // Gestion des erreurs de validation (ex: email déjà pris)
      final message = _extraireMessage(body);
      throw AuthException(message: message, statusCode: response.statusCode);

    } on SocketException {
      throw const AuthException(
        message:    'Impossible de joindre le serveur. Vérifiez votre connexion.',
        statusCode: 0,
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        message:    'Une erreur inattendue est survenue.',
        statusCode: 0,
      );
    }
  }

  // ── Logout ─────────────────────────────────────────────────
  Future<void> logout(String refreshToken) async {
    try {
      await http.post(
        Uri.parse(ApiConstants.logout),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silencieux : on déconnecte localement quoi qu'il arrive
    }
  }

  // Dans auth_service.dart — ajouter dans la classe AuthService

Future<EscortModel> chargerProfil(String accessToken) async {
  final response = await http.get(
    Uri.parse(ApiConstants.profil),
    headers: {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $accessToken',
    },
  ).timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return EscortModel.fromJson(body['escort'] ?? body);
  }

  throw AuthException(
    message:    'Session expirée. Veuillez vous reconnecter.',
    statusCode: response.statusCode,
  );
}

  // ── Privé : extrait le message d'erreur du backend ─────────
  String _extraireMessage(Map<String, dynamic> body) {
    // Express-validator renvoie parfois un tableau d'erreurs
    if (body['errors'] != null && body['errors'] is List) {
      final errors = body['errors'] as List;
      if (errors.isNotEmpty) {
        return errors.first['msg'] ?? 'Erreur de validation.';
      }
    }
    return body['message'] ?? 'Erreur lors de l\'inscription.';
  }
}

// ── Exception typée ────────────────────────────────────────────
class AuthException implements Exception {
  final String message;
  final int    statusCode;

  const AuthException({required this.message, required this.statusCode});

  @override
  String toString() => 'AuthException($statusCode): $message';
}