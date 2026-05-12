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
  final String id;
  final PlanAbonnement plan;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String statut; // 'actif', 'expire'

  const AbonnementSouscrit({
    required this.id,
    required this.plan,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
  });

  bool get estActif => statut == 'actif' && dateFin.isAfter(DateTime.now());
}