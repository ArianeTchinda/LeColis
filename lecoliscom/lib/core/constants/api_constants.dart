// lib/core/constants/api_constants.dart

import 'package:flutter/foundation.dart';

class ApiConstants {

  // ── À CHANGER UNIQUEMENT ICI au moment du déploiement ───
  static const String _prodUrl = 'https://api.lecolis.com/api';
  // ────────────────────────────────────────────────────────

  static String get baseUrl {
    // En production → toujours l'URL du vrai serveur
    if (kReleaseMode) return _prodUrl;

    // En développement → selon la plateforme d'exécution
    if (kIsWeb) return 'http://localhost:3000/api';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api'; // émulateur Android
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:3000/api';
      default:
        return 'http://localhost:3000/api';
    }
  }

  // ── Auth ─────────────────────────────────────────────────
  static String get login    => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get refresh  => '$baseUrl/auth/refresh';
  static String get logout   => '$baseUrl/auth/logout';

  // ── Reset mot de passe (3 étapes) ────────────────────────
  static String get motDePasseOublie  => '$baseUrl/auth/mot-de-passe-oublie';
  static String get verifierCode      => '$baseUrl/auth/verifier-code';
  static String get reinitialiserMdp  => '$baseUrl/auth/reinitialiser-mdp';

  // ── Profil ───────────────────────────────────────────────
  static String get profil                  => '$baseUrl/profil';
  static String get profilPhoto             => '$baseUrl/profil/photo';
  static String get profilMotDePasse        => '$baseUrl/profil/mot-de-passe';
  static String get profilNotifications     => '$baseUrl/profil/notifications';
  static String get profilTransactions      => '$baseUrl/profil/transactions';
  static String get profilAbonnement        => '$baseUrl/profil/abonnement';
  static String get profilHistorique        => '$baseUrl/profil/historique-abonnements';
  static String get profilPublications      => '$baseUrl/profil/publications';

  // ── Publications publiques ───────────────────────────────
  static String get publications => '$baseUrl/publications';

  // ── Abonnements ──────────────────────────────────────────
  static String get abonnementPlans     => '$baseUrl/abonnements/plans';
  static String get abonnementSouscrire => '$baseUrl/abonnements/souscrire';

  // ── Référentiel ──────────────────────────────────────────
  static String get localisationPays      => '$baseUrl/localisation/pays';
  static String get localisationRegions   => '$baseUrl/localisation/regions';
  static String get localisationVilles    => '$baseUrl/localisation/villes';
  static String get localisationQuartiers => '$baseUrl/localisation/quartiers';
  static String get categories            => '$baseUrl/categories';
  static String get categoriesFlat        => '$baseUrl/categories/flat';
}