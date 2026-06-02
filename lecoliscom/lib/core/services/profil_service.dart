// lib/core/services/profil_service.dart
//
// Couche service pour toutes les routes /profil/* et /publications/*
// Alignée sur profilController.js, publicationController.js,
// abonnementController.js et referentielController.js

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';
import '../models/abonnement_model.dart';
import '../models/publication_model.dart';


// ─────────────────────────────────────────────────────────
// Modèle de Statistiques d'une Publication
// ─────────────────────────────────────────────────────────
class PublicationStats {
  final int vuesTotal;
  final int totalAvis;
  final double noteMoyenne;
  final Map<String, int> evolutionAvis;

  const PublicationStats({
    required this.vuesTotal,
    required this.totalAvis,
    required this.noteMoyenne,
    required this.evolutionAvis,
  });

  factory PublicationStats.fromJson(Map<String, dynamic> json) {
    // Sécurise la récupération de l'objet imbriqué du backend
    final evolution = json['evolutionAvis'] as Map<String, dynamic>? ?? {};
    
    return PublicationStats(
      // Supporte 'vuesTotal' tout en gérant l'ancienne clé avec faute de frappe 'vuesTotatles' par sécurité
      vuesTotal:   json['vuesTotal'] ?? json['vuesTotatles'] ?? 0,
      totalAvis:   json['totalAvis'] ?? 0,
      noteMoyenne: (json['noteMoyenne'] as num? ?? 0.0).toDouble(),
      evolutionAvis: {
        'jour':    (evolution['parJour']    as num? ?? 0).toInt(),
        'semaine': (evolution['parSemaine'] as num? ?? 0).toInt(),
        'mois':    (evolution['parMois']    as num? ?? 0).toInt(),
        'an':      (evolution['parAn']      as num? ?? 0).toInt(),
      },
    );
  }
}

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

  /// GET /profil/publications/:id — détail d'une publication (authentifié)
  Future<PublicationModel> getPublicationById(String id) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.profilPublications}/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return PublicationModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Publication introuvable (${res.statusCode})');
  }

  // À AJOUTER ICI : Récupération des statistiques depuis le backend
  /// GET /profil/publications/:id/stats — statistiques complètes et avis
  Future<PublicationStats> getPublicationStats(String id) async {
    final res = await http.get(
      Uri.parse(ApiConstants.profilPublicationStats(id)),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return PublicationStats.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Impossible de charger les statistiques (${res.statusCode})');
  }

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
        filename: 'image_$i.png',
        contentType: MediaType('image', 'png'),
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
  /// [imagesToDelete] : liste des IDs Prisma des images à supprimer (MinIO + BD).
  ///   - Toujours inclus dans le body, même vide, pour que le backend sache
  ///     qu'il n'y a rien à supprimer (évite un null check côté JS).
  Future<PublicationModel> modifierPublication(
    String pubId, {
    String?       titre,
    String?       description,
    bool?         estDisponible,
    String?       statut,
    double?       tarif,
    String?       quartierId,
    String?       villeNom,
    String?       regionNom,
    String?       paysNom,
    List<String>? categorieIds,
    List<String>  imagesToDelete = const [],  // ← optionnel, défaut liste vide
  }) async {
    final body = <String, dynamic>{
      if (titre         != null) 'titre':         titre,
      if (description   != null) 'description':   description,
      if (estDisponible != null) 'estDisponible':  estDisponible,
      if (statut        != null) 'statut':         statut,
      if (tarif         != null) 'tarif':          tarif,
      if (quartierId    != null) 'quartierId':     quartierId,
      if (villeNom      != null) 'villeNom':       villeNom,
      if (regionNom     != null) 'regionNom':      regionNom,
      if (paysNom       != null) 'paysNom':        paysNom,
      if (categorieIds  != null) 'categorieIds':   categorieIds,
      // Toujours envoyé — le backend lit imagesToDelete pour supprimer dans MinIO + BD
      'imagesToDelete': imagesToDelete,
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

  /// PUT /profil — modifier pseudo, téléphone et/ou email
  Future<void> updateProfil({
    String? pseudo,
    String? telephone,
    String? email,
  }) async {
    final body = <String, dynamic>{
      if (pseudo    != null) 'pseudo':    pseudo,
      if (telephone != null) 'telephone': telephone,
      if (email     != null) 'email':     email,
    };

    final res = await http.put(
      Uri.parse(ApiConstants.profil),
      headers: _headers,
      body:    jsonEncode(body),
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
        contentType: MediaType('image', 'png'),
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
  // ── Stats par publication ───────────────────────────────
  Future<PubStats> statsPublication(String pubId) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.profilPublications}/$pubId/stats'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return PubStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Erreur stats publication (${res.statusCode})');
  }

  // ── Avis d'une publication ───────────────────────────────
  Future<List<AvisPub>> avisPublication(String pubId) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.profilPublications}/$pubId/avis'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((j) => AvisPub.fromJson(j)).toList();
    }
    throw Exception('Erreur avis publication (${res.statusCode})');
  }

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

  Future<void> supprimerCompte() async {
  final response = await http
      .delete(
        Uri.parse('${ApiConstants.baseUrl}/profil/compte'),
        headers: _headers,
      )
      .timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw Exception('Impossible de supprimer le compte.');
  }
}
}

// ══════════════════════════════════════════════════════════
// EXTENSION — UPSERT LOCALISATION (méthodes statiques)
// ══════════════════════════════════════════════════════════
// Séparées en extension pour ne pas modifier la classe existante.
// Usage : ProfilServiceUpsert.upsertPays(token, nom: 'Sénégal')
extension ProfilServiceUpsert on ProfilService {

  // Helper interne : headers avec token
  static Map<String, String> _authHeaders(String token) => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $token',
  };

  /// POST /localisation/pays
  /// "Créer si absent, retourner si existant" (déduplication côté backend).
  /// [drapeau] est optionnel — le backend utilise '🌍' par défaut.
  static Future<PaysRef> upsertPays(
    String token, {
    required String nom,
    String drapeau = '🌍',
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.localisationPays),
      headers: _authHeaders(token),
      body:    jsonEncode({'nom': nom, 'drapeau': drapeau}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return PaysRef.fromJson(body['pays'] as Map<String, dynamic>);
    }
    final err = jsonDecode(res.body);
    throw Exception(err['message'] ?? 'Erreur upsert pays (${res.statusCode})');
  }

  /// POST /localisation/regions
  /// Le pays parent doit exister en BD (ou avoir été upsert juste avant).
  static Future<RegionRef> upsertRegion(
    String token, {
    required String nom,
    required String paysNom,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.localisationRegions),
      headers: _authHeaders(token),
      body:    jsonEncode({'nom': nom, 'paysNom': paysNom}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return RegionRef.fromJson(body['region'] as Map<String, dynamic>);
    }
    final err = jsonDecode(res.body);
    throw Exception(err['message'] ?? 'Erreur upsert région (${res.statusCode})');
  }

  /// POST /localisation/villes
  static Future<VilleRef> upsertVille(
    String token, {
    required String nom,
    required String regionNom,
    required String paysNom,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.localisationVilles),
      headers: _authHeaders(token),
      body:    jsonEncode({'nom': nom, 'regionNom': regionNom, 'paysNom': paysNom}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return VilleRef.fromJson(body['ville'] as Map<String, dynamic>);
    }
    final err = jsonDecode(res.body);
    throw Exception(err['message'] ?? 'Erreur upsert ville (${res.statusCode})');
  }

  /// POST /localisation/quartiers
  /// Toute la chaîne parent doit exister (ou avoir été upsert en cascade).
  static Future<QuartierRef> upsertQuartier(
    String token, {
    required String nom,
    required String villeNom,
    required String regionNom,
    required String paysNom,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.localisationQuartiers),
      headers: _authHeaders(token),
      body:    jsonEncode({
        'nom':       nom,
        'villeNom':  villeNom,
        'regionNom': regionNom,
        'paysNom':   paysNom,
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return QuartierRef.fromJson(body['quartier'] as Map<String, dynamic>);
    }
    final err = jsonDecode(res.body);
    throw Exception(err['message'] ?? 'Erreur upsert quartier (${res.statusCode})');
  }
}
// ═══════════════════════════════════════════════════════════
// MODÈLES STATS PAR PUBLICATION
// ═══════════════════════════════════════════════════════════

/// Un point de série temporelle : label + vues + avis
class PeriodePoint {
  final String label;   // ex: "Lun", "Jan", "2024"
  final int    vues;
  final int    avis;

  const PeriodePoint({
    required this.label,
    required this.vues,
    required this.avis,
  });

  factory PeriodePoint.fromJson(Map<String, dynamic> j) => PeriodePoint(
    label: j['label']?.toString() ?? '',
    vues:  (j['vues']  as num? ?? 0).toInt(),
    avis:  (j['avis']  as num? ?? 0).toInt(),
  );
}

/// Stats complètes d'une publication
class PubStats {
  final int               vuesTotal;
  final int               avisTotal;
  final double            noteMoyenne;
  final List<PeriodePoint> parJour;
  final List<PeriodePoint> parSemaine;
  final List<PeriodePoint> parMois;
  final List<PeriodePoint> parAn;

  const PubStats({
    required this.vuesTotal,
    required this.avisTotal,
    required this.noteMoyenne,
    required this.parJour,
    required this.parSemaine,
    required this.parMois,
    required this.parAn,
  });

  factory PubStats.fromJson(Map<String, dynamic> j) {
    List<PeriodePoint> _parse(dynamic raw) {
      if (raw == null) return [];
      return (raw as List).map((e) =>
          PeriodePoint.fromJson(e as Map<String, dynamic>)).toList();
    }

    return PubStats(
      vuesTotal:   (j['vuesTotal']   as num? ?? 0).toInt(),
      avisTotal:   (j['avisTotal']   as num? ?? 0).toInt(),
      noteMoyenne: (j['noteMoyenne'] as num? ?? 0).toDouble(),
      parJour:     _parse(j['parJour']),
      parSemaine:  _parse(j['parSemaine']),
      parMois:     _parse(j['parMois']),
      parAn:       _parse(j['parAn']),
    );
  }
}

/// Un avis sur une publication
class AvisPub {
  final String   id;
  final int      note;       // 1–5
  final String   message;
  final DateTime createdAt;

  const AvisPub({
    required this.id,
    required this.note,
    required this.message,
    required this.createdAt,
  });

  factory AvisPub.fromJson(Map<String, dynamic> j) => AvisPub(
    id:        j['id']?.toString() ?? '',
    note:      (j['note'] as num? ?? 0).toInt(),
    message:   j['message']?.toString() ?? '',
    createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );

  /// Label textuel de la note
  String get noteLabel {
    switch (note) {
      case 5: return 'Excellent';
      case 4: return 'Très bien';
      case 3: return 'Bien';
      case 2: return 'Passable';
      case 1: return 'Mauvais';
      default: return '';
    }
  }

  /// Date formatée lisible
  String get dateFormatee {
    final now  = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 60)  return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24)  return 'Il y a ${diff.inHours} h';
    if (diff.inDays    < 7)   return 'Il y a ${diff.inDays} j';
    if (diff.inDays    < 30)  return 'Il y a ${(diff.inDays / 7).round()} sem.';
    if (diff.inDays    < 365) return 'Il y a ${(diff.inDays / 30).round()} mois';
    return 'Il y a ${(diff.inDays / 365).round()} an(s)';
  }
}