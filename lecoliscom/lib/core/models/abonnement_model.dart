// lib/core/models/abonnement_model.dart

import 'package:flutter/material.dart';

/// Définit les caractéristiques d'un forfait (Basique, Standard, Premium)
class PlanAbonnement {
  final String     id;
  final String     nom;
  final String     description;
  final double     prix;
  final int        nbPublications;
  final int        dureeJours;
  final List<String> avantages;
  final Color      accentColor;
  final IconData   icone;

  const PlanAbonnement({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.nbPublications,
    required this.dureeJours,
    required this.avantages,
    required this.accentColor,
    required this.icone,
  });

  /// Construit depuis la réponse JSON du backend
  /// Champs backend : id, nom, description, prix, nbPublications,
  ///                  dureeJours, avantages (JSON array), accentColor (hex)
  factory PlanAbonnement.fromJson(Map<String, dynamic> j) {
    // Convertit la couleur hex "#FF5DA8" → Color
    Color parseColor(String? hex) {
      if (hex == null || hex.isEmpty) return const Color(0xFF8A8A9A);
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    }

    // Convertit le nom du plan en icône
    IconData parseIcone(String nom) {
      switch (nom.toLowerCase()) {
        case 'premium':  return Icons.workspace_premium;
        case 'standard': return Icons.verified_outlined;
        default:         return Icons.star_outline;
      }
    }

    final avantagesRaw = j['avantages'];
    final avantages = avantagesRaw is List
        ? avantagesRaw.map((e) => e.toString()).toList()
        : <String>[];

    return PlanAbonnement(
      id:             j['id'],
      nom:            j['nom'],
      description:    j['description'] ?? '',
      prix:           (j['prix'] ?? 0).toDouble(),
      nbPublications: j['nbPublications'] ?? 1,
      dureeJours:     j['dureeJours'] ?? 7,
      avantages:      avantages,
      accentColor:    parseColor(j['accentColor']),
      icone:          parseIcone(j['nom'] ?? ''),
    );
  }
}

/// Définit un abonnement souscrit par un utilisateur
class AbonnementSouscrit {
  final String       id;
  final PlanAbonnement plan;
  final DateTime     dateDebut;
  DateTime           dateFin;       // mutable : l'admin peut ajuster
  final String       statut;        // 'ACTIF' | 'EXPIRE'

  /// Quota ajusté par l'admin. Vient de quotaTotal dans la réponse API.
  int nbPublicationsAdm;

  /// Champs enrichis renvoyés par GET /profil/abonnement
  final int quotaTotal;
  final int quotaUtilise;
  final int quotaRestant;

  AbonnementSouscrit({
    required this.id,
    required this.plan,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
    int? nbPublicationsAdm,
    this.quotaTotal   = 0,
    this.quotaUtilise = 0,
    this.quotaRestant = 0,
  }) : nbPublicationsAdm = nbPublicationsAdm ?? plan.nbPublications;

  bool get estActif =>
      statut == 'ACTIF' && dateFin.isAfter(DateTime.now());

  int get joursRestants =>
      dateFin.difference(DateTime.now()).inDays.clamp(0, 9999);

  /// Construit depuis la réponse de GET /profil/abonnement
  /// Le backend renvoie : { abonnement: { id, plan:{...}, dateFin,
  ///   statut, quotaTotal, quotaUtilise, quotaRestant, createdAt } }
  factory AbonnementSouscrit.fromJson(Map<String, dynamic> j) {
    return AbonnementSouscrit(
      id:               j['id'],
      plan:             PlanAbonnement.fromJson(j['plan']),
      dateDebut:        DateTime.parse(j['createdAt']),
      dateFin:          DateTime.parse(j['dateFin']),
      statut:           j['statut'] ?? 'ACTIF',
      nbPublicationsAdm: j['quotaTotal'],
      quotaTotal:       j['quotaTotal']   ?? 1,
      quotaUtilise:     j['quotaUtilise'] ?? 0,
      quotaRestant:     j['quotaRestant'] ?? 1,
    );
  }
}