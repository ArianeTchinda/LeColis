import 'package:flutter/material.dart';

/// Définit les caractéristiques d'un forfait (Basique, Standard, Premium)
class PlanAbonnement {
  final String id;
  final String nom;
  final String description;
  final double prix;
  final int nbPublications;
  final int dureeJours;
  final List<String> avantages;
  final Color accentColor;
  final IconData icone;

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
}

/// Définit un abonnement acheté par un utilisateur
class AbonnementSouscrit {
  final String       id;
  final PlanAbonnement plan;
  final DateTime     dateDebut;
  DateTime           dateFin;       // mutable : l'admin peut ajuster l'expiration
  final String       statut;        // 'actif', 'expire'

  /// Nombre de publications ajusté par l'admin (commence à plan.nbPublications).
  /// Mutable pour permettre les ajustements individuels.
  int nbPublicationsAdm;

  AbonnementSouscrit({
    required this.id,
    required this.plan,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
    int? nbPublicationsAdm,
  }) : nbPublicationsAdm = nbPublicationsAdm ?? plan.nbPublications;

  bool get estActif => statut == 'actif' && dateFin.isAfter(DateTime.now());
}