// lib/features/home/tabs/profil/models/escort_model.dart

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
// MODÈLE ESCORT (utilisateur connecté)
// ─────────────────────────────────────────────────────────
class EscortModel {
  final String  id;
  final String  pseudo;
  final String  email;
  final String  telephone;
  final String? photoUrl;
  final bool    estVerifie;
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
// SESSION MOCK — remplacer par vrai auth (Riverpod/Provider)
// ─────────────────────────────────────────────────────────
class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  EscortModel? _escort;
  bool get estConnecte => _escort != null;
  EscortModel? get escort => _escort;

  // Simule une connexion réussie
  Future<bool> connecter(String email, String motDePasse) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock : tout email/mdp valide fonctionne
    if (email.contains('@') && motDePasse.length >= 6) {
      _escort = EscortModel(
        id:               'escort_001',
        pseudo:           email.split('@').first,
        email:            email,
        telephone:        '+237691000001',
        photoUrl:         'https://randomuser.me/api/portraits/women/44.jpg',
        estVerifie:       true,
        dateInscription:  DateTime.now().subtract(const Duration(days: 45)),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  // Simule une inscription réussie
  Future<bool> inscrire({
    required String pseudo,
    required String email,
    required String telephone,
    required String motDePasse,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _escort = EscortModel(
      id:              'escort_new_${DateTime.now().millisecondsSinceEpoch}',
      pseudo:          pseudo,
      email:           email,
      telephone:       telephone,
      photoUrl:        null,
      estVerifie:      false,
      dateInscription: DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  void deconnecter() {
    _escort = null;
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
      case TypeNotification.systeme:      return Icons.info_outline_rounded;
      case TypeNotification.admin:        return Icons.admin_panel_settings_outlined;
      case TypeNotification.abonnement:   return Icons.workspace_premium_outlined;
      case TypeNotification.publication:  return Icons.article_outlined;
    }
  }

  Color get couleur {
    switch (this) {
      case TypeNotification.systeme:      return Color(0xFF5DB8FF);
      case TypeNotification.admin:        return Color(0xFFB68DFF);
      case TypeNotification.abonnement:   return Color(0xFFFFD700);
      case TypeNotification.publication:  return Color(0xFFFF5DA8);
    }
  }

  String get label {
    switch (this) {
      case TypeNotification.systeme:      return 'Système';
      case TypeNotification.admin:        return 'Admin';
      case TypeNotification.abonnement:   return 'Abonnement';
      case TypeNotification.publication:  return 'Publication';
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