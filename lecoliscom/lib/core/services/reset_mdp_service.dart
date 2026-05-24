// lib/core/services/reset_mdp_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ResetMdpService {
  // ── Étape 1 : demander le code ────────────────────────────
  /// Renvoie true si la requête a abouti (même si email inconnu)
  Future<void> demanderCode({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.motDePasseOublie),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      ).timeout(const Duration(seconds: 10));

      // 200 = OK quelle que soit la situation (anti-énumération)
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw ResetException(body['message'] ?? 'Erreur lors de la demande.');
      }
    } on SocketException {
      throw const ResetException('Impossible de joindre le serveur.');
    } on ResetException {
      rethrow;
    } catch (_) {
      throw const ResetException('Une erreur inattendue est survenue.');
    }
  }

  // ── Étape 2 : vérifier le code ────────────────────────────
  /// Renvoie le reinitId si le code est valide
  Future<String> verifierCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifierCode),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'code':  code.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['valide'] == true) {
        return body['reinitId'] as String;
      }

      throw ResetException(body['message'] ?? 'Code invalide ou expiré.');
    } on SocketException {
      throw const ResetException('Impossible de joindre le serveur.');
    } on ResetException {
      rethrow;
    } catch (_) {
      throw const ResetException('Une erreur inattendue est survenue.');
    }
  }

  // ── Étape 3 : changer le mot de passe ─────────────────────
  Future<void> reinitialiserMdp({
    required String reinitId,
    required String nouveauMotDePasse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.reinitialiserMdp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reinitId':          reinitId,
          'nouveauMotDePasse': nouveauMotDePasse,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw ResetException(body['message'] ?? 'Erreur lors de la réinitialisation.');
      }
    } on SocketException {
      throw const ResetException('Impossible de joindre le serveur.');
    } on ResetException {
      rethrow;
    } catch (_) {
      throw const ResetException('Une erreur inattendue est survenue.');
    }
  }
}

// ── Exception typée ────────────────────────────────────────
class ResetException implements Exception {
  final String message;
  const ResetException(this.message);
  @override
  String toString() => 'ResetException: $message';
}
