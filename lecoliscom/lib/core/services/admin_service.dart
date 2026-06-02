// lib/features/admin/services/admin_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/admin_models.dart';   // ← Correction d'import

class AdminService {
  static String get _baseUrl => '${ApiConstants.baseUrl}/admin';

  // Singleton
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  // ─────────────────────────────────────────────────────────
  // AUTHENTIFICATION
  // ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'motDePasse': motDePasse,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('adminAccessToken', data['accessToken']);
        await prefs.setString('adminRefreshToken', data['refreshToken']);

        return {'success': true, 'admin': data['admin']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Identifiants incorrects'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau : Impossible de contacter le serveur.',
      };
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('adminAccessToken');
    await prefs.remove('adminRefreshToken');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('adminAccessToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────────────────
  // DASHBOARD & DONNÉES
  // ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erreur getDashboardStats: $e');
    }
    return null;
  }

  Future<List<dynamic>> getEscorts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/escorts'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        return res['data'] ?? res;
      }
    } catch (e) {
      print('Erreur getEscorts: $e');
    }
    return [];
  }

  Future<List<dynamic>> getSignalements() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/signalements'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      }
    } catch (e) {
      print('Erreur getSignalements: $e');
    }
    return [];
  }

  Future<List<dynamic>> getPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/plans'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Le backend retourne un tableau direct (pas { data: [...] })
        if (data is List) return data;
        return data['data'] ?? [];
      }
    } catch (e) {
      print('Erreur getPlans: $e');
    }
    return [];
  }

  // ─────────────────────────────────────────────────────────
  // ACTIONS SUR COMPTES
  // ─────────────────────────────────────────────────────────

  Future<bool> verifierEscort(String id, {bool estVerifie = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/escorts/$id/verifier'),
        headers: await _getHeaders(),
        body: jsonEncode({'estVerifie': estVerifie}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur verifierEscort: $e');
      return false;
    }
  }

  Future<bool> sanctionnerEscort(
    String id,
    String type,
    String motif, {
    int? dureeJours,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/escorts/$id/sanctionner'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'type': type,
          'motif': motif,
          if (dureeJours != null) 'dureeJours': dureeJours,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur sanctionnerEscort: $e');
      return false;
    }
  }

  Future<bool> debloquerEscort(String id) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/escorts/$id/debloquer'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur debloquerEscort: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // SIGNALEMENTS
  // ─────────────────────────────────────────────────────────

  Future<bool> traiterSignalement(String id, StatutSignalement statut) async {
    // Convertit l'enum Dart vers le format attendu par le backend Prisma :
    //   traite    → TRAITE
    //   ignore    → IGNORE
    //   enAttente → EN_ATTENTE  (rouvrir pour révision)
    String statutStr;
    switch (statut) {
      case StatutSignalement.traite:    statutStr = 'TRAITE';    break;
      case StatutSignalement.ignore:    statutStr = 'IGNORE';    break;
      case StatutSignalement.enAttente: statutStr = 'EN_ATTENTE'; break;
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/signalements/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'statut': statutStr}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur traiterSignalement: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // NOTIFICATIONS
  // ─────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────
  // ABONNEMENTS
  // ─────────────────────────────────────────────────────────

  /// Ajuste un abonnement par delta de jours (+1 / -1) et/ou quota de publications.
  /// Le backend vérifie qu'il reste au moins 1 jour après ajustement.
  /// Retourne { ok: bool, message: string, dateFin?: string }
  Future<Map<String, dynamic>> ajusterAbonnement(
    String id, {
    int?      deltaJours,        // +1 pour ajouter 1 jour, -1 pour en retirer 1
    int?      nbPublicationsAdm, // nouveau quota
  }) async {
    try {
      final body = <String, dynamic>{};
      if (deltaJours        != null) body['deltaJours']        = deltaJours;
      if (nbPublicationsAdm != null) body['nbPublicationsAdm'] = nbPublicationsAdm;

      final response = await http.put(
        Uri.parse('$_baseUrl/abonnements/$id/ajuster'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return { 'ok': true, 'message': data['message'], 'dateFin': data['dateFin'] };
      }

      // 400 = règle minimum 1 jour → on récupère le message du backend
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      return { 'ok': false, 'message': err['message'] ?? 'Erreur ajustement.' };
    } catch (e) {
      print('Erreur ajusterAbonnement: $e');
      return { 'ok': false, 'message': 'Erreur réseau.' };
    }
  }

  /// Offre un plan cadeau à un ou plusieurs comptes sans paiement.
  /// [escortId] : compte principal (toujours inclus)
  /// [planId]   : ID Prisma du plan à offrir
  /// [escortIds]: autres comptes à inclure (cadeau groupé, max 50)
  Future<bool> offrirCadeau(
    String escortId, {
    required String  planId,
    List<String>     escortIds = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/escorts/$escortId/cadeau'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'planId':    planId,
          if (escortIds.isNotEmpty) 'escortIds': escortIds,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Erreur offrirCadeau: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // PLANS
  // ─────────────────────────────────────────────────────────

  /// Supprime un plan personnalisé (les plans de base sont protégés côté backend).
  /// Retourne { ok: bool, message: String }
  Future<Map<String, dynamic>> supprimerPlan(String planId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/plans/$planId'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return {'ok': true, 'message': 'Plan supprimé.'};
      }
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      return {'ok': false, 'message': err['message'] ?? 'Erreur suppression.'};
    } catch (e) {
      print('Erreur supprimerPlan: $e');
      return {'ok': false, 'message': 'Erreur réseau.'};
    }
  }

  Future<bool> modifierPlan(PlanConfig plan) async {
    // Convertit Color → hex "#RRGGBB"
    final hex = '#${plan.accentColor.value.toRadixString(16).substring(2).toUpperCase()}';

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/plans/${plan.id}'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'prix':           plan.prix,
          'nbPublications': plan.nbPublications,
          'dureeJours':     plan.dureeJours,
          'description':    plan.description,
          'avantages':      plan.avantages,
          'accentColor':    hex,            // ← AJOUT
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur modifierPlan: $e');
      return false;
    }
  }

  /// POST /admin/plans — crée un nouveau plan abonnement custom
/// Retourne l'ID réel du plan créé côté backend, ou null en cas d'erreur.
Future<String?> creerPlan({
  required String      nom,
  required String      description,
  required double      prix,
  required int         nbPublications,
  required int         dureeJours,
  required List<String> avantages,
  required String      accentColor,   // format hex "#RRGGBB"
}) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/plans'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'nom':            nom,
        'description':    description,
        'prix':           prix,
        'nbPublications': nbPublications,
        'dureeJours':     dureeJours,
        'avantages':      avantages,
        'accentColor':    accentColor,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['id'] as String?;
    }
    final err = jsonDecode(response.body);
    print('Erreur creerPlan: ${err['message']}');
    return null;
  } catch (e) {
    print('Erreur creerPlan: $e');
    return null;
  }
}

  Future<bool> envoyerNotification({
    required String titre,
    required String message,
    required String type,
    required String cible,
    List<String>? escortIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/envoyer'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'titre': titre,
          'message': message,
          'type': type,
          'cible': cible,
          if (escortIds != null && escortIds.isNotEmpty) 'escortIds': escortIds,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Erreur envoyerNotification: $e');
      return false;
    }
  }

 // ─────────────────────────────────────────────────────────
  // ANALYTICS
  // ─────────────────────────────────────────────────────────
 
  /// Récupère toutes les données analytiques pour les graphiques.
  /// Retourne null en cas d'erreur réseau.
  Future<Map<String, dynamic>?> getAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/analytics'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Erreur getAnalytics: $e');
    }
    return null;
  }
 
  // ─────────────────────────────────────────────────────────
  // HISTORIQUE NOTIFICATIONS
  // ─────────────────────────────────────────────────────────
 
  /// [page]     : numéro de page (défaut 1)
  /// [limite]   : nb d'items par page (max 100)
  /// [cible]    : filtre cible ('TOUS' | 'INDIVIDUEL' | 'MULTIPLE')
  /// [escortId] : filtre sur un compte spécifique
  Future<Map<String, dynamic>> getHistoriqueNotifications({
    int    page     = 1,
    int    limite   = 20,
    String? cible,
    String? escortId,
  }) async {
    try {
      final params = <String, String>{
        'page':   '$page',
        'limite': '$limite',
        if (cible    != null) 'cible':    cible,
        if (escortId != null) 'escortId': escortId,
      };
 
      final uri = Uri.parse('$_baseUrl/notifications/historique')
          .replace(queryParameters: params);
 
      final response = await http.get(uri, headers: await _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Erreur getHistoriqueNotifications: $e');
    }
    return {'data': [], 'total': 0, 'page': page, 'limite': limite};
  }
 

}