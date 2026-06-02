// lib/core/models/publication_model.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

enum PlanType { premium, standard, basique }

extension PlanTypeExt on PlanType {
  String get label {
    switch (this) {
      case PlanType.premium:  return 'Premium';
      case PlanType.standard: return 'Standard';
      case PlanType.basique:  return 'Basique';
    }
  }

  Color get color {
    switch (this) {
      case PlanType.premium:  return const Color(0xFFFFD700);
      case PlanType.standard: return const Color(0xFFFF5DA8);
      case PlanType.basique:  return const Color(0xFF8A8A9A);
    }
  }

  Color get bgColor {
    switch (this) {
      case PlanType.premium:  return const Color(0x22FFD700);
      case PlanType.standard: return const Color(0x22FF5DA8);
      case PlanType.basique:  return const Color(0x228A8A9A);
    }
  }
}

// ─────────────────────────────────────────────────────────
// IMAGE — transporte id + url pour permettre la suppression
// ─────────────────────────────────────────────────────────
class ImagePub {
  final String id;
  final String url;  // URL proxifiée côté Flutter
  const ImagePub({required this.id, required this.url});
}

class PublicationModel {
  final String id;
  final String escortPseudo;
  final String escortImageProfil;
  final List<String> imageUrls;
  final List<ImagePub> imageItems;
  final String titre;
  final String description;
  
  final String categorie;
  final List<String> categories;

  // Localisation
  final String pays;
  final String region;
  final String ville;
  final String quartier;

  // Contacts
  final String telephone;
  final String whatsapp;
  final String? email;

  final PlanType planType;
  final String planTypeString;        // ← Plus important maintenant
  final Color planColor;
  final Color planBgColor;

  final bool estVerifie;
  final bool estDisponible;
  final String statutBackend;

  final double? tarif;
  final DateTime dateExpiration;
  final DateTime createdAt;
  final int vues;

  final List<AvisModel> avis;
  final int nbAvis;
  final double noteMoyenne;

  PublicationModel({
    required this.id,
    required this.escortPseudo,
    required this.escortImageProfil,
    required this.imageUrls,
    required this.imageItems,
    required this.titre,
    required this.description,
    required this.categorie,
    required this.categories,
    this.pays = 'Cameroun',
    this.region = '',
    required this.ville,
    required this.quartier,
    required this.telephone,
    required this.whatsapp,
    this.email,
    required this.planType,
    required this.planTypeString,
    required this.estVerifie,
    required this.estDisponible,
    this.statutBackend = 'ACTIVE',
    required this.tarif,
    required this.dateExpiration,
    required this.createdAt,
    required this.vues,
    this.avis = const [],
    this.nbAvis = 0,
    this.noteMoyenne = 0.0,
    Color? planColor,
    Color? planBgColor,
  })  : planColor   = planColor   ?? _defaultPlanColor(planType),
        planBgColor = planBgColor ?? _defaultPlanBgColor(planType);

  static Color _defaultPlanColor(PlanType t) {
    switch (t) {
      case PlanType.premium:  return const Color(0xFFFFD700);
      case PlanType.standard: return const Color(0xFFFF5DA8);
      case PlanType.basique:  return const Color(0xFF8A8A9A);
      default:                return const Color(0xFF8A8A9A);
    }
  }

  static Color _defaultPlanBgColor(PlanType t) {
    switch (t) {
      case PlanType.premium:  return const Color(0x22FFD700);
      case PlanType.standard: return const Color(0x22FF5DA8);
      case PlanType.basique:  return const Color(0x228A8A9A);
      default:                return const Color(0x228A8A9A);
    }
  }

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  bool get estActive => dateExpiration.isAfter(DateTime.now());

  String get localisationLabel {
    final parts = <String>[];
    if (quartier.isNotEmpty) parts.add(quartier);
    if (ville.isNotEmpty) parts.add(ville);
    return parts.join(', ');
  }

  int get poidsAffichage {
    switch (planType) {
      case PlanType.premium:  return 3;
      case PlanType.standard: return 2;
      case PlanType.basique:  return 1;
      default: return 1;
    }
  }

  // ─────────────────────────────────────────────────────────
  factory PublicationModel.fromJson(Map<String, dynamic> j) {
    // Images
    final imagesRaw = (j['images'] as List?) ?? [];
    final imageItems = imagesRaw.map<ImagePub>((img) {
      final id = img['id'] as String? ?? '';
      final rawUrl = img['url'] as String? ?? '';
      final proxied = rawUrl.isNotEmpty
          ? '${ApiConstants.baseUrl}/proxy-image?url=${Uri.encodeComponent(rawUrl)}'
          : '';
      return ImagePub(id: id, url: proxied);
    }).toList();

    final imageUrls = imageItems.map((i) => i.url).toList();

    // Escort
    final escort = j['escort'] as Map<String, dynamic>? ?? {};
    final rawPhoto = escort['photoUrl'] as String?;
    final escortImageProfil = rawPhoto != null && rawPhoto.isNotEmpty
        ? '${ApiConstants.baseUrl}/proxy-image?url=${Uri.encodeComponent(rawPhoto)}'
        : '';

    // Catégories
    final catsRaw = (j['categories'] as List?) ?? [];
    final categoriesList = catsRaw
        .map<String>((c) => (c['nom'] as String?)?.trim() ?? '')
        .where((nom) => nom.isNotEmpty)
        .toList();

    final categoriePrincipale = categoriesList.isNotEmpty 
        ? categoriesList.first 
        : (j['categorie'] ?? '');

    // Avis
    final avisRaw = (j['avis'] as List?) ?? [];
    final avis = avisRaw.map((a) => AvisModel.fromJson(a, j['id']?.toString() ?? '')).toList();

    // ── PLAN LOGIC (Correction principale) ─────────────────
    String planStr = (j['planType'] ?? 
                     j['plan']?['nom'] ?? 
                     j['planNom'] ?? 
                     'basique').toString().toLowerCase();

    PlanType parsePlanType(String str) {
      if (str.contains('premium')) return PlanType.premium;
      if (str.contains('standard')) return PlanType.standard;
      return PlanType.basique;
    }

    final pt = parsePlanType(planStr);

    // Couleur depuis le backend (prioritaire)
    Color? planColorFromBackend;
    final accentHex = j['accentColor'] ?? j['plan']?['accentColor'];
    if (accentHex != null && accentHex.toString().isNotEmpty) {
      try {
        final h = accentHex.toString().replaceAll('#', '');
        planColorFromBackend = Color(int.parse('FF$h', radix: 16));
      } catch (_) {}
    }

    return PublicationModel(
      id:                 j['id']?.toString() ?? '',
      escortPseudo:       escort['pseudo'] ?? '',
      escortImageProfil:  escortImageProfil,
      imageUrls:          imageUrls,
      imageItems:         imageItems,
      titre:              j['titre'] ?? '',
      description:        j['description'] ?? '',
      categorie:          categoriePrincipale,
      categories:         categoriesList,
      pays:               j['paysNom'] ?? 'Cameroun',
      region:             j['regionNom'] ?? '',
      ville:              j['villeNom'] ?? '',
      quartier:           j['quartier']?['nom'] ?? j['quartier'] ?? '',
      telephone:          escort['telephone'] ?? '',
      whatsapp:           escort['whatsapp'] ?? escort['telephone'] ?? '',
      email:              escort['email'],
      planType:           pt,
      planTypeString:     planStr,                    // ← Très important
      planColor:          planColorFromBackend,
      estVerifie:         escort['estVerifie'] ?? false,
      estDisponible:      j['estDisponible'] ?? true,
      statutBackend:      j['statut'] ?? 'ACTIVE',
      tarif:              (j['tarif'] as num?)?.toDouble(),
      dateExpiration:     DateTime.tryParse(j['dateExpiration'] ?? '') ?? DateTime.now(),
      createdAt:          DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      vues:               (j['vues'] as num?)?.toInt() ?? 0,
      avis:               avis,
      nbAvis:             (j['nbAvis'] as num? ?? 0).toInt(),
      noteMoyenne:        (j['noteMoyenne'] as num? ?? 0.0).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// AVIS
// ─────────────────────────────────────────────────────────
class AvisModel {
  final String id;
  final String publicationId;
  final int note;
  final String message;
  final DateTime createdAt;

  const AvisModel({
    required this.id,
    required this.publicationId,
    required this.note,
    required this.message,
    required this.createdAt,
  });

  factory AvisModel.fromJson(Map<String, dynamic> j, String pubId) => AvisModel(
        id:            j['id']?.toString() ?? '',
        publicationId: pubId,
        note:          j['note'] ?? 0,
        message:       j['message'] ?? '',
        createdAt:     DateTime.parse(j['createdAt'] ?? DateTime.now().toIso8601String()),
      );
}

// ─────────────────────────────────────────────────────────
// MOTIF SIGNALEMENT
// ─────────────────────────────────────────────────────────
enum SignalementMotif {
  fauxCompte,
  spam,
  contenuInapproprie,
  autre;

  String get label {
    switch (this) {
      case SignalementMotif.fauxCompte:         return 'Faux compte';
      case SignalementMotif.spam:               return 'Spam';
      case SignalementMotif.contenuInapproprie: return 'Contenu inapproprié';
      case SignalementMotif.autre:              return 'Autre';
    }
  }
}



// Liste statique (à remplacer par le référentiel plus tard)
const List<String> categoriesStatiques = [
  'Toutes', 'Milf', 'BBW', 'Ebony', 'Latina', 'Asian', 'Trans', 'Couple',
];

const List<String> villesStatiques = [
  'Toutes', 'Yaoundé', 'Douala', 'Bafoussam', 'Garoua', 'Maroua',
];

// Avis mock
final List<AvisModel> mockAvis = [
  AvisModel(
    id: '1',
    publicationId: 'mock_1',
    note: 5,
    message: 'Très discrète et ponctuelle.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  AvisModel(
    id: '2',
    publicationId: 'mock_1',
    note: 4,
    message: 'Super expérience, cadre agréable.',
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
];