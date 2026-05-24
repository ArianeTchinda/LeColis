// lib/features/home/tabs/profil/models/escort_model.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/models/auth_response.dart';

// ─────────────────────────────────────────────────────────
// MODÈLE ESCORT (utilisateur connecté)
// ─────────────────────────────────────────────────────────
class EscortModel {
  final String   id;
  final String   pseudo;
  final String   email;
  final String   telephone;
  final String?  photoUrl;
  final bool     estVerifie;
  final DateTime dateInscription;

  const EscortModel({
    required this.id,
    required this.pseudo,
    required this.email,
    required this.telephone,
    this.photoUrl,
    required this.estVerifie,
    required this.dateInscription,
  });

  factory EscortModel.fromJson(Map<String, dynamic> json) => EscortModel(
    id:              json['id'],
    pseudo:          json['pseudo'],
    email:           json['email'],
    telephone:       json['telephone'] ?? '',
    photoUrl:        json['photoUrl'],
    estVerifie:      json['estVerifie'] ?? false,
    dateInscription: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String()),
  );
}

// ─────────────────────────────────────────────────────────
// MODÈLE PUBLICATION GÉRÉE (côté profil)
// ─────────────────────────────────────────────────────────
enum StatutPublication { active, expiree, brouillon }

extension StatutPublicationExt on StatutPublication {
  String get label {
    switch (this) {
      case StatutPublication.active:    return 'Active';
      case StatutPublication.expiree:   return 'Expirée';
      case StatutPublication.brouillon: return 'Brouillon';
    }
  }

  Color get couleur {
    switch (this) {
      case StatutPublication.active:    return const Color(0xFF25D366);
      case StatutPublication.expiree:   return const Color(0xFF8A8A9A);
      case StatutPublication.brouillon: return const Color(0xFFFFB800);
    }
  }
}

class PublicationGestion {
  final String            id;
  final String            titre;
  final String            categorie;
  final String?           imageUrl;
  final StatutPublication statut;
  final int               vues;
  final DateTime          dateExpiration;

  const PublicationGestion({
    required this.id,
    required this.titre,
    required this.categorie,
    this.imageUrl,
    required this.statut,
    required this.vues,
    required this.dateExpiration,
  });

  int get joursRestants =>
      dateExpiration.difference(DateTime.now()).inDays.clamp(0, 9999);
}

// ─────────────────────────────────────────────────────────
// SESSION MANAGER — auth réelle via API
// ─────────────────────────────────────────────────────────
class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final AuthService _authService = AuthService();

  EscortModel? _escort;
  String?      _accessToken;
  String?      _refreshToken;
  String?      _derniereErreur;

  bool         get estConnecte    => _escort != null;
  EscortModel? get escort         => _escort;
  String?      get accessToken    => _accessToken;
  String?      get derniereErreur => _derniereErreur;

  // ── Login ────────────────────────────────────────────────
  Future<bool> connecter(String email, String motDePasse) async {
    _derniereErreur = null;
    try {
      final res = await _authService.login(
        email:      email,
        motDePasse: motDePasse,
      );
      await _sauvegarderSession(res);
      return true;
    } on AuthException catch (e) {
      _derniereErreur = e.message;
      return false;
    } catch (_) {
      _derniereErreur = 'Erreur réseau. Vérifiez votre connexion.';
      return false;
    }
  }

  // ── Register ─────────────────────────────────────────────
  Future<bool> inscrire({
    required String pseudo,
    required String email,
    required String telephone,
    required String motDePasse,
  }) async {
    _derniereErreur = null;
    try {
      final res = await _authService.register(
        pseudo:     pseudo,
        email:      email,
        telephone:  telephone,
        motDePasse: motDePasse,
      );
      await _sauvegarderSession(res);
      return true;
    } on AuthException catch (e) {
      _derniereErreur = e.message;
      return false;
    } catch (_) {
      _derniereErreur = 'Erreur réseau. Vérifiez votre connexion.';
      return false;
    }
  }

  // ── Déconnexion ──────────────────────────────────────────
  Future<void> deconnecter() async {
    if (_refreshToken != null) {
      await _authService.logout(_refreshToken!);
    }
    _escort       = null;
    _accessToken  = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    notifyListeners();
  }

  // ── Restaurer session au démarrage de l'app ──────────────
  Future<void> restaurer() async {
    final prefs   = await SharedPreferences.getInstance();
    _accessToken  = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');
    // Si token présent → recharger le profil via GET /profil
    // (à implémenter lors de l'intégration du ProfilService)
    notifyListeners();
  }

  // ── Privé ────────────────────────────────────────────────
  Future<void> _sauvegarderSession(AuthResponse res) async {
    _escort       = res.escort;
    _accessToken  = res.accessToken;
    _refreshToken = res.refreshToken;
    final prefs   = await SharedPreferences.getInstance();
    await prefs.setString('accessToken',  res.accessToken);
    await prefs.setString('refreshToken', res.refreshToken);
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────
// MODÈLE NOTIFICATION
// ─────────────────────────────────────────────────────────
enum TypeNotification { systeme, admin, abonnement, publication }

extension TypeNotificationExt on TypeNotification {
  IconData get icone {
    switch (this) {
      case TypeNotification.systeme:     return Icons.info_outline_rounded;
      case TypeNotification.admin:       return Icons.admin_panel_settings_outlined;
      case TypeNotification.abonnement:  return Icons.workspace_premium_outlined;
      case TypeNotification.publication: return Icons.article_outlined;
    }
  }

  Color get couleur {
    switch (this) {
      case TypeNotification.systeme:     return const Color(0xFF5DB8FF);
      case TypeNotification.admin:       return const Color(0xFFB68DFF);
      case TypeNotification.abonnement:  return const Color(0xFFFFD700);
      case TypeNotification.publication: return const Color(0xFFFF5DA8);
    }
  }

  String get label {
    switch (this) {
      case TypeNotification.systeme:     return 'Système';
      case TypeNotification.admin:       return 'Admin';
      case TypeNotification.abonnement:  return 'Abonnement';
      case TypeNotification.publication: return 'Publication';
    }
  }
}

class NotificationModel {
  final String           id;
  final TypeNotification type;
  final String           titre;
  final String           message;
  final DateTime         date;
  bool                   lue;

  NotificationModel({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    required this.date,
    this.lue = false,
  });
}

// ─────────────────────────────────────────────────────────
// DONNÉES MOCK NOTIFICATIONS
// ─────────────────────────────────────────────────────────
List<NotificationModel> mockNotifications = [
  NotificationModel(
    id:      'n1',
    type:    TypeNotification.admin,
    titre:   'Bienvenue sur LeColis !',
    message: 'Votre compte a été validé par notre équipe. Vous pouvez maintenant publier.',
    date:    DateTime.now().subtract(const Duration(hours: 2)),
    lue:     false,
  ),
  NotificationModel(
    id:      'n2',
    type:    TypeNotification.abonnement,
    titre:   'Abonnement bientôt expiré',
    message: 'Votre plan Standard expire dans 22 jours. Pensez à le renouveler.',
    date:    DateTime.now().subtract(const Duration(days: 1)),
    lue:     false,
  ),
  NotificationModel(
    id:      'n3',
    type:    TypeNotification.publication,
    titre:   'Publication approuvée',
    message: '"Disponible ce soir à Bastos" est maintenant visible par les visiteurs.',
    date:    DateTime.now().subtract(const Duration(days: 2)),
    lue:     true,
  ),
  NotificationModel(
    id:      'n4',
    type:    TypeNotification.systeme,
    titre:   'Mise à jour de la plateforme',
    message: 'De nouvelles fonctionnalités sont disponibles. Découvrez les filtres avancés.',
    date:    DateTime.now().subtract(const Duration(days: 5)),
    lue:     true,
  ),
];

// ─────────────────────────────────────────────────────────
// DONNÉES MOCK PUBLICATIONS GÉRÉES
// ─────────────────────────────────────────────────────────
final List<PublicationGestion> mockPublicationsEscort = [
  PublicationGestion(
    id:             'pg_001',
    titre:          'Disponible ce soir à Bastos',
    categorie:      'Milf',
    imageUrl:       'https://picsum.photos/seed/pg1/400/300',
    statut:         StatutPublication.active,
    vues:           142,
    dateExpiration: DateTime.now().add(const Duration(days: 22)),
  ),
  PublicationGestion(
    id:             'pg_002',
    titre:          'Massage relaxant, centre ville',
    categorie:      'Milf',
    imageUrl:       'https://picsum.photos/seed/pg2/400/300',
    statut:         StatutPublication.brouillon,
    vues:           0,
    dateExpiration: DateTime.now().add(const Duration(days: 22)),
  ),
  PublicationGestion(
    id:             'pg_003',
    titre:          'Ancienne publication expirée',
    categorie:      'Milf',
    imageUrl:       'https://picsum.photos/seed/pg3/400/300',
    statut:         StatutPublication.expiree,
    vues:           89,
    dateExpiration: DateTime.now().subtract(const Duration(days: 5)),
  ),
];