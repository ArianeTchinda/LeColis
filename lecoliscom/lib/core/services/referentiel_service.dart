// lib/core/services/referentiel_service.dart
// Service pour charger les données de référence depuis le backend

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../models/categorie_model.dart';

class ReferentielService {
  // Charge toutes les catégories avec leurs IDs depuis le backend
  static Future<Map<String, List<CategorieModel>>> getCategoriesGrouped() async {
    try {
      final url = '${ApiConstants.baseUrl}/categories';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> groupes = jsonDecode(response.body);
        final Map<String, List<CategorieModel>> result = {};

        for (var groupe in groupes) {
          final groupName = groupe['nom'] as String;
          final categories = (groupe['categories'] as List)
              .map((cat) => CategorieModel.fromJson(cat))
              .toList();
          result[groupName] = categories;
        }

        return result;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('[ReferentielService] getCategoriesGrouped error: $e');
      rethrow;
    }
  }

  // Charge une liste plate de toutes les catégories
  static Future<List<CategorieModel>> getCategoriesFlat() async {
    try {
      final url = '${ApiConstants.baseUrl}/categories/flat';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((cat) => CategorieModel.fromJson(cat))
            .toList();
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('[ReferentielService] getCategoriesFlat error: $e');
      rethrow;
    }
  }
}
