// lib/core/services/abonnement_service.dart
// Service d'abonnement — connecté au backend Express
// Couvre :
//   GET  /abonnements/plans          → listerPlans()       public
//   POST /abonnements/souscrire      → souscrire()         🔐 token
//   GET  /profil/abonnement          → monAbonnement()     🔐 token
//   GET  /profil/historique-abonnements → historique()     🔐 token
//   GET  /profil/transactions        → mesTransactions()   🔐 token

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/abonnement_model.dart';
import '../models/transaction_model.dart';

class AbonnementService {
  // ── Headers communs ──────────────────────────────────────
  static Map<String, String> _publicHeaders() => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $token',
  };

  // ════════════════════════════════════════════════════════
  // GET /abonnements/plans
  // Public — pas de token requis.
  // Retourne la liste des plans actifs triés par ordre croissant.
  // ════════════════════════════════════════════════════════
  static Future<List<PlanAbonnement>> listerPlans() async {
    final res = await http
        .get(
          Uri.parse(ApiConstants.abonnementPlans),
          headers: _publicHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => PlanAbonnement.fromJson(j)).toList();
    }

    throw Exception(
      'Impossible de charger les plans (${res.statusCode}).',
    );
  }

  // ════════════════════════════════════════════════════════
  // GET /profil/abonnement
  // 🔐 Token requis.
  // Retourne l'abonnement ACTIF de l'escort avec ses quotas,
  // ou null si aucun abonnement actif.
  // ════════════════════════════════════════════════════════
  static Future<AbonnementSouscrit?> monAbonnement(String token) async {
    final res = await http
        .get(
          Uri.parse(ApiConstants.profilAbonnement),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      // Le backend renvoie { abonnement: {...} | null }
      final abData = body['abonnement'];
      if (abData == null) return null;
      return AbonnementSouscrit.fromJson(abData);
    }

    throw Exception(
      'Impossible de charger l\'abonnement (${res.statusCode}).',
    );
  }

  // ════════════════════════════════════════════════════════
  // GET /profil/historique-abonnements
  // 🔐 Token requis.
  // Retourne tous les abonnements passés et présents de l'escort.
  // ════════════════════════════════════════════════════════
  static Future<List<AbonnementSouscrit>> historique(String token) async {
    final res = await http
        .get(
          Uri.parse(ApiConstants.profilHistorique),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => AbonnementSouscrit.fromJson(j)).toList();
    }

    throw Exception(
      'Impossible de charger l\'historique (${res.statusCode}).',
    );
  }

  // ════════════════════════════════════════════════════════
  // GET /profil/transactions
  // 🔐 Token requis.
  // Retourne toutes les transactions de paiement de l'escort.
  // ════════════════════════════════════════════════════════
  static Future<List<TransactionModel>> mesTransactions(String token) async {
    final res = await http
        .get(
          Uri.parse(ApiConstants.profilTransactions),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => _transactionFromJson(j)).toList();
    }

    throw Exception(
      'Impossible de charger les transactions (${res.statusCode}).',
    );
  }

  // ════════════════════════════════════════════════════════
  // POST /abonnements/souscrire
  // 🔐 Token requis.
  // [planId]          : ID Prisma du plan choisi
  // [methodePaiement] : label de la méthode (ex: "MTN MoMo")
  //
  // Le backend crée la transaction + l'abonnement en une
  // seule transaction DB et retourne :
  //   { message, abonnement: {...}, transaction: {...} }
  // ════════════════════════════════════════════════════════
  static Future<SouscriptionResult> souscrire(
    String token, {
    required String planId,
    required String methodePaiement,
  }) async {
    final res = await http
        .post(
          Uri.parse(ApiConstants.abonnementSouscrire),
          headers: _authHeaders(token),
          body: jsonEncode({
            'planId':          planId,
            'methodePaiement': methodePaiement,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return SouscriptionResult.fromJson(body);
    }

    // Propager le message d'erreur du backend
    try {
      final err = jsonDecode(res.body);
      throw Exception(err['message'] ?? 'Erreur souscription (${res.statusCode}).');
    } catch (_) {
      throw Exception('Erreur souscription (${res.statusCode}).');
    }
  }

  // ════════════════════════════════════════════════════════
  // HELPER INTERNE — TransactionModel.fromJson
  // Le backend retourne :
  //   { id, planNom, montant, methodePaiement, statut, createdAt }
  // ════════════════════════════════════════════════════════
  static TransactionModel _transactionFromJson(Map<String, dynamic> j) {
    TransactionStatus parseStatut(String? s) {
      switch ((s ?? '').toUpperCase()) {
        case 'SUCCES':      return TransactionStatus.succes;
        case 'EN_ATTENTE':  return TransactionStatus.enAttente;
        case 'ECHEC':       return TransactionStatus.echec;
        default:            return TransactionStatus.enAttente;
      }
    }

    return TransactionModel(
      id:              j['id']?.toString() ?? '',
      planNom:         j['planNom'] ?? '',
      montant:         (j['montant'] ?? 0).toDouble(),
      date:            DateTime.parse(j['createdAt'] ?? DateTime.now().toIso8601String()),
      statut:          parseStatut(j['statut']),
      methodePaiement: j['methodePaiement'] ?? '',
    );
  }
}

// ════════════════════════════════════════════════════════
// MODÈLE RÉSULTAT SOUSCRIPTION
// Retourné par souscrire() — contient le message de confirmation
// + l'abonnement créé + la transaction associée.
// ════════════════════════════════════════════════════════
class SouscriptionResult {
  final String             message;
  final AbonnementSouscrit abonnement;
  final TransactionModel   transaction;

  const SouscriptionResult({
    required this.message,
    required this.abonnement,
    required this.transaction,
  });

  factory SouscriptionResult.fromJson(Map<String, dynamic> j) {
    TransactionStatus parseStatut(String? s) {
      switch ((s ?? '').toUpperCase()) {
        case 'SUCCES':      return TransactionStatus.succes;
        case 'EN_ATTENTE':  return TransactionStatus.enAttente;
        case 'ECHEC':       return TransactionStatus.echec;
        default:            return TransactionStatus.enAttente;
      }
    }

    final tr = j['transaction'] as Map<String, dynamic>;

    return SouscriptionResult(
      message:     j['message'] ?? 'Abonnement souscrit.',
      abonnement:  AbonnementSouscrit.fromJson(j['abonnement']),
      transaction: TransactionModel(
        id:              tr['id']?.toString() ?? '',
        planNom:         tr['planNom'] ?? '',
        montant:         (tr['montant'] ?? 0).toDouble(),
        date:            DateTime.parse(tr['createdAt'] ?? DateTime.now().toIso8601String()),
        statut:          parseStatut(tr['statut']),
        methodePaiement: tr['methodePaiement'] ?? '',
      ),
    );
  }
}