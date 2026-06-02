// lib/features/admin/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/models/escort_model.dart';
import '../../../core/models/abonnement_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/admin_service.dart';
import 'admin_analytics_screen.dart'; 

// ─────────────────────────────────────────────────────────
// SECTIONS DU DASHBOARD
// ─────────────────────────────────────────────────────────
enum _AdminSection { analytiques, comptes, signalements, notifications, abonnements }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _AdminSection _section = _AdminSection.analytiques;

  // Service Backend
  final AdminService _adminService = AdminService();
  bool _isLoading = true;

  // Stats du Dashboard
  int totalEscorts = 0;
  int escortsVerifies = 0;
  int escortsBloques = 0;
  double revenuTotal = 0.0;

  // Données principales
  List<CompteEscortAdmin> _comptes = [];
  List<SignalementAdmin> _signalements = [];
  List<PlanConfig> _plansConfig = [];
  final List<NotificationAdmin> _notifsSent = [];

  String _searchComptes = '';

  @override
  void initState() {
    super.initState();
    _recupererDonnees();
  }

  /// Charge toutes les données depuis le backend
  Future<void> _recupererDonnees() async {
    setState(() => _isLoading = true);

    try {
      // 1. Statistiques globales
      final stats = await _adminService.getDashboardStats();
      if (stats != null) {
        totalEscorts = stats['totalEscorts'] ?? 0;
        escortsVerifies = stats['escortsVerifies'] ?? 0;
        escortsBloques = stats['escortsBloques'] ?? 0;
        revenuTotal = (stats['revenuTotal'] ?? 0).toDouble();
      }

      // 2. Liste des comptes escorts
      final escortsData = await _adminService.getEscorts();
      _comptes = escortsData
          .map((json) => CompteEscortAdmin.fromJson(json))
          .toList();

      // 3. Signalements
      final signalementsData = await _adminService.getSignalements();
      _signalements = signalementsData
          .map((json) => SignalementAdmin.fromJson(json))
          .toList();

      // 4. Plans d'abonnement
      final plansData = await _adminService.getPlans();
      _plansConfig = plansData
          .map((json) => PlanConfig.fromJson(json))
          .toList();

    } catch (e) {
      print("Erreur lors du chargement des données admin : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion au serveur'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<CompteEscortAdmin> get _comptesFiltres => _comptes
      .where((c) =>
          c.escort.pseudo.toLowerCase().contains(_searchComptes.toLowerCase()) ||
          c.escort.email.toLowerCase().contains(_searchComptes.toLowerCase()))
      .toList();

  int get _nbSignalementsEnAttente =>
      _signalements.where((s) => s.statut == StatutSignalement.enAttente).length;

  // ── Navigation section ──────────────────────────────────
  Widget _buildNav(bool isWide) {
    final items = [
      (_AdminSection.analytiques,   Icons.auto_graph_rounded,        'Analytiques'),
      (_AdminSection.comptes,       Icons.people_alt_rounded,        'Comptes'),
      (_AdminSection.signalements,  Icons.flag_rounded,              'Signalements'),
      (_AdminSection.notifications, Icons.notifications_rounded,     'Notifications'),
      (_AdminSection.abonnements,   Icons.workspace_premium_rounded, 'Abonnements'),
    ];
 
    if (isWide) {
      return Container(
        width: 230,
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          border: Border(right: BorderSide(color: const Color(0xFF252535))),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Logo / titre ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF9B5FFF), Color(0xFFFF4D8F)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF9B5FFF), Color(0xFF00D4FF)])
                    .createShader(b),
                child: Text('LeColis',
                    style: GoogleFonts.dmSerifDisplay(
                        fontSize: 20, color: Colors.white)),
              ),
            ]),
          ),
          Container(height: 1, color: const Color(0xFF252535)),
          const SizedBox(height: 10),
 
          // ── Items ─────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: items.map((item) {
                final sel   = _section == item.$1;
                final badge = item.$1 == _AdminSection.signalements &&
                    _nbSignalementsEnAttente > 0
                    ? _nbSignalementsEnAttente
                    : null;
 
                return GestureDetector(
                  onTap: () => setState(() => _section = item.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: sel
                        ? LinearGradient(colors: [
                            const Color(0xFF9B5FFF).withOpacity(0.18),
                            const Color(0xFF00D4FF).withOpacity(0.05),
                          ])
                        : null,
                      borderRadius: BorderRadius.circular(12),
                      border: sel
                        ? Border.all(
                            color: const Color(0xFF9B5FFF).withOpacity(0.3))
                        : null,
                    ),
                    child: Row(children: [
                      Icon(item.$2,
                          size: 19,
                          color: sel
                              ? const Color(0xFF9B5FFF)
                              : const Color(0xFF555570)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.$3,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: sel
                                  ? const Color(0xFFF0F0FF)
                                  : const Color(0xFF9090B0)))),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFF4D4D),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('$badge',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
 
          // ── Déconnexion ───────────────────────────────────
          Container(height: 1, color: const Color(0xFF252535)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                AdminSession().deconnecter();
                Navigator.popUntil(context, (r) => r.isFirst);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4D).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFF4D4D).withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.logout_rounded,
                      color: Color(0xFFFF4D4D), size: 16),
                  const SizedBox(width: 10),
                  const Text('Déconnexion',
                      style: TextStyle(
                          color: Color(0xFFFF4D4D),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ),
        ]),
      );
    }
 
    // ── Bottom nav mobile ────────────────────────────────────
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        border: Border(top: BorderSide(color: const Color(0xFF252535))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: items.map((item) {
              final sel   = _section == item.$1;
              final badge = item.$1 == _AdminSection.signalements &&
                  _nbSignalementsEnAttente > 0
                  ? _nbSignalementsEnAttente
                  : null;
 
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _section = item.$1),
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(clipBehavior: Clip.none, children: [
                          Icon(item.$2,
                              size: 22,
                              color: sel
                                  ? const Color(0xFF9B5FFF)
                                  : const Color(0xFF555570)),
                          if (badge != null)
                            Positioned(
                              right: -6, top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                    color: Color(0xFFFF4D4D),
                                    shape: BoxShape.circle),
                                child: Text('$badge',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                        ]),
                        const SizedBox(height: 3),
                        Text(item.$3,
                            style: TextStyle(
                                fontSize: sel ? 10 : 9,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: sel
                                    ? const Color(0xFF9B5FFF)
                                    : const Color(0xFF555570))),
                        if (sel)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 18, height: 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF9B5FFF),
                                    Color(0xFF00D4FF)
                                  ]),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 44, height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF9B5FFF).withOpacity(0.8)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Chargement…',
              style: TextStyle(fontSize: 12, color: Color(0xFF555570))),
        ]),
      ),
    );
  }

    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: isWide
          ? Row(children: [
              _buildNav(true),
              Expanded(child: _buildContent()),
            ])
          : _buildContent(),
      bottomNavigationBar: isWide ? null : _buildNav(false),
    );
  }

  Widget _buildContent() {
     switch (_section) {
       case _AdminSection.comptes:        return _buildComptes();
       case _AdminSection.signalements:   return _buildSignalements();
       case _AdminSection.notifications:  return _buildNotifications();
       case _AdminSection.abonnements:    return _buildAbonnements();
       case _AdminSection.analytiques:                           // ← AJOUTER
         return AdminAnalyticsScreen(                           // ← AJOUTER
           adminService: _adminService,                        // ← AJOUTER
           comptes: _comptes,                                  // ← AJOUTER
         );                                                    // ← AJOUTER
     }
   }

    // ═══════════════════════════════════════════════════════
  // SECTION COMPTES
  // ═══════════════════════════════════════════════════════
  Widget _buildComptes() {
    final filtres = _comptesFiltres;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          titre: 'Comptes Escort',
          sous: '${_comptes.length} comptes enregistrés',
          gradient: const [Color(0xFF9B5FFF), Color(0xFF00D4FF)]
          
        ),
        // Recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: TextField(
            onChanged: (v) => setState(() => _searchComptes = v),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher un compte…',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 18, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.divider)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.divider)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.primaryPink, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: filtres.length,
            itemBuilder: (_, i) => _CompteCard(
              compte: filtres[i],
              onVoirDetail: () => _ouvrirDetailCompte(filtres[i]),
            ),
          ),
        ),
      ],
    );
  }

  void _ouvrirDetailCompte(CompteEscortAdmin compte) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailCompteSheet(
        compte:      compte,
        plansConfig: _plansConfig,          // ← liste des plans pour le cadeau
        onCadeau:    (planId) => _offrirCadeau(compte, planId),
        onSanction:  (type, motif, duree) =>
            _appliquerSanction(compte, type, motif, duree),
        onLeverSanction: () => _leverSanction(compte),
        onVerifier:      () => _basculerVerification(compte),
      ),
    );
  }

  Future<void> _appliquerSanction(
      CompteEscortAdmin compte, TypeSanction type, String motif, int? jours) async {
    
    // Conversion explicite vers les valeurs Prisma
    //   avertissement     → AVERTISSEMENT
    //   blocageTemporaire → BLOCAGE_TEMPORAIRE
    //   bannissement      → BANNISSEMENT
    String typeStr;
    switch (type) {
      case TypeSanction.avertissement:     typeStr = 'AVERTISSEMENT';     break;
      case TypeSanction.blocageTemporaire: typeStr = 'BLOCAGE_TEMPORAIRE'; break;
      case TypeSanction.bannissement:      typeStr = 'BANNISSEMENT';       break;
    }

    final success = await _adminService.sanctionnerEscort(
      compte.escort.id,
      typeStr,
      motif,
      dureeJours: jours,
    );

    if (success) {
      await _recupererDonnees();
      _snack('Sanction appliquée avec succès : ${type.label}');
    } else {
      _snack('Échec de l\'application de la sanction', isError: true);
    }
  }

  Future<void> _leverSanction(CompteEscortAdmin compte) async {
    final success = await _adminService.debloquerEscort(compte.escort.id);

    if (success) {
      await _recupererDonnees();
      _snack('Sanctions levées pour ${compte.escort.pseudo}');
    } else {
      _snack('Échec du déblocage du compte', isError: true);
    }
  }

    // ═══════════════════════════════════════════════════════
  // SECTION SIGNALEMENTS
  // ═══════════════════════════════════════════════════════
  Widget _buildSignalements() {
    final enAttente = _signalements
        .where((s) => s.statut == StatutSignalement.enAttente)
        .toList();
    final traites = _signalements
        .where((s) => s.statut != StatutSignalement.enAttente)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          titre: 'Signalements',
          sous: '$_nbSignalementsEnAttente en attente',
          gradient: const [Color(0xFFFF6B6B), Color(0xFFFF4D8F)]
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              if (enAttente.isNotEmpty) ...[
                _SubHeader('En attente (${enAttente.length})'),
                ...enAttente.map((s) => _SignalementCard(
                      sig: s,
                      onTraiter: () => _traiterSignalement(s, StatutSignalement.traite),
                      onIgnorer: () => _traiterSignalement(s, StatutSignalement.ignore),
                      onSanction: () {
                        final compte = _comptes.firstWhere(
                            (c) => c.escort.id == s.escortId,
                            orElse: () => _comptes.first);
                        _ouvrirDetailCompte(compte);
                      },
                    )),
              ],
              if (traites.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SubHeader('Traités / Ignorés (${traites.length})'),
                ...traites.map((s) => _SignalementCard(
                      sig: s,
                      // Bouton "Rouvrir" → remet EN_ATTENTE pour révision
                      onRouvrir: () => _traiterSignalement(
                          s, StatutSignalement.enAttente),
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Traiter un signalement via le backend
  /// Gère les 3 cas : traite | ignore | enAttente (rouvrir pour révision)
  Future<void> _traiterSignalement(
      SignalementAdmin sig, StatutSignalement statut) async {

    final success = await _adminService.traiterSignalement(sig.id, statut);

    if (success) {
      setState(() => sig.statut = statut);
      final msg = statut == StatutSignalement.traite
          ? 'Signalement marqué comme traité'
          : statut == StatutSignalement.ignore
              ? 'Signalement ignoré'
              : 'Signalement rouvert pour révision';
      _snack(msg);
    } else {
      _snack('Échec du traitement du signalement', isError: true);
    }
  }
    // ═══════════════════════════════════════════════════════
  // SECTION NOTIFICATIONS
  // ═══════════════════════════════════════════════════════
  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          titre: 'Notifications',
          sous: 'Envoyer des messages aux escortes',
          gradient: const [Color(0xFF9B5FFF), Color(0xFFFF4D8F)]
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              // Formulaire d'envoi
              _NotifForm(
                comptes: _comptes,
                onEnvoyer: (titre, message, typeNotif, ids) async {
                  // .name retourne minuscule (ex: "admin") → on force majuscules
                  // pour correspondre à l'enum Prisma (SYSTEME | ADMIN | ABONNEMENT | PUBLICATION)
                  final typeStr = typeNotif.name.toUpperCase();
                  final cible   = ids.isEmpty
                      ? 'TOUS'
                      : (ids.length == 1 ? 'INDIVIDUEL' : 'MULTIPLE');

                  final success = await _adminService.envoyerNotification(
                    titre:     titre,
                    message:   message,
                    type:      typeStr,
                    cible:     cible,
                    escortIds: ids.isEmpty ? null : ids,
                  );

                  if (success) {
                    setState(() {
                      _notifsSent.add(NotificationAdmin(
                        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
                        titre: titre,
                        message: message,
                        cible: ids.isEmpty
                            ? CibleNotification.tous
                            : ids.length == 1
                                ? CibleNotification.individuel
                                : CibleNotification.multiple,
                        escortIds: List<String>.from(ids), // copie sécurisée
                        dateEnvoi: DateTime.now(),
                        type: typeNotif,
                      ));
                    });
                    _snack('Notification envoyée avec succès !');
                  } else {
                    _snack('Échec de l\'envoi de la notification', isError: true);
                  }
                },
              ),

              const SizedBox(height: 24),
              _SubHeader('Historique d\'envoi'),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.history_rounded, size: 16),
                label: const Text('Voir l\'historique complet'),
                style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryPink,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () => setState(() => _section = _AdminSection.analytiques),
              ),
   // L'historique complet est dans l'onglet Analytiques → Notifs envoyées
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // SECTION ABONNEMENTS
  // ═══════════════════════════════════════════════════════
  Widget _buildAbonnements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          titre: 'Gestion des abonnements',
          sous: 'Tarifs, durées et publications',
          gradient: const [Color(0xFFFFB830), Color(0xFFFF6B6B)]
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              // En-tête avec compteur
              _SubHeader('Plans configurés (${_plansConfig.length})'),
              ..._plansConfig.map((plan) => _PlanConfigCard(
                    plan: plan,
                    onSave: (p) async {
                      final success = await _adminService.modifierPlan(p);
                      if (success && mounted) {
                        setState(() {
                          final i = _plansConfig.indexWhere((x) => x.id == p.id);
                          if (i != -1) _plansConfig[i] = p;
                        });
                        _snack('Plan "${p.nom}" mis à jour');
                      } else {
                        _snack('Échec de la mise à jour du plan', isError: true);
                      }
                    },
                    onSupprimer: plan.estBase
                        ? null
                        : () async {
                            final result = await _adminService.supprimerPlan(plan.id);
                            if (result['ok'] == true) {
                              setState(() => _plansConfig.removeWhere((x) => x.id == plan.id));
                              _snack('Plan "${plan.nom}" supprimé');
                            } else {
                              _snack(result['message'] ?? 'Impossible de supprimer ce plan',
                              isError: true);
                            }
                          },
                  )),

              // Bouton ajouter un plan custom
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _ouvrirDialogueNouveauPlan,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB68DFF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFB68DFF).withOpacity(0.30)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Color(0xFFB68DFF), size: 18),
                      SizedBox(width: 8),
                      Text('Ajouter un nouveau plan',
                          style: TextStyle(
                              color: Color(0xFFB68DFF),
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              _SubHeader('Abonnements actifs par compte'),
              ..._comptes.where((c) => c.abonnementActif != null).map(
                    (c) => _AbonnementClientCard(
                      compte: c,
                      plansConfig: _plansConfig,
                      onModifier: (deltaJours, nbPub) =>
                          _modifierAbonnementClient(c, deltaJours, nbPub),
                      onCadeau: (planId) => _offrirCadeau(c, planId),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  // [deltaJours] : +1 ou -1 (ajustement un par un)
  // [nbPub]       : nouveau quota de publications (null = pas de changement)
  Future<void> _modifierAbonnementClient(
      CompteEscortAdmin compte, int? deltaJours, int? nbPub) async {
    final ab = compte.abonnementActif;
    if (ab == null) return;

    final result = await _adminService.ajusterAbonnement(
      ab.id,
      deltaJours:        deltaJours,
      nbPublicationsAdm: nbPub,
    );

    if (result['ok'] == true) {
      setState(() {
        if (deltaJours != null) {
          ab.dateFin = ab.dateFin.add(Duration(days: deltaJours));
        }
        if (nbPub != null) ab.nbPublicationsAdm = nbPub.clamp(1, 99);
      });
      _snack('Abonnement de ${compte.escort.pseudo} mis à jour');
    } else {
      _snack(result['message'] ?? 'Échec de la mise à jour', isError: true);
    }
  }

  // ── Offrir un plan cadeau ─────────────────────────────────
  Future<void> _offrirCadeau(CompteEscortAdmin compte, String planId) async {
    final success = await _adminService.offrirCadeau(
      compte.escort.id,
      planId: planId,
    );
    if (success) {
      _snack('Plan cadeau offert à ${compte.escort.pseudo} 🎁');
      await _recupererDonnees();
    } else {
      _snack("Échec de l'offre cadeau", isError: true);
    }
  }
  // ── Dialogue création d'un nouveau plan ──────────────────
  void _ouvrirDialogueNouveauPlan() {
    showDialog(
      context: context,
      builder: (_) => _NouveauPlanDialog(
        onCreer: (plan) async {
  // Convertir Color → hex pour l'API
  final hex = '#${plan.accentColor.value.toRadixString(16).substring(2).toUpperCase()}';

  final id = await _adminService.creerPlan(
    nom:            plan.nom,
    description:    plan.description ?? '',
    prix:           plan.prix,
    nbPublications: plan.nbPublications,
    dureeJours:     plan.dureeJours,
    avantages:      plan.avantages,
    accentColor:    hex,
  );

  if (id != null) {
    _snack('Plan "${plan.nom}" créé avec succès !');
    // Recharger depuis le backend pour avoir les vrais IDs
    final plansData = await _adminService.getPlans();
    if (mounted) setState(() {
      _plansConfig = plansData
          .map((json) => PlanConfig.fromJson(json))
          .toList();
    });
  } else {
    _snack('Échec de la création du plan.', isError: true);
  }
},
      ),
    );
  }

  Future<void> _basculerVerification(CompteEscortAdmin compte) async {
    final nouvelEtat = !compte.escort.estVerifie;
    final success = await _adminService.verifierEscort(
      compte.escort.id,
      estVerifie: nouvelEtat,
    );
    if (success) {
      await _recupererDonnees();
      _snack(nouvelEtat
          ? '${compte.escort.pseudo} vérifié(e)'
          : 'Vérification retirée pour ${compte.escort.pseudo}');
    } else {
      _snack('Échec de la mise à jour de la vérification', isError: true);
    }
  }

    void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red[700] : AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
// WIDGETS INTERNES
// ═════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String       titre, sous;
  final List<Color>  gradient;
  final Widget?      action;
 
  const _SectionHeader({
    required this.titre,
    required this.sous,
    this.gradient = const [Color(0xFF9B5FFF), Color(0xFF00D4FF)],
    this.action,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111118),
        border: Border(
            bottom: BorderSide(color: Color(0xFF252535))),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) =>
                  LinearGradient(colors: gradient).createShader(b),
              child: Text(titre,
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 26,
                      color: Colors.white,
                      letterSpacing: -0.3)),
            ),
            const SizedBox(height: 3),
            Text(sous, style: const TextStyle(
                fontSize: 12, color: Color(0xFF555570))),
          ],
        )),
        if (action != null) action!,
      ]),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String text;
  const _SubHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, letterSpacing: 0.4)),
  );
}

// ─────────────────────────────────────────────────────────
// CARTE COMPTE
// ─────────────────────────────────────────────────────────
class _CompteCard extends StatelessWidget {
  final CompteEscortAdmin compte;
  final VoidCallback onVoirDetail;
  const _CompteCard({required this.compte, required this.onVoirDetail});

  @override
  Widget build(BuildContext context) {
    final e = compte.escort;
    final plan = compte.abonnementActif?.plan;
    final estBloqueOuBanni = compte.estBloque || compte.estBanni;

    return GestureDetector(
      onTap: onVoirDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estBloqueOuBanni
                ? const Color(0x55FF5252)
                : AppColors.divider,
          ),
        ),
        child: Row(children: [
          // Avatar
          Stack(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: plan != null
                      ? plan.accentColor.withOpacity(0.6)
                      : AppColors.divider,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: e.photoUrl != null
                    ? Image.network(e.photoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatar())
                    : _avatar(),
              ),
            ),
            if (estBloqueOuBanni)
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF5252), shape: BoxShape.circle),
                  child: const Icon(Icons.block_rounded,
                      color: Colors.white, size: 10),
                ),
              ),
          ]),
          const SizedBox(width: 12),

          // Infos
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(e.pseudo, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
                if (e.estVerifie) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded,
                      color: Color(0xFF5DB8FF), size: 13),
                ],
              ]),
              Text(e.email, style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Row(children: [
                if (plan != null)
                  _Badge(label: plan.nom, color: plan.accentColor),
                const SizedBox(width: 6),
                if (compte.signalements.any(
                    (s) => s.statut == StatutSignalement.enAttente))
                  _Badge(
                      label: '${compte.signalements.where(
                          (s) => s.statut == StatutSignalement.enAttente).length} signal.',
                      color: const Color(0xFFFF5252)),
                if (estBloqueOuBanni)
                  _Badge(
                      label: compte.estBanni ? 'Banni' : 'Bloqué',
                      color: const Color(0xFFFF5252)),
              ]),
            ],
          )),

          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ]),
      ),
    );
  }

  Widget _avatar() => Container(color: AppColors.surfaceElevated,
      child: const Icon(Icons.person, color: AppColors.textMuted));
}

// ─────────────────────────────────────────────────────────
// DETAIL COMPTE (bottom sheet)
// ─────────────────────────────────────────────────────────
class _DetailCompteSheet extends StatefulWidget {
  final CompteEscortAdmin              compte;
  final List<PlanConfig>               plansConfig;   // ← pour le cadeau
  final void Function(String)          onCadeau;      // (planId)
  final void Function(TypeSanction, String, int?) onSanction;
  final VoidCallback onLeverSanction;
  final VoidCallback onVerifier;

  const _DetailCompteSheet({
    required this.compte,
    required this.plansConfig,
    required this.onCadeau,
    required this.onSanction,
    required this.onLeverSanction,
    required this.onVerifier,
  });

  @override
  State<_DetailCompteSheet> createState() => _DetailCompteSheetState();
}

class _DetailCompteSheetState extends State<_DetailCompteSheet> {
  bool _showSanctionForm = false;
  TypeSanction _typeSanction = TypeSanction.avertissement;
  final _motifCtrl = TextEditingController();
  int _dureeJours  = 7;

  @override
  void dispose() { _motifCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c  = widget.compte;
    final e  = c.escort;
    final ab = c.abonnementActif;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize:     0.95,
      minChildSize:     0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider,
                borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),

          Expanded(child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // ── En-tête ──
              Row(children: [
                Container(width: 54, height: 54,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryPink, width: 2)),
                  child: ClipOval(
                    child: e.photoUrl != null
                        ? Image.network(e.photoUrl!, fit: BoxFit.cover)
                        : Container(color: AppColors.surfaceElevated,
                            child: const Icon(Icons.person, color: AppColors.textMuted)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(e.pseudo, style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                      if (e.estVerifie) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF5DB8FF), size: 16),
                      ],
                    ]),
                    Text(e.email,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(e.telephone,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                )),
              ]),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ── Abonnement actif ──
              _SheetSection(titre: 'Abonnement actif'),
              if (ab != null) ...[
                _InfoRow2(label: 'Plan', value: ab.plan.nom),
                _InfoRow2(label: 'Début',
                    value: DateFormat('dd/MM/yyyy').format(ab.dateDebut)),
                _InfoRow2(label: 'Expiration',
                    value: DateFormat('dd/MM/yyyy').format(ab.dateFin)),
                _InfoRow2(label: 'Statut', value: ab.estActif ? 'Actif' : 'Expiré'),
                _InfoRow2(label: 'Publications max',
                    value: '${ab.plan.nbPublications}'),
              ] else
                const Text('Aucun abonnement actif',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),

              // ── Offrir un plan cadeau (accessible même sans abonnement) ──
              const SizedBox(height: 16),
              _SheetSection(titre: 'Offrir un plan cadeau 🎁'),
              const Text(
                'Activez un plan pour ce compte sans paiement.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              ...widget.plansConfig.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text('Offrir le plan ${plan.nom} ?',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 16)),
                        content: Text(
                          'Cela activera "${plan.nom}" (${plan.dureeJours} jours) '
                          'pour ${widget.compte.escort.pseudo} sans paiement.',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler',
                                style: TextStyle(color: AppColors.textMuted)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onCadeau(plan.id);
                            },
                            child: Text('Offrir',
                                style: TextStyle(
                                    color: plan.accentColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: plan.accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: plan.accentColor.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(plan.icone, color: plan.accentColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(plan.nom,
                          style: TextStyle(
                              color: plan.accentColor,
                              fontWeight: FontWeight.w600, fontSize: 13))),
                      Text('${plan.dureeJours} jours',
                          style: TextStyle(
                              color: plan.accentColor.withOpacity(0.7),
                              fontSize: 11)),
                    ]),
                  ),
                ),
              )),

              const SizedBox(height: 20),

              // ── Statistiques ──
              _SheetSection(titre: 'Statistiques'),
              _InfoRow2(label: 'Publications', value: '${c.nbPublications}'),
              _InfoRow2(label: 'Vues totales',  value: '${c.nbVues}'),
              _InfoRow2(label: 'Transactions',   value: '${c.transactions.length}'),
              _InfoRow2(label: 'Signalements',   value: '${c.signalements.length}'),

              const SizedBox(height: 20),

              // ── Transactions ──
              if (c.transactions.isNotEmpty) ...[
                _SheetSection(titre: 'Transactions'),
                ...c.transactions.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan ${t.planNom}',
                            style: const TextStyle(fontWeight: FontWeight.w600,
                                fontSize: 13, color: AppColors.textPrimary)),
                        Text(DateFormat('dd/MM/yyyy').format(t.date),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                    Text('${t.montant.toInt()} FCFA',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13,
                            color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: t.statut == TransactionStatus.succes
                            ? const Color(0x2225D366)
                            : const Color(0x22FF5252),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.statut == TransactionStatus.succes ? 'Réussi' : 'Échoué',
                        style: TextStyle(
                          color: t.statut == TransactionStatus.succes
                              ? const Color(0xFF25D366)
                              : const Color(0xFFFF5252),
                          fontSize: 10, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
                )),
                const SizedBox(height: 12),
              ],

              // ── Sanctions actives ──
              if (c.sanctions.where((s) => s.active).isNotEmpty) ...[
                _SheetSection(titre: 'Sanctions actives',
                    color: const Color(0xFFFF5252)),
                ...c.sanctions.where((s) => s.active).map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: s.type.couleur.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: s.type.couleur.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(s.type.icone, color: s.type.couleur, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.type.label, style: TextStyle(
                            color: s.type.couleur, fontWeight: FontWeight.w600,
                            fontSize: 13)),
                        Text(s.motif,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        if (s.dateFin != null)
                          Text('Jusqu\'au ${DateFormat('dd/MM/yyyy').format(s.dateFin!)}',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                      ],
                    )),
                  ]),
                )),
              ],

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ── Actions sanctions ──
              _SheetSection(titre: 'Actions'),

              // Vérifier / dé-vérifier le compte
              _ActionBtn(
                label: e.estVerifie ? 'Retirer la vérification' : 'Vérifier le compte',
                icon:  e.estVerifie
                    ? Icons.remove_circle_outline_rounded
                    : Icons.verified_rounded,
                color: const Color(0xFF5DB8FF),
                onTap: widget.onVerifier,
              ),
              const SizedBox(height: 8),

              if (c.estBloque || c.estBanni)
                _ActionBtn(
                  label: 'Lever la sanction',
                  icon:  Icons.lock_open_rounded,
                  color: const Color(0xFF25D366),
                  onTap: widget.onLeverSanction,
                )
              else
                _ActionBtn(
                  label: 'Appliquer une sanction',
                  icon:  Icons.gavel_rounded,
                  color: const Color(0xFFFF5252),
                  onTap: () => setState(() => _showSanctionForm = !_showSanctionForm),
                ),

              // Formulaire sanction
              if (_showSanctionForm) ...[
                const SizedBox(height: 16),
                // Type
                Wrap(spacing: 8, runSpacing: 8,
                  children: TypeSanction.values.map((t) => GestureDetector(
                    onTap: () => setState(() => _typeSanction = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _typeSanction == t
                            ? t.couleur.withOpacity(0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _typeSanction == t
                              ? t.couleur.withOpacity(0.5)
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(t.icone, size: 13,
                            color: _typeSanction == t ? t.couleur : AppColors.textMuted),
                        const SizedBox(width: 5),
                        Text(t.label, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: _typeSanction == t ? t.couleur : AppColors.textMuted)),
                      ]),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                // Durée (blocage temporaire)
                if (_typeSanction == TypeSanction.blocageTemporaire) ...[
                  Text('Durée : $_dureeJours jours',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Slider(
                    value: _dureeJours.toDouble(), min: 1, max: 90,
                    activeColor: AppColors.primaryPink,
                    inactiveColor: AppColors.divider,
                    onChanged: (v) => setState(() => _dureeJours = v.toInt()),
                  ),
                  const SizedBox(height: 8),
                ],
                // Motif
                TextField(
                  controller: _motifCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Motif de la sanction…',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true, fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primaryPink, width: 1.5)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionBtn(
                  label: 'Confirmer la sanction',
                  icon:  Icons.check_rounded,
                  color: _typeSanction.couleur,
                  onTap: () {
                    if (_motifCtrl.text.trim().isEmpty) return;
                    widget.onSanction(
                      _typeSanction,
                      _motifCtrl.text.trim(),
                      _typeSanction == TypeSanction.blocageTemporaire
                          ? _dureeJours : null,
                    );
                    // Fermer le formulaire et nettoyer après soumission
                    setState(() {
                      _showSanctionForm = false;
                      _motifCtrl.clear();
                      _typeSanction = TypeSanction.avertissement;
                      _dureeJours   = 7;
                    });
                  },
                ),
              ],

              const SizedBox(height: 40),
            ],
          )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CARTE SIGNALEMENT
// Affiche les actions selon le statut :
//   EN_ATTENTE → Traité | Ignorer | Sanctionner
//   TRAITE / IGNORE → bouton "Rouvrir" pour re-examiner
// ─────────────────────────────────────────────────────────
class _SignalementCard extends StatelessWidget {
  final SignalementAdmin sig;
  final VoidCallback? onTraiter;
  final VoidCallback? onIgnorer;
  final VoidCallback? onSanction;
  final VoidCallback? onRouvrir;   // ← nouveau : re-passer EN_ATTENTE

  const _SignalementCard({
    required this.sig,
    this.onTraiter,
    this.onIgnorer,
    this.onSanction,
    this.onRouvrir,
  });

  @override
  Widget build(BuildContext context) {
    final estEnAttente = sig.statut == StatutSignalement.enAttente;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sig.statut.couleur.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(sig.statut.label, style: TextStyle(
                color: sig.statut.couleur,
                fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(sig.escortPseudo,
              style: const TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 14, color: AppColors.textPrimary))),
          Text(DateFormat('dd/MM HH:mm').format(sig.date),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 8),
        _Badge2('Motif', sig.motif, const Color(0xFFFFB800)),
        if (sig.titrePublication != null) ...[
          const SizedBox(height: 4),
          _Badge2('Publication', sig.titrePublication!, const Color(0xFF5DB8FF)),
        ],
        if (sig.description != null) ...[
          const SizedBox(height: 4),
          Text(sig.description!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 12),
        if (estEnAttente) ...[
          // Actions principales
          Row(children: [
            Expanded(child: _SmallBtn('Traité',
                const Color(0xFF25D366), onTraiter ?? () {})),
            const SizedBox(width: 8),
            Expanded(child: _SmallBtn('Ignorer',
                AppColors.textMuted, onIgnorer ?? () {})),
            const SizedBox(width: 8),
            Expanded(child: _SmallBtn('Sanctionner',
                const Color(0xFFFF5252), onSanction ?? () {})),
          ]),
        ] else ...[
          // Signalement déjà traité → bouton rouvrir
          _SmallBtn('Rouvrir pour révision',
              const Color(0xFFFFB800), onRouvrir ?? () {}),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// FORMULAIRE NOTIFICATION
// ─────────────────────────────────────────────────────────
class _NotifForm extends StatefulWidget {
  final List<CompteEscortAdmin> comptes;
  final void Function(String, String, TypeNotification, List<String>) onEnvoyer;
  const _NotifForm({required this.comptes, required this.onEnvoyer});

  @override
  State<_NotifForm> createState() => _NotifFormState();
}

class _NotifFormState extends State<_NotifForm> {
  final _titreCtrl   = TextEditingController();
  final _msgCtrl     = TextEditingController();
  TypeNotification   _type  = TypeNotification.admin;
  bool               _tous  = true;
  List<String>       _selIds = [];

  @override
  void dispose() {
    _titreCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Nouvelle notification',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 14),

        // Type
        Wrap(spacing: 8, runSpacing: 8,
          children: TypeNotification.values.map((t) => GestureDetector(
            onTap: () => setState(() => _type = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: _type == t
                    ? t.couleur.withOpacity(0.15)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _type == t
                      ? t.couleur.withOpacity(0.5)
                      : AppColors.divider,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(t.icone, size: 12,
                    color: _type == t ? t.couleur : AppColors.textMuted),
                const SizedBox(width: 5),
                Text(t.label, style: TextStyle(
                    fontSize: 11,
                    color: _type == t ? t.couleur : AppColors.textMuted,
                    fontWeight: FontWeight.w500)),
              ]),
            ),
          )).toList(),
        ),

        const SizedBox(height: 12),

        // Titre
        _Field(controller: _titreCtrl, hint: 'Titre de la notification'),
        const SizedBox(height: 10),

        // Message
        TextField(
          controller: _msgCtrl,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: _inputDeco('Message…'),
        ),

        const SizedBox(height: 14),

        // Cible
        Row(children: [
          const Text('Destinataires :',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _tous = true),
            child: _ToggleBtn('Tous', _tous),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _tous = false),
            child: _ToggleBtn('Sélection', !_tous),
          ),
        ]),

        if (!_tous) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: ListView.builder(
              itemCount: widget.comptes.length,
              itemBuilder: (_, i) {
                final c = widget.comptes[i];
                final sel = _selIds.contains(c.escort.id);
                return CheckboxListTile(
                  value: sel,
                  dense: true,
                  activeColor: AppColors.primaryPink,
                  title: Text(c.escort.pseudo,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary)),
                  subtitle: Text(c.escort.email,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  onChanged: (_) => setState(() {
                    if (sel) _selIds.remove(c.escort.id);
                    else _selIds.add(c.escort.id);
                  }),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () {
              if (_titreCtrl.text.trim().isEmpty ||
                  _msgCtrl.text.trim().isEmpty) return;
              widget.onEnvoyer(
                _titreCtrl.text.trim(),
                _msgCtrl.text.trim(),
                _type,
                _tous ? [] : _selIds,
              );
              _titreCtrl.clear();
              _msgCtrl.clear();
              setState(() { _selIds = []; _tous = true; });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFFF5DA8), Color(0xFFB68DFF)
                ]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.25),
                    blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: const Text('Envoyer la notification',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _Field({required TextEditingController controller, required String hint}) =>
      TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: _inputDeco(hint),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
    filled: true, fillColor: AppColors.surfaceElevated,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.5)),
    contentPadding: const EdgeInsets.all(12),
  );
}

// ─────────────────────────────────────────────────────────
// CARTE NOTIFICATION ENVOYÉE
// ─────────────────────────────────────────────────────────
class _NotifSentCard extends StatelessWidget {
  final NotificationAdmin notif;
  const _NotifSentCard({required this.notif});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: notif.type.couleur.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(notif.type.icone, color: notif.type.couleur, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(notif.titre, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
        Text(notif.cible == CibleNotification.tous
            ? 'Envoyé à tous'
            : 'Envoyé à ${notif.escortIds.length} compte(s)',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ])),
      Text(DateFormat('dd/MM HH:mm').format(notif.dateEnvoi),
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────
// CARTE CONFIG PLAN
// ─────────────────────────────────────────────────────────
class _PlanConfigCard extends StatefulWidget {
  final PlanConfig    plan;
  final void Function(PlanConfig) onSave;
  final VoidCallback? onSupprimer; // null pour les 3 plans de base
  const _PlanConfigCard({required this.plan, required this.onSave, this.onSupprimer});

  @override
  State<_PlanConfigCard> createState() => _PlanConfigCardState();
}

class _PlanConfigCardState extends State<_PlanConfigCard> {
  bool _expanded = false;
  late double      _prix;
  late int         _nbPub;
  late int         _duree;
  late List<String> _avantages;
  late Color       _couleur;       // ← AJOUT
  final _avantageCtrl = TextEditingController();
  final _hexCtrl      = TextEditingController(); // ← AJOUT

  // Palette de couleurs prédéfinies
  static const List<Color> _palette = [
    Color(0xFFFF5DA8), Color(0xFFFFB800), Color(0xFF8A8A9A),
    Color(0xFFB68DFF), Color(0xFF5DB8FF), Color(0xFF25D366),
    Color(0xFFFF6600), Color(0xFFFF5252), Color(0xFF00BCD4),
    Color(0xFF9C27B0), Color(0xFF3F51B5), Color(0xFF009688),
  ];

  @override
  void initState() {
    super.initState();
    _prix      = widget.plan.prix;
    _nbPub     = widget.plan.nbPublications;
    _duree     = widget.plan.dureeJours;
    _avantages = List.from(widget.plan.avantages);
    _couleur   = widget.plan.accentColor; // ← AJOUT
    _hexCtrl.text = _colorToHex(_couleur); // ← AJOUT
  }

  @override
  void dispose() {
    _avantageCtrl.dispose();
    _hexCtrl.dispose(); // ← AJOUT
    super.dispose();
  }

  // Convertit Color → hex sans le #
  String _colorToHex(Color c) =>
      c.value.toRadixString(16).substring(2).toUpperCase();

  // Tente de parser un hex saisi manuellement
  void _applyHex(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      try {
        final parsed = Color(int.parse('FF$clean', radix: 16));
        setState(() => _couleur = parsed);
      } catch (_) {}
    }
  }

  Color get _color => _couleur; // ← utilise la couleur locale

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _expanded ? _color.withOpacity(0.4) : AppColors.divider,
        ),
      ),
      child: Column(children: [
        // En-tête
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.workspace_premium_rounded, color: _color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.plan.nom, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
                Text(
                  widget.plan.estBasique
                      ? 'Gratuit — ${_duree}j — $_nbPub pub.'
                      : '${_prix.toInt()} FCFA — ${_duree}j — $_nbPub pub.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ])),
              Icon(
                _expanded ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
            ]),
          ),
        ),

        // Formulaire éditeur
        if (_expanded) Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Prix — masqué pour Basique
            if (!widget.plan.estBasique) ...[
              _SliderWithInput(
                label:    'Prix (FCFA)',
                color:    _color,
                value:    _prix.toInt(),
                minVal:   100,
                maxVal:   10000000,
                sliderMax: 500000,
                suffixe:  'FCFA',
                isInt:    false,
                onChanged: (v) => setState(() => _prix = v.toDouble()),
              ),
            ] else
              const Text('Prix : Gratuit (non modifiable)',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),

            const SizedBox(height: 8),

            // Durée
            _SliderWithInput(
              label:    'Durée (jours)',
              color:    _color,
              value:    _duree,
              minVal:   1,
              maxVal:   3650,
              sliderMax: 365,
              suffixe:  'j',
              isInt:    true,
              onChanged: (v) => setState(() => _duree = v.toInt()),
            ),

            const SizedBox(height: 8),

            // Nb publications
            _SliderWithInput(
              label:    'Publications max',
              color:    _color,
              value:    _nbPub,
              minVal:   1,
              maxVal:   9999,
              sliderMax: 100,
              suffixe:  'pub.',
              isInt:    true,
              onChanged: (v) => setState(() => _nbPub = v.toInt()),
            ),

            const SizedBox(height: 16),

            // ── COULEUR DU PLAN ──
            Row(children: [
              const Text('Couleur du plan',
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const Spacer(),
              // Aperçu de la couleur sélectionnée
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: _couleur,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  boxShadow: [BoxShadow(
                    color: _couleur.withOpacity(0.4),
                    blurRadius: 8,
                  )],
                ),
              ),
            ]),
            const SizedBox(height: 10),

            // Grille de couleurs
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _palette.map((c) {
                final selected = _couleur.value == c.value;
                return GestureDetector(
                  onTap: () => setState(() {
                    _couleur = c;
                    _hexCtrl.text = _colorToHex(c);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected ? [BoxShadow(
                        color: c.withOpacity(0.55),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )] : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Champ hex manuel
            Row(children: [
              Container(
                width: 20, height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _couleur,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _hexCtrl,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'Code hex (ex: FF5DA8)',
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                    prefixText: '#  ',
                    prefixStyle: TextStyle(
                        color: _couleur,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _couleur, width: 1.5)),
                  ),
                  onChanged: _applyHex,
                  onSubmitted: _applyHex,
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // ── AVANTAGES ──
            Row(children: [
              Text('Avantages',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const Spacer(),
              Text('${_avantages.length} élément(s)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 8),

            // Liste des avantages existants
            ..._avantages.asMap().entries.map((entry) {
              final i   = entry.key;
              final txt = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: _color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(txt,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary))),
                  GestureDetector(
                    onTap: () => setState(() => _avantages.removeAt(i)),
                    child: const Icon(Icons.close_rounded,
                        size: 15, color: AppColors.textMuted),
                  ),
                ]),
              );
            }),

            // Champ ajout avantage
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _avantageCtrl,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Ajouter un avantage…',
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _color, width: 1.5)),
                  ),
                  onSubmitted: (v) {
                    final val = v.trim();
                    if (val.isNotEmpty) {
                      setState(() {
                        _avantages.add(val);
                        _avantageCtrl.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final val = _avantageCtrl.text.trim();
                  if (val.isNotEmpty) {
                    setState(() {
                      _avantages.add(val);
                      _avantageCtrl.clear();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _color.withOpacity(0.4)),
                  ),
                  child: Icon(Icons.add_rounded, color: _color, size: 18),
                ),
              ),
            ]),

            const SizedBox(height: 14),

            // Sauvegarder + Supprimer (si plan custom)
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.plan.prix           = _prix;
                    widget.plan.nbPublications = _nbPub;
                    widget.plan.dureeJours     = _duree;
                    widget.plan.avantages      = List.from(_avantages);
                    widget.plan.accentColor    = _couleur; // ← AJOUT
                    widget.onSave(widget.plan);
                    setState(() => _expanded = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _color.withOpacity(0.4)),
                    ),
                    child: Text('Sauvegarder',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _color,
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ),
              if (widget.onSupprimer != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: widget.onSupprimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x22FF5252),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x55FF5252)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFFF5252), size: 18),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ABONNEMENT CLIENT (vue admin)
// ─────────────────────────────────────────────────────────
class _AbonnementClientCard extends StatefulWidget {
  final CompteEscortAdmin              compte;
  final List<PlanConfig>               plansConfig;
  final void Function(int?, int?)      onModifier; // (deltaJours, nbPub)
  final void Function(String)          onCadeau;   // (planId)

  const _AbonnementClientCard({
    required this.compte,
    required this.plansConfig,
    required this.onModifier,
    required this.onCadeau,
  });

  @override
  State<_AbonnementClientCard> createState() => _AbonnementClientCardState();
}

class _AbonnementClientCardState extends State<_AbonnementClientCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ab  = widget.compte.abonnementActif!;
    final e   = widget.compte.escort;

    // Trouver le PlanConfig correspondant — fallback sur le plan de l'abonnement
    // si _plansConfig est vide ou pas encore chargé (évite Bad state: No element)
    final planActuel = widget.plansConfig.isNotEmpty
        ? widget.plansConfig.firstWhere(
            (p) => p.nom == ab.plan.nom,
            orElse: () => widget.plansConfig.first,
          )
        : null;

    final joursRestants = ab.dateFin.difference(DateTime.now()).inDays;
    final color = ab.plan.accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5), width: 1.5)),
                child: ClipOval(child: e.photoUrl != null
                    ? Image.network(e.photoUrl!, fit: BoxFit.cover)
                    : Container(color: AppColors.surfaceElevated,
                        child: const Icon(Icons.person,
                            color: AppColors.textMuted, size: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.pseudo, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
                Text('${ab.plan.nom} · $joursRestants j restants',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ])),
              _Badge(label: ab.plan.nom, color: color),
              const SizedBox(width: 8),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded
                             : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted, size: 18),
            ]),
          ),
        ),

        if (_expanded) Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            _InfoRow2(label: 'Email',       value: e.email),
            _InfoRow2(label: 'Début',
                value: DateFormat('dd/MM/yyyy').format(ab.dateDebut)),
            _InfoRow2(label: 'Expiration',
                value: DateFormat('dd/MM/yyyy').format(ab.dateFin)),
            _InfoRow2(label: 'Publications',
                value: '${widget.compte.nbPublications} / ${ab.nbPublicationsAdm}'),
            const SizedBox(height: 12),

            // Prolonger / Réduire validité (un jour à la fois — min 1 jour restant)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Ajuster l\'expiration',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Text('${ab.dateFin.difference(DateTime.now()).inDays} j restants',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _SmallBtn('-1 jour', const Color(0xFFFF5252), () {
                widget.onModifier(-1, null);  // backend vérifie le minimum
              })),
              const SizedBox(width: 8),
              Expanded(child: _SmallBtn('+1 jour', const Color(0xFF25D366), () {
                widget.onModifier(1, null);
              })),
            ]),

            // Ajuster publications (basique uniquement ou tout plan)
            const SizedBox(height: 10),
            Text('Ajuster publications',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _SmallBtn('-1 pub', const Color(0xFFFF5252), () {
                if (ab.nbPublicationsAdm > 1)
                  widget.onModifier(null, ab.nbPublicationsAdm - 1);
              })),
              const SizedBox(width: 8),
              Expanded(child: _SmallBtn('+1 pub', const Color(0xFF25D366), () {
                widget.onModifier(null, ab.nbPublicationsAdm + 1);
              })),
            ]),

            // ── Offrir un plan cadeau ─────────────────────
            const SizedBox(height: 16),
            Divider(color: AppColors.divider.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('Offrir un plan cadeau 🎁',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            // Liste déroulante des plans disponibles
            ...widget.plansConfig.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () {
                  // Confirmation avant d'offrir
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text('Offrir le plan ${plan.nom} ?',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                      content: Text(
                        'Cela activera le plan "${plan.nom}" '
                        '(${plan.dureeJours} jours) pour '
                        '${widget.compte.escort.pseudo} sans paiement.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onCadeau(plan.id);
                          },
                          child: Text('Offrir',
                              style: TextStyle(color: plan.accentColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: plan.accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: plan.accentColor.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(plan.icone, color: plan.accentColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(plan.nom,
                        style: TextStyle(color: plan.accentColor,
                            fontWeight: FontWeight.w600, fontSize: 13))),
                    Text('${plan.dureeJours}j',
                        style: TextStyle(color: plan.accentColor.withOpacity(0.7),
                            fontSize: 11)),
                  ]),
                ),
              ),
            )),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PETITS WIDGETS RÉUTILISABLES
// ─────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(
        color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _Badge2 extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _Badge2(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Text('$label : ', style: const TextStyle(
        fontSize: 12, color: AppColors.textMuted)),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(value, style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ),
  ]);
}

class _InfoRow2 extends StatelessWidget {
  final String label, value;
  const _InfoRow2({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 110, child: Text('$label :',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary))),
    ]),
  );
}

class _SheetSection extends StatelessWidget {
  final String titre;
  final Color? color;
  const _SheetSection({required this.titre, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(titre, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary)),
  );
}

class _ActionBtn extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    ),
  );
}

class _SmallBtn extends StatelessWidget {
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _SmallBtn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: color,
              fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool   active;
  const _ToggleBtn(this.label, this.active);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: active ? AppColors.primaryPink.withOpacity(0.15) : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: active ? AppColors.primaryPink.withOpacity(0.4) : AppColors.divider,
      ),
    ),
    child: Text(label, style: TextStyle(
        fontSize: 12,
        color: active ? AppColors.primaryPink : AppColors.textSecondary,
        fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
  );
}

// ignore: unused_element
class _SliderRow extends StatelessWidget {
  final String label, value;
  final Widget child;
  const _SliderRow({required this.label, required this.value, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text(label, style: const TextStyle(
            fontSize: 12, color: AppColors.textMuted)),
        const Spacer(),
        Text(value, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary)),
      ]),
      child,
    ],
  );
}

// ─────────────────────────────────────────────────────────
// TRANSACTION STATUS BADGE
// ─────────────────────────────────────────────────────────
// ignore: unused_element
class _TransactionStatusBadge extends StatelessWidget {
  final TransactionStatus statut;

  const _TransactionStatusBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final color = statut.couleur;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statut.icone, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            statut.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// DIALOGUE NOUVEAU PLAN (plan custom ajouté par l'admin)
// ─────────────────────────────────────────────────────────
class _NouveauPlanDialog extends StatefulWidget {
  final void Function(PlanConfig) onCreer;
  const _NouveauPlanDialog({required this.onCreer});

  @override
  State<_NouveauPlanDialog> createState() => _NouveauPlanDialogState();
}

class _NouveauPlanDialogState extends State<_NouveauPlanDialog> {
  final _nomCtrl      = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _avantageCtrl = TextEditingController();
  double       _prix     = 10000;
  int          _duree    = 30;
  int          _nbPub    = 5;
  List<String> _avantages = [];

  // Couleurs disponibles pour un plan custom
  static const List<Color> _couleurs = [
    Color(0xFF00C2FF), Color(0xFF7B61FF), Color(0xFF00D084),
    Color(0xFFFF6B35), Color(0xFFFF3CAC), Color(0xFFFFD600),
  ];
  int _colorIdx = 0;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _avantageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _couleurs[_colorIdx];

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB68DFF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_box_rounded,
                    color: Color(0xFFB68DFF), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Nouveau plan',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
            ]),

            const SizedBox(height: 20),

            // Nom
            _DialogLabel('Nom du plan'),
            const SizedBox(height: 6),
            _DialogField(controller: _nomCtrl, hint: 'ex: Premium Plus'),

            const SizedBox(height: 12),

            // Description
            _DialogLabel('Description courte'),
            const SizedBox(height: 6),
            _DialogField(controller: _descCtrl, hint: 'ex: Visibilité maximale + avantages exclusifs'),

            const SizedBox(height: 16),

            // Couleur
            _DialogLabel('Couleur du plan'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: List.generate(_couleurs.length, (i) {
                final c = _couleurs[i];
                return GestureDetector(
                  onTap: () => setState(() => _colorIdx = i),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: _colorIdx == i
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: _colorIdx == i
                          ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                          : null,
                    ),
                    child: _colorIdx == i
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Prix
            _SliderWithInput(
              label:    'Prix (FCFA)',
              color:    selectedColor,
              value:    _prix.toInt(),
              minVal:   100,
              maxVal:   10000000,
              sliderMax: 500000,
              suffixe:  'FCFA',
              isInt:    false,
              onChanged: (v) => setState(() => _prix = v.toDouble()),
            ),

            const SizedBox(height: 4),

            // Durée
            _SliderWithInput(
              label:    'Durée (jours)',
              color:    selectedColor,
              value:    _duree,
              minVal:   1,
              maxVal:   3650,
              sliderMax: 365,
              suffixe:  'j',
              isInt:    true,
              onChanged: (v) => setState(() => _duree = v.toInt()),
            ),

            const SizedBox(height: 4),

            // Publications
            _SliderWithInput(
              label:    'Publications max',
              color:    selectedColor,
              value:    _nbPub,
              minVal:   1,
              maxVal:   9999,
              sliderMax: 100,
              suffixe:  'pub.',
              isInt:    true,
              onChanged: (v) => setState(() => _nbPub = v.toInt()),
            ),

            const SizedBox(height: 8),

            // ── AVANTAGES ──
            _DialogLabel('Avantages du plan'),
            const SizedBox(height: 8),

            // Liste des avantages ajoutés
            ..._avantages.asMap().entries.map((entry) {
              final i   = entry.key;
              final txt = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: selectedColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(txt,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary))),
                  GestureDetector(
                    onTap: () => setState(() => _avantages.removeAt(i)),
                    child: const Icon(Icons.close_rounded,
                        size: 15, color: AppColors.textMuted),
                  ),
                ]),
              );
            }),

            // Champ ajout
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _avantageCtrl,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'ex: 5 publications actives',
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: selectedColor, width: 1.5)),
                  ),
                  onSubmitted: (v) {
                    final val = v.trim();
                    if (val.isNotEmpty) {
                      setState(() {
                        _avantages.add(val);
                        _avantageCtrl.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final val = _avantageCtrl.text.trim();
                  if (val.isNotEmpty) {
                    setState(() {
                      _avantages.add(val);
                      _avantageCtrl.clear();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selectedColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selectedColor.withOpacity(0.4)),
                  ),
                  child: Icon(Icons.add_rounded, color: selectedColor, size: 18),
                ),
              ),
            ]),

            const SizedBox(height: 8),

            // Bouton créer
            GestureDetector(
              onTap: () {
                final nom = _nomCtrl.text.trim();
                if (nom.isEmpty) return;
                final plan = PlanConfig(
                  id:             'plan_custom_${DateTime.now().millisecondsSinceEpoch}',
                  nom:            nom,
                  estBasique:     false,
                  estBase:        false,
                  prix:           _prix,
                  nbPublications: _nbPub,
                  dureeJours:     _duree,
                  accentColor:    selectedColor,
                  icone:          Icons.star_rounded,
                  description:    _descCtrl.text.trim().isEmpty
                      ? null
                      : _descCtrl.text.trim(),
                  avantages:      List.from(_avantages),
                );
                widget.onCreer(plan);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFB68DFF), Color(0xFF8A5BFF)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFFB68DFF).withOpacity(0.3),
                      blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: const Text('Créer le plan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SLIDER + CHAMP TEXTE MANUEL (slider pour valeurs courantes,
// champ pour saisir des valeurs arbitrairement élevées)
// ─────────────────────────────────────────────────────────
class _SliderWithInput extends StatefulWidget {
  final String   label;
  final Color    color;
  final num      value;      // valeur courante
  final num      minVal;     // minimum absolu
  final num      maxVal;     // maximum absolu (pour le champ texte)
  final num      sliderMax;  // maximum du slider (plus maniable)
  final String   suffixe;
  final bool     isInt;      // true → entier, false → double
  final void Function(num) onChanged;

  const _SliderWithInput({
    required this.label,
    required this.color,
    required this.value,
    required this.minVal,
    required this.maxVal,
    required this.sliderMax,
    required this.suffixe,
    required this.isInt,
    required this.onChanged,
  });

  @override
  State<_SliderWithInput> createState() => _SliderWithInputState();
}

class _SliderWithInputState extends State<_SliderWithInput> {
  late final TextEditingController _ctrl;
  late num _current;

  @override
  void initState() {
    super.initState();
    _current = widget.value;
    _ctrl = TextEditingController(text: _fmt(_current));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(num v) => widget.isInt
      ? v.toInt().toString()
      : v.toInt().toString(); // prix affiché sans décimales

  void _fromText(String raw) {
    final parsed = num.tryParse(raw.replaceAll(' ', '').replaceAll(',', ''));
    if (parsed == null) return;
    final clamped = parsed.clamp(widget.minVal, widget.maxVal);
    setState(() => _current = clamped);
    widget.onChanged(clamped);
  }

  void _fromSlider(double v) {
    final val = widget.isInt ? v.toInt() : v;
    setState(() {
      _current = val;
      _ctrl.text = _fmt(val);
      _ctrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _ctrl.text.length));
    });
    widget.onChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    final sliderVal = _current.toDouble().clamp(
        widget.minVal.toDouble(), widget.sliderMax.toDouble());

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Label
      Text(widget.label, style: const TextStyle(
          fontSize: 12, color: AppColors.textMuted)),
      const SizedBox(height: 6),

      // Slider + champ texte côte à côte
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Slider (limité à sliderMax pour une manipulation confortable)
        Expanded(
          flex: 3,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: sliderVal,
              min:   widget.minVal.toDouble(),
              max:   widget.sliderMax.toDouble(),
              activeColor:   widget.color,
              inactiveColor: AppColors.divider,
              onChanged: _fromSlider,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Champ de saisie manuelle
        SizedBox(
          width: 90,
          child: TextField(
            controller:  _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textAlign:   TextAlign.center,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: widget.color),
            decoration: InputDecoration(
              suffixText:  widget.suffixe,
              suffixStyle: TextStyle(fontSize: 10, color: widget.color),
              filled:      true,
              fillColor:   widget.color.withOpacity(0.07),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: widget.color.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: widget.color.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: widget.color, width: 1.5)),
            ),
            onChanged:   _fromText,
            onSubmitted: _fromText,
          ),
        ),
      ]),
    ]);
  }
}


class _DialogLabel extends StatelessWidget {
  final String text;
  const _DialogLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: AppColors.textSecondary));
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  const _DialogField({required this.controller, required this.hint});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      filled: true, fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB68DFF), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    ),
  );
}

// ignore: unused_element
class _DialogSlider extends StatelessWidget {
  final String label, value;
  final Color  color;
  final Widget child;
  const _DialogSlider({
    required this.label, required this.value,
    required this.color, required this.child,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text(label, style: const TextStyle(
            fontSize: 12, color: AppColors.textMuted)),
        const Spacer(),
        Text(value, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
      child,
    ],
  );
}