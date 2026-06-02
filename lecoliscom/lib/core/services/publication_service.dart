// lib/core/services/publication_service.dart
//
// Couvre :
//   GET  /publications          → lister()   public
//   GET  /publications/:id      → detail()   public

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/publication_model.dart';

// ─────────────────────────────────────────────────────────
// PARAMÈTRES DE FILTRE
// Tous optionnels — seuls les non-null sont envoyés au backend
// ─────────────────────────────────────────────────────────
class FiltrePublication {
  final String? categorie;   // nom ex: "Milf"
  final String? ville;       // nom ex: "Yaoundé"
  final String? region;      // nom ex: "Centre"
  final String? pays;        // nom ex: "Cameroun"
  final String? planType;    // "premium" | "standard" | "basique"
  final bool?   disponible;
  final double? tarifMin;
  final double? tarifMax;
  final int     page;
  final int     limite;

  const FiltrePublication({
    this.categorie,
    this.ville,
    this.region,
    this.pays,
    this.planType,
    this.disponible,
    this.tarifMin,
    this.tarifMax,
    this.page   = 1,
    this.limite = 20,
  });

  // Construit les query params — n'inclut que les valeurs non-null
  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'page':   page.toString(),
      'limite': limite.toString(),
    };
    if (categorie  != null) params['categorie']  = categorie!;
    if (ville      != null) params['ville']      = ville!;
    if (region     != null) params['region']     = region!;
    if (pays       != null) params['pays']       = pays!;
    if (planType   != null) params['planType']   = planType!;
    if (disponible != null) params['disponible'] = disponible.toString();
    if (tarifMin   != null) params['tarifMin']   = tarifMin.toString();
    if (tarifMax   != null) params['tarifMax']   = tarifMax.toString();
    return params;
  }
}

// ─────────────────────────────────────────────────────────
// RÉSULTAT PAGINÉ
// ─────────────────────────────────────────────────────────
class ResultatPublications {
  final List<PublicationModel> publications;
  final int   total;
  final int   page;
  final int   pages;   // nombre total de pages
  final bool  hasMore; // raccourci : page < pages

  const ResultatPublications({
    required this.publications,
    required this.total,
    required this.page,
    required this.pages,
  }) : hasMore = page < pages;
}

// ─────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────
class PublicationService {

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // ══════════════════════════════════════════════════════
  // GET /publications
  // Public — pas de token requis
  // Retourne la liste paginée avec filtres optionnels
  // ══════════════════════════════════════════════════════
  static Future<ResultatPublications> lister({
    FiltrePublication filtre = const FiltrePublication(),
  }) async {
    final uri = Uri.parse(ApiConstants.publications)
        .replace(queryParameters: filtre.toQueryParams());

    final res = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = (body['data'] as List?) ?? [];

      return ResultatPublications(
        publications: data
            .map((j) => PublicationModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        total: body['total'] ?? 0,
        page:  body['page']  ?? 1,
        pages: body['pages'] ?? 1,
      );
    }

    throw Exception(
      'Impossible de charger les publications (${res.statusCode}).',
    );
  }

  // ══════════════════════════════════════════════════════
  // GET /publications/:id
  // Public — pas de token requis
  // Incrémente les vues côté backend automatiquement
  // ══════════════════════════════════════════════════════
  static Future<PublicationModel> detail(String id) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.publications}/$id'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return PublicationModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }

    if (res.statusCode == 404) {
      throw Exception('Publication introuvable.');
    }

    throw Exception(
      'Impossible de charger la publication (${res.statusCode}).',
    );
  }
}