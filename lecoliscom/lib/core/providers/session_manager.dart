// lib/core/models/escort_model.dart  (ou un fichier dédié session_manager.dart)

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';
import '../models/escort_model.dart';

// Dans escort_model.dart — remplace l'ancienne classe SessionManager

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final AuthService _authService = AuthService();

  EscortModel? _escort;
  String?      _accessToken;
  String?      _refreshToken;
  String?      _derniereErreur;
  bool         _chargement = false;

  EscortModel? get escort          => _escort;
  bool         get estConnecte     => _escort != null;
  String?      get accessToken     => _accessToken;
  String?      get derniereErreur  => _derniereErreur;
  bool         get chargement      => _chargement;

  // ── Login ────────────────────────────────────────────────
  Future<bool> connecter(String email, String motDePasse) async {
    _derniereErreur = null;
    try {
      final res = await _authService.login(
        email: email, motDePasse: motDePasse,
      );
      await _sauvegarderSession(res);
      return true;
    } on AuthException catch (e) {
      _derniereErreur = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _derniereErreur = 'Erreur réseau. Vérifiez votre connexion.';
      notifyListeners();
      return false;
    }
  }

  // ── Register ─────────────────────────────────────────────
  Future<bool> inscrire({
    required String pseudo,
    required String email,
    required String telephone,
    required String motDePasse,
  }) async {
    _derniereErreur = null;
    try {
      final res = await _authService.register(
        pseudo: pseudo, email: email,
        telephone: telephone, motDePasse: motDePasse,
      );
      await _sauvegarderSession(res);
      return true;
    } on AuthException catch (e) {
      _derniereErreur = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _derniereErreur = 'Erreur réseau. Vérifiez votre connexion.';
      notifyListeners();
      return false;
    }
  }

  // ── Déconnexion ──────────────────────────────────────────
  Future<void> deconnecter() async {
    if (_refreshToken != null) {
      await _authService.logout(_refreshToken!);
    }
    _escort       = null;
    _accessToken  = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    notifyListeners();
  }

  // ── Restaurer session au démarrage de l'app ──────────────
  // Appelé dans main.dart avant runApp()
  Future<void> restaurer() async {
    final prefs   = await SharedPreferences.getInstance();
    _accessToken  = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');

    if (_accessToken != null) {
      // Token présent → recharger le profil depuis l'API
      _chargement = true;
      notifyListeners();
      try {
        final escort = await _authService.chargerProfil(_accessToken!);
        _escort = escort;
      } catch (_) {
        // Token expiré ou invalide → on vide tout proprement
        _accessToken  = null;
        _refreshToken = null;
        await prefs.remove('accessToken');
        await prefs.remove('refreshToken');
      } finally {
        _chargement = false;
        notifyListeners();
      }
    }
  }

  // ── Privé ────────────────────────────────────────────────
  Future<void> _sauvegarderSession(AuthResponse res) async {
    _escort       = res.escort;
    _accessToken  = res.accessToken;
    _refreshToken = res.refreshToken;
    final prefs   = await SharedPreferences.getInstance();
    await prefs.setString('accessToken',  res.accessToken);
    await prefs.setString('refreshToken', res.refreshToken);
    notifyListeners();
  }
}