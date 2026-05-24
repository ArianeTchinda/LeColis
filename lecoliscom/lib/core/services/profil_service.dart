// lib/core/services/profil_service.dart
//
// Couche service pour toutes les routes /profil/* et /publications/*
// Alignée sur profilController.js, publicationController.js,
// abonnementController.js et referentielController.js

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/abonnement_model.dart';
import '../models/publication_model.dart';

// ─────────────────────────────────────────────────────────
// Modèle notification (aligné sur le controller backend)
// ─────────────────────────────────────────────────────────
class NotificationApiModel {
  final String   id;
  final String   type;    // SYSTEME | ADMIN | ABONNEMENT | PUBLICATION
  final String   titre;
  final String   message;
  final bool     lue;
  final DateTime date;

  NotificationApiModel({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    required this.lue,
    required this.date,
  });

  factory NotificationApiModel.fromJson(Map<String, dynamic> j) =>
      NotificationApiModel(
        id:      j['id'],
        type:    j['type']    ?? 'SYSTEME',
        titre:   j['titre']   ?? '',
        message: j['message'] ?? '',
        lue:     j['lue']     ?? false,
        date:    DateTime.parse(j['createdAt']),
      );
}

// ─────────────────────────────────────────────────────────
// Modèle localisation (référentiel)
// ─────────────────────────────────────────────────────────
class QuartierRef {
  final String id;
  final String nom;
  const QuartierRef({required this.id, required this.nom});
  factory QuartierRef.fromJson(Map<String, dynamic> j) =>
      QuartierRef(id: j['id'], nom: j['nom']);
}

class VilleRef {
  final String id;
  final String nom;
  const VilleRef({required this.id, required this.nom});
  factory VilleRef.fromJson(Map<String, dynamic> j) =>
      VilleRef(id: j['id'], nom: j['nom']);
}

class RegionRef {
  final String id;
  final String nom;
  const RegionRef({required this.id, required this.nom});
  factory RegionRef.fromJson(Map<String, dynamic> j) =>
      RegionRef(id: j['id'], nom: j['nom']);
}

class PaysRef {
  final String id;
  final String nom;
  final String drapeau;
  const PaysRef({required this.id, required this.nom, required this.drapeau});
  factory PaysRef.fromJson(Map<String, dynamic> j) =>
      PaysRef(id: j['id'], nom: j['nom'], drapeau: j['drapeau'] ?? '');
}

class CategorieRef {
  final String id;
  final String nom;
  const CategorieRef({required this.id, required this.nom});
  factory CategorieRef.fromJson(Map<String, dynamic> j) =>
      CategorieRef(id: j['id'], nom: j['nom']);
}

// ─────────────────────────────────────────────────────────
// SERVICE PRINCIPAL
// ─────────────────────────────────────────────────────────
class ProfilService {
  final String _token;

  ProfilService(this._token);

  Map<String, String> get _headers => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $_token',
  };

  // ══════════════════════════════════════════════════════
  // ABONNEMENT
  // ══════════════════════════════════════════════════════

  /// GET /profil/abonnement
  /// Retourne l'abonnement actif avec quotas, ou null si aucun
  Future<AbonnementSouscrit?> getAbonnement() async {
    final res = await http.get(
      Uri.parse(ApiConstants.profilAbonnement),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['abonnement'] == null) return null;
      return AbonnementSouscrit.fromJson(body['abonnement']);
    }
    throw Exception('Erreur abonnement (${res.statusCode})');
  }

  /// GET /profil/historique-abonnements
  Future<List<AbonnementSouscrit>> getHistoriqueAbonnements() async {
    final res = await http.get(
      Uri.parse(ApiConstants.profilHistorique),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((j) => AbonnementSouscrit.fromJson(j)).toList();
    }
    throw Exception('Erreur historique abonnements (${res.statusCode})');
  }

  // ══════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════

  /// GET /profil/notifications
  Future<List<NotificationApiModel>> getNotifications() async {
    final res = await http.get(
      Uri.parse(ApiConstants.profilNotifications),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((j) => NotificationApiModel.fromJson(j)).toList();
    }
    throw Exception('Erreur notifications (${res.statusCode})');
  }

  /// PUT /profil/notifications/:id/lue
  Future<void> marquerNotificationLue(String id) async {
    await http.put(
      Uri.parse('${ApiConstants.profilNotifications}/$id/lue'),
      headers: _headers,
    ).timeout(const Duration(seconds: 5));
  }

  // ══════════════════════════════════════════════════════
  // PUBLICATIONS (côté profil)
  // ══════════════════════════════════════════════════════

  /// GET /profil/publications — mes publications
  Future<List<PublicationModel>> getMesPublications() async {
    final res = await http.get(
      Uri.parse(ApiConstants.profilPublications),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((j) => PublicationModel.fromJson(j)).toList();
    }
    throw Exception('Erreur publications (${res.statusCode})');
  }

  /// POST /profil/publications — créer une publication (sans images)
  /// Retourne la publication créée (statut BROUILLON)
  Future<PublicationModel> creerPublication({
    required String titre,
    required String description,
    required bool   estDisponible,
    double?         tarif,
    String?         quartierId,
    required String villeNom,
    required String regionNom,
    String          paysNom = 'Cameroun',
    List<String>    categorieIds = const [],
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.profilPublications),
      headers: _headers,
      body: jsonEncode({
        'titre':        titre,
        'description':  description,
        'estDisponible': estDisponible,
        if (tarif      != null) 'tarif':      tarif,
        if (quartierId != null) 'quartierId': quartierId,
        'villeNom':     villeNom,
        'regionNom':    regionNom,
        'paysNom':      paysNom,
        if (categorieIds.isNotEmpty) 'categorieIds': categorieIds,
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 201) {
      return PublicationModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? 'Erreur création publication');
  }

  /// POST /profil/publications/:id/images — upload images (multipart)
  /// Passe la pub de BROUILLON → ACTIVE automatiquement côté backend
  Future<PublicationModel> ajouterImages(
      String pubId, List<Uint8List> images) async {
    final uri     = Uri.parse('${ApiConstants.profilPublications}/$pubId/images');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_token';

    for (int i = 0; i < images.length; i++) {
      request.files.add(http.MultipartFile.fromBytes(
        'images',
        images[i],
        filename: 'image_$i.jpg',
      ));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res      = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      return PublicationModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Erreur upload images (${res.statusCode})');
  }

  /// PUT /profil/publications/:id — modifier une publication
  Future<PublicationModel> modifierPublication(
    String pubId, {
    String?      titre,
    String?      description,
    bool?        estDisponible,
    double?      tarif,
    String?      quartierId,
    String?      villeNom,
    String?      regionNom,
    String?      paysNom,
    List<String>? categorieIds,
  }) async {
    final body = <String, dynamic>{
      if (titre        != null) 'titre':        titre,
      if (description  != null) 'description':  description,
      if (estDisponible!= null) 'estDisponible': estDisponible,
      if (tarif        != null) 'tarif':         tarif,
      if (quartierId   != null) 'quartierId':    quartierId,
      if (villeNom     != null) 'villeNom':      villeNom,
      if (regionNom    != null) 'regionNom':     regionNom,
      if (paysNom      != null) 'paysNom':       paysNom,
      if (categorieIds != null) 'categorieIds':  categorieIds,
    };

    final res = await http.put(
      Uri.parse('${ApiConstants.profilPublications}/$pubId'),
      headers: _headers,
      body:    jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return PublicationModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    final b = jsonDecode(res.body);
    throw Exception(b['message'] ?? 'Erreur modification');
  }

  /// DELETE /profil/publications/:id
  Future<void> supprimerPublication(String id) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.profilPublications}/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Erreur suppression (${res.statusCode})');
    }
  }

  /// DELETE /profil/publications/:id/images/:imageId
  Future<void> supprimerImage(String pubId, String imageId) async {
    final res = await http.delete(
      Uri.parse('${ApiConstants.profilPublications}/$pubId/images/$imageId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Erreur suppression image (${res.statusCode})');
    }
  }

  // ══════════════════════════════════════════════════════
  // PROFIL (infos personnelles)
  // ══════════════════════════════════════════════════════

  /// PUT /profil — modifier pseudo et/ou téléphone
  Future<void> updateProfil({
    required String pseudo,
    required String telephone,
  }) async {
    final res = await http.put(
      Uri.parse(ApiConstants.profil),
      headers: _headers,
      body:    jsonEncode({'pseudo': pseudo, 'telephone': telephone}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Erreur mise à jour profil');
    }
  }

  /// PUT /profil/photo — upload photo de profil (multipart field: "photo")
  /// Retourne la nouvelle URL publique
  Future<String> updatePhoto(Uint8List imageBytes, String fileName) async {
    final uri     = Uri.parse(ApiConstants.profilPhoto);
    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $_token'
      ..files.add(http.MultipartFile.fromBytes(
        'photo',
        imageBytes,
        filename: fileName,
      ));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res      = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['photoUrl'] as String;
    }
    throw Exception('Erreur upload photo (${res.statusCode})');
  }

  /// PUT /profil/mot-de-passe
  Future<void> updatePassword({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    final res = await http.put(
      Uri.parse(ApiConstants.profilMotDePasse),
      headers: _headers,
      body: jsonEncode({
        'ancienMotDePasse':  ancienMotDePasse,
        'nouveauMotDePasse': nouveauMotDePasse,
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Erreur changement mot de passe');
    }
  }

  // ══════════════════════════════════════════════════════
  // PUBLICATIONS PUBLIQUES
  // ══════════════════════════════════════════════════════

  /// GET /publications — liste filtrée et paginée (public, sans token)
  static Future<Map<String, dynamic>> getPublications({
    String? categorie,
    String? ville,
    String? region,
    String? pays,
    String? planType,
    bool?   disponible,
    double? tarifMin,
    double? tarifMax,
    int     page   = 1,
    int     limite = 20,
  }) async {
    final params = <String, String>{
      'page':   '$page',
      'limite': '$limite',
      if (categorie  != null) 'categorie':  categorie,
      if (ville      != null) 'ville':      ville,
      if (region     != null) 'region':     region,
      if (pays       != null) 'pays':       pays,
      if (planType   != null) 'planType':   planType,
      if (disponible != null) 'disponible': '$disponible',
      if (tarifMin   != null) 'tarifMin':   '$tarifMin',
      if (tarifMax   != null) 'tarifMax':   '$tarifMax',
    };

    final uri = Uri.parse(ApiConstants.publications)
        .replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final pubs = (body['data'] as List)
          .map((j) => PublicationModel.fromJson(j))
          .toList();
      return {
        'publications': pubs,
        'total':  body['total'],
        'pages':  body['pages'],
        'page':   body['page'],
      };
    }
    throw Exception('Erreur liste publications (${res.statusCode})');
  }

  /// GET /publications/:id — détail public (incrémente les vues)
  static Future<PublicationModel> getPublicationDetail(String id) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.publications}/$id'),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return PublicationModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Publication introuvable');
  }

  /// POST /publications/:id/avis — laisser un avis (public, sans token)
  static Future<void> ajouterAvis(
      String pubId, int note, String message) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.publications}/$pubId/avis'),
      headers: {'Content-Type': 'application/json'},
      body:    jsonEncode({'note': note, 'message': message}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 201) {
      throw Exception('Erreur avis (${res.statusCode})');
    }
  }

  /// POST /publications/:id/signaler — signaler une publication
  static Future<void> signalerPublication(
      String pubId, String motif, String description) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.publications}/$pubId/signaler'),
      headers: {'Content-Type': 'application/json'},
      body:    jsonEncode({'motif': motif, 'description': description}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 201) {
      throw Exception('Erreur signalement (${res.statusCode})');
    }
  }

  // ══════════════════════════════════════════════════════
  // RÉFÉRENTIEL (public, sans token)
  // ══════════════════════════════════════════════════════

  static Future<List<PaysRef>> getPays() async {
    final res = await http.get(Uri.parse(ApiConstants.localisationPays))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => PaysRef.fromJson(j))
          .toList();
    }
    throw Exception('Erreur pays');
  }

  static Future<List<RegionRef>> getRegions(String paysNom) async {
    final uri = Uri.parse(ApiConstants.localisationRegions)
        .replace(queryParameters: {'paysNom': paysNom});
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => RegionRef.fromJson(j))
          .toList();
    }
    throw Exception('Erreur régions');
  }

  static Future<List<VilleRef>> getVilles(String regionNom) async {
    final uri = Uri.parse(ApiConstants.localisationVilles)
        .replace(queryParameters: {'regionNom': regionNom});
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => VilleRef.fromJson(j))
          .toList();
    }
    throw Exception('Erreur villes');
  }

  static Future<List<QuartierRef>> getQuartiers(String villeNom) async {
    final uri = Uri.parse(ApiConstants.localisationQuartiers)
        .replace(queryParameters: {'villeNom': villeNom});
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => QuartierRef.fromJson(j))
          .toList();
    }
    throw Exception('Erreur quartiers');
  }

  static Future<List<CategorieRef>> getCategories() async {
    final res = await http.get(Uri.parse(ApiConstants.categoriesFlat))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => CategorieRef.fromJson(j))
          .toList();
    }
    throw Exception('Erreur catégories');
  }

  // ══════════════════════════════════════════════════════
  // ABONNEMENTS (public)
  // ══════════════════════════════════════════════════════

  static Future<List<PlanAbonnement>> getPlans() async {
    final res = await http.get(Uri.parse(ApiConstants.abonnementPlans))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => PlanAbonnement.fromJson(j))
          .toList();
    }
    throw Exception('Erreur plans');
  }

  /// POST /abonnements/souscrire (authentifié)
  Future<void> souscrire(
      String planId, String methodePaiement) async {
    final res = await http.post(
      Uri.parse(ApiConstants.abonnementSouscrire),
      headers: _headers,
      body:    jsonEncode({'planId': planId, 'methodePaiement': methodePaiement}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Erreur souscription');
    }
  }
}