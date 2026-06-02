// lib/features/home/tabs/profil/screens/profil_dashboard_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '/core/models/escort_model.dart';
import '../../../../../core/models/abonnement_model.dart';
import '../../../../../core/models/publication_model.dart';
import '../../../../../core/services/profil_service.dart';
import '../widgets/image_editor_screen.dart';
import 'publication_form_screen.dart';

class ProfilDashboard extends StatefulWidget {
  final EscortModel  escort;
  final VoidCallback onDeconnexion;
  /// Navigue vers l'onglet Abonnements de HomeScreen.
  /// tabIndex : 0=Plans, 1=Mon abonnement, 2=Historique
  final void Function(int tabIndex)? onGoToAbonnement;

  const ProfilDashboard({
    super.key,
    required this.escort,
    required this.onDeconnexion,
    this.onGoToAbonnement,
  });

  @override
  State<ProfilDashboard> createState() => _ProfilDashboardState();
}

class _ProfilDashboardState extends State<ProfilDashboard> {
  late List<PublicationGestion> _publications;
  late List<NotificationModel>  _notifications;
  late EscortModel              _escort;

  // Recherche locale sur les publications
  bool _searchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  Uint8List? _photoProfilBytes; // photo modifiée via éditeur

  // Plan réel (chargé depuis l'API)
  AbonnementSouscrit? _abonnement;
  bool _chargement = true;

  // Onglets Publications / Statistiques
  int _tabIndex = 0;

  String get _planNom           => _abonnement?.plan.nom ?? '—';
  Color  get _planCouleur       => _abonnement?.plan.accentColor ?? const Color(0xFF8A8A9A);
  int    get _planPubMax        => _abonnement?.quotaTotal ?? 0;
  int    get _planJoursRestants => _abonnement?.joursRestants ?? 0;

  int get _nonLues    => _notifications.where((n) => !n.lue).length;
  int get _pubActives => _publications.where((p) => p.statut == StatutPublication.active).length;
  int get _totalVues  => _publications.fold(0, (s, p) => s + p.vues);

  @override
  void initState() {
    super.initState();
    _escort        = widget.escort;
    _publications  = [];
    _notifications = [];
    _searchCtrl.addListener(
        () => _searchQuery.value = _searchCtrl.text.trim().toLowerCase());
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    // Récupère le token depuis ton SessionManager (adapte l'import si nécessaire)
    final token = SessionManager().accessToken;
    if (token == null) {
      if (mounted) setState(() => _chargement = false);
      return;
    }
    final svc = ProfilService(token);
    try {
      final results = await Future.wait([
        svc.getAbonnement(),
        svc.getMesPublications(),
        svc.getNotifications(),
      ]);
      if (!mounted) return;
      setState(() {
        _abonnement    = results[0] as AbonnementSouscrit?;
        final pubs     = results[1] as List<PublicationModel>;
        _publications  = pubs.map((p) => PublicationGestion(
          id:             p.id,
          titre:          p.titre,
          categorie:      p.categorie,
          imageUrl:       p.imageUrl.isNotEmpty ? p.imageUrl : null,
          statut:         _mapStatut(p.statutBackend, estDisponible: p.estDisponible),
          vues:           p.vues,
          dateExpiration: p.dateExpiration,
          estDisponible: p.estDisponible,
          nbAvis:         p.nbAvis, 
          noteMoyenne:    p.noteMoyenne,
        )).toList();
        final notifs   = results[2] as List<NotificationApiModel>;
        _notifications = notifs.map((n) => NotificationModel(
          id:      n.id,
          type:    _parseTypeNotif(n.type),
          titre:   n.titre,
          message: n.message,
          date:    n.date,
          lue:     n.lue,
        )).toList();
        _chargement = false;
      });
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  TypeNotification _parseTypeNotif(String t) {
    switch (t) {
      case 'ADMIN':       return TypeNotification.admin;
      case 'ABONNEMENT':  return TypeNotification.abonnement;
      case 'PUBLICATION': return TypeNotification.publication;
      default:            return TypeNotification.systeme;
    }
  }

  // Convertit le statut backend vers le statut local.
  // - ACTIVE    → active    (peu importe estDisponible — c'est un champ séparé)
  // - EXPIREE   → expiree   (abonnement expiré / date dépassée)
  // - BROUILLON → brouillon
  // - SUSPENDUE → expiree   (suspendu par admin, même traitement visuel)
  StatutPublication _mapStatut(String s, {bool estDisponible = true}) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':    return StatutPublication.active;
      case 'EXPIREE':   return StatutPublication.expiree;
      case 'SUSPENDUE': return StatutPublication.expiree;
      default:          return StatutPublication.brouillon;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color ?? AppColors.surface,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin:          const EdgeInsets.all(16),
      duration:        const Duration(seconds: 2),
    ));
  }

  void _supprimerPublication(PublicationGestion pub) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
        content: Text('Voulez-vous supprimer "${pub.titre}" ?',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final token = SessionManager().accessToken;
              if (token != null) {
                try {
                  await ProfilService(token).supprimerPublication(pub.id);
                } catch (_) {}
              }
              if (mounted) {
                setState(() => _publications.remove(pub));
                _snack('Publication supprimée', color: const Color(0xFFFF5252));
              }
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
  }

  // Bascule estDisponible sur le backend, puis met à jour l'UI
  // depuis la réponse serveur (évite l'état stale au retour de navigation).
  Future<void> _toggleActiver(PublicationGestion pub) async {
    final estActive = pub.statut == StatutPublication.active;

    // Vérification quota côté client (pour activation uniquement)
    if (!estActive && _pubActives >= _planPubMax) {
      _snack('Limite de $_planPubMax publications atteinte. Passez à un plan supérieur !');
      widget.onGoToAbonnement?.call(0); // 0 = onglet Plans
      return;
    }

    final idx = _publications.indexOf(pub);

    // Mise à jour optimiste — UI réagit immédiatement
    setState(() {
      _publications[idx] = PublicationGestion(
        id:             pub.id,
        titre:          pub.titre,
        categorie:      pub.categorie,
        imageUrl:       pub.imageUrl,
        statut:         estActive
            ? StatutPublication.brouillon
            : StatutPublication.active,
        vues:           pub.vues,
        dateExpiration: pub.dateExpiration,
      );
    });

    final token = SessionManager().accessToken;
    if (token == null) return;

    try {
      // Envoie le nouveau statut (ACTIVE ↔ BROUILLON) — séparé de estDisponible
      final updated = await ProfilService(token).modifierPublication(
        pub.id,
        statut: estActive ? 'BROUILLON' : 'ACTIVE',
        imagesToDelete: [],
      );

      if (mounted) {
        setState(() {
          _publications[idx] = PublicationGestion(
            id:             updated.id,
            titre:          updated.titre,
            categorie:      updated.categorie,
            imageUrl:       updated.imageUrl.isNotEmpty
                ? updated.imageUrl : pub.imageUrl,
            statut:         _mapStatut(updated.statutBackend,
                estDisponible: updated.estDisponible),
            vues:           updated.vues,
            dateExpiration: updated.dateExpiration,
            estDisponible:  updated.estDisponible,
            nbAvis:         pub.nbAvis,
            noteMoyenne:    pub.noteMoyenne,
          );
        });
        _snack(!estActive ? 'Publication activée ✓' : 'Publication en brouillon');
      }
    } catch (e) {
      // Rollback vers l'état d'origine
      if (mounted) {
        setState(() => _publications[idx] = pub);
        final msg = e.toString().replaceFirst('Exception: ', '');
        _snack(msg, color: const Color(0xFFFF5252));
      }
    }
  }

  Future<void> _toggleDisponible(PublicationGestion pub) async {
  final token = SessionManager().accessToken;
  if (token == null) return;
  final idx = _publications.indexOf(pub);
  try {
    final updated = await ProfilService(token).modifierPublication(
      pub.id,
      estDisponible: !pub.estDisponible,
      imagesToDelete: [],
    );
    if (mounted) {
      setState(() {
        _publications[idx] = PublicationGestion(
          id:             updated.id,
          titre:          updated.titre,
          categorie:      updated.categorie,
          imageUrl:       updated.imageUrl.isNotEmpty ? updated.imageUrl : null,
          statut:         _mapStatut(updated.statutBackend,
              estDisponible: updated.estDisponible),
          vues:           updated.vues,
          dateExpiration: updated.dateExpiration,
          estDisponible:  updated.estDisponible,
          nbAvis:         pub.nbAvis,
          noteMoyenne:    pub.noteMoyenne,
        );
      });
      _snack(updated.estDisponible ? '👁 Visible' : '👁 Masqué aux visiteurs');
    }
  } catch (e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    _snack(msg, color: const Color(0xFFFF5252));
  }
}

  void _ajouterPublication() {
    if (_pubActives >= _planPubMax) {
if (_abonnement == null) {
  _snack('Aucun abonnement actif. Souscrivez un plan pour publier.');
  widget.onGoToAbonnement?.call(0);
  return;
}
_snack('Quota atteint ($_pubActives/$_planPubMax). Désactivez une publication ou changez de plan.');
widget.onGoToAbonnement?.call(0);
return;
    }
    Navigator.push<PublicationFormResult>(
      context,
      MaterialPageRoute(builder: (_) => const PublicationFormScreen()),
    ).then((result) async {
      if (result == null || !mounted) return;
      setState(() {
            _publications.insert(0, PublicationGestion(
              id:             result.id,
              titre:          result.titre,
              categorie:      result.categories.isNotEmpty
                  ? result.categories.first : 'Autre',
              imageUrl:       result.imageUrls.isNotEmpty
                  ? result.imageUrls.first : null,
              statut:         result.dateExpiration.isAfter(DateTime.now())
                  ? StatutPublication.active
                  : StatutPublication.expiree,
              vues:           result.vues,
              dateExpiration: result.dateExpiration,
            ));
      });
      // Rafraîchissement complet depuis le serveur
       await chargerDonnees();   // ← IMPORTANT
      _snack('Publication créée !', color: const Color(0xFF25D366));
    });
  }

  // Ouvre l'éditeur d'image pour la photo de profil
  Future<void> _changerPhotoProfil() async {
    final bytes = await ouvrirEditeurImage(context);
    if (bytes == null || !mounted) return;
    setState(() => _photoProfilBytes = bytes);

    final token = SessionManager().accessToken;
    if (token != null) {
      try {
        final url = await ProfilService(token)
            .updatePhoto(bytes, 'profil_${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (mounted) {
          setState(() {
            _escort = EscortModel(
              id:              _escort.id,
              pseudo:          _escort.pseudo,
              email:           _escort.email,
              telephone:       _escort.telephone,
              photoUrl:        url,
              estVerifie:      _escort.estVerifie,
              dateInscription: _escort.dateInscription,
            );
          });
          // Mettre à jour la session globale pour que le changement persiste
          SessionManager().updateEscort(_escort);
        }
      } catch (_) {}
    }
  }

  void _ouvrirEditionProfil() {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _EditProfilSheet(
        escort:              _escort,
        photoProfilBytes:    _photoProfilBytes,
        onSave:              (updated) => setState(() => _escort = updated),
        onChangerPhoto:      _changerPhotoProfil,
      ),
    );
  }

  void _ouvrirNotifications() {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _NotificationsSheet(
        notifications: _notifications,
        onMarquerLue:  (id) => setState(() =>
            _notifications.firstWhere((n) => n.id == id).lue = true),
        onToutMarquer: () => setState(() =>
            _notifications.forEach((n) => n.lue = true)),
        onSupprimer:   (id) => setState(() =>
            _notifications.removeWhere((n) => n.id == id)),
      ),
    );
  }

  void _confirmerDeconnexion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
        content: const Text('Voulez-vous vous déconnecter ?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeconnexion();
            },
            child: const Text('Déconnexion',
                style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────

@override
void didChangeDependencies() {
  super.didChangeDependencies();

  // Cette méthode est appelée quand on revient sur l'écran
  final route = ModalRoute.of(context);
  if (route != null) {
    route.completed.then((_) async {
      if (mounted) {
        await chargerDonnees();   // Rafraîchit automatiquement au retour
      }
    });
  }
}

@override
Widget build(BuildContext context) {
  if (_chargement) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryPink),
    );
  }

  final w         = MediaQuery.of(context).size.width;
  final isMobile  = w < 700;
  final isDesktop = w >= 1100;
  final hPad      = isDesktop ? 60.0 : isMobile ? 16.0 : 28.0;
  final gridCols  = isDesktop ? 4 : isMobile ? 3 : 3;

  return RefreshIndicator(
    onRefresh: chargerDonnees,
    color: AppColors.primaryPink,
    backgroundColor: AppColors.surface,
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: isMobile
              ? _buildMobileHeader(hPad)
              : _buildWideHeader(hPad, isDesktop),
        ),

        SliverToBoxAdapter(child: _buildStats(hPad, isMobile)),

        // ── Onglets Publications / Statistiques ──────────
        SliverToBoxAdapter(child: _buildTabBar(hPad)),

        // ── Contenu selon onglet actif ────────────────────
        if (_tabIndex == 0) ...[
          SliverToBoxAdapter(child: _buildPubsHeader(hPad)),
          // Grille des publications
          ValueListenableBuilder<String>(
          valueListenable: _searchQuery,
          builder: (context, query, _) {
            final filtered = query.isEmpty
                ? _publications
                : _publications.where((p) =>
                    p.titre.toLowerCase().contains(query) ||
                    p.categorie.toLowerCase().contains(query)).toList();

            if (filtered.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 32),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        _publications.isEmpty ? 'Aucune publication pour le moment.' : 'Aucun résultat pour "$query".',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ]),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 80),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCols,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final pub = filtered[i];
                    final realIdx = _publications.indexOf(pub);

                    return _PubGridTile(
                      publication: pub,
                      onSupprimer: () => _supprimerPublication(pub),
                      onModifier: () async {
                        final token = SessionManager().accessToken;
                        if (token == null) return;

                        PublicationModel? fullModel;
                        try {
                          fullModel = await ProfilService(token).getPublicationById(pub.id);
                        } catch (_) {}

                        if (!mounted) return;

                        Navigator.push<PublicationFormResult>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicationFormScreen(
                              existing: pub,
                              existingModel: fullModel,
                            ),
                          ),
                        ).then((_) async {
                          if (mounted) await chargerDonnees(); // ← Auto refresh
                        });
                      },
                      onToggleActif:      () => _toggleActiver(pub),
                      onToggleDisponible: () => _toggleDisponible(pub),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            );
          },
        ),
        ] else ...[
          // ── ONGLET STATISTIQUES ───────────────────────
          SliverToBoxAdapter(child: _buildStatistiques(hPad, isMobile)),
        ],
      ],
    ),
  );
}

  // ── TabBar Publications / Statistiques ──────────────
  Widget _buildTabBar(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColors.divider),
        ),
        child: Row(children: [
          _TabBtn(
            label:    'Publications',
            icon:     Icons.grid_on_rounded,
            selected: _tabIndex == 0,
            color:    _planCouleur,
            onTap:    () => setState(() => _tabIndex = 0),
          ),
          _TabBtn(
            label:    'Statistiques',
            icon:     Icons.bar_chart_rounded,
            selected: _tabIndex == 1,
            color:    _planCouleur,
            onTap:    () => setState(() => _tabIndex = 1),
          ),
        ]),
      ),
    );
  }

  // ── Onglet Statistiques ──────────────────────────────
  Widget _buildStatistiques(double hPad, bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats globales existantes
          _StatsDashboard(
            publications: _publications,
            abonnement:   _abonnement,
            planCouleur:  _planCouleur,
            planPubMax:   _planPubMax,
          ),
          const SizedBox(height: 28),
          // Stats par publication (nouveau)
          if (_publications.isNotEmpty)
            _PubStatsPanel(
              publications: _publications,
              planCouleur:  _planCouleur,
            ),
        ],
      ),
    );
  }

  // ── Header mobile (photo centrée, pseudo, stats en ligne) ──
  Widget _buildMobileHeader(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
      child: Column(
        children: [
          // Ligne : photo + actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Avatar(
                escort:      _escort,
                planCouleur: _planCouleur,
                size:        80,
                onTap:       _changerPhotoProfil,
                photoBytes:  _photoProfilBytes,
              ),
              Row(children: [
                _ActionBtn(
                  icon:  Icons.notifications_none_rounded,
                  badge: _nonLues > 0 ? _nonLues : null,
                  onTap: _ouvrirNotifications,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon:  Icons.logout_rounded,
                  color: const Color(0xFFFF5252),
                  onTap: _confirmerDeconnexion,
                ),
              ]),
            ],
          ),
          const SizedBox(height: 14),

          // Pseudo + vérification
          Align(
            alignment: Alignment.centerLeft,
            child: _PseudoBadge(escort: _escort, planNom: _planNom, planCouleur: _planCouleur),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(_escort.email,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          const SizedBox(height: 14),

          // Bouton modifier profil
          _EditProfilBtn(onTap: _ouvrirEditionProfil),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Header tablette / desktop (photo à gauche, infos à droite) ──
  Widget _buildWideHeader(double hPad, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          _Avatar(
            escort:      _escort,
            planCouleur: _planCouleur,
            size:        isDesktop ? 110 : 90,
            onTap:       _changerPhotoProfil,
            photoBytes:  _photoProfilBytes,
          ),

          SizedBox(width: isDesktop ? 40 : 24),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PseudoBadge(
                        escort: _escort,
                        planNom: _planNom,
                        planCouleur: _planCouleur),
                    const Spacer(),
                    _ActionBtn(
                      icon:  Icons.notifications_none_rounded,
                      badge: _nonLues > 0 ? _nonLues : null,
                      onTap: _ouvrirNotifications,
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon:  Icons.logout_rounded,
                      color: const Color(0xFFFF5252),
                      onTap: _confirmerDeconnexion,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_escort.email,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: _EditProfilBtn(onTap: _ouvrirEditionProfil),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats (inspirées Instagram) ──
  Widget _buildStats(double hPad, bool isMobile) {
    final quotaAtteint = _planPubMax > 0 && _pubActives >= _planPubMax;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ligne de stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color:        AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border:       Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                _StatItem(
                  value: '$_pubActives/$_planPubMax',
                  label: 'Publications',
                  color: quotaAtteint ? const Color(0xFFFF5252) : _planCouleur,
                ),
                _Divider(),
                _StatItem(
                  value: '$_planJoursRestants j',
                  label: 'Abonnement',
                  color: _planCouleur,
                ),
                _Divider(),
                _StatItem(
                  value: '$_totalVues',
                  label: 'Vues totales',
                  color: AppColors.primaryPink,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Bandeau infos abonnement + bouton Détail
          GestureDetector(
            onTap: () => widget.onGoToAbonnement?.call(1), // 1 = Mon abonnement
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:        _planCouleur.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border:       Border.all(color: _planCouleur.withOpacity(0.25)),
              ),
              child: Row(children: [
                // Icône plan
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color:        _planCouleur.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _abonnement?.plan.icone ?? Icons.star_outline_rounded,
                    size: 17, color: _planCouleur),
                ),
                const SizedBox(width: 12),

                // Nom plan + jours restants
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        _planNom == '—' ? 'Aucun abonnement' : 'Plan $_planNom',
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      _planCouleur,
                        ),
                      ),
                      if (quotaAtteint) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Limite atteinte',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                              color: Color(0xFFFF5252))),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      _planJoursRestants > 0
                          ? '$_planJoursRestants jour${_planJoursRestants > 1 ? "s" : ""} restants'
                          : 'Abonnement expiré',
                      style: TextStyle(
                        fontSize: 11,
                        color:    _planJoursRestants > 0
                            ? AppColors.textMuted
                            : const Color(0xFFFF5252),
                      ),
                    ),
                  ],
                )),

                // Bouton Détail
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:        _planCouleur.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: _planCouleur.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Détail',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      _planCouleur)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 14, color: _planCouleur),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── En-tête section publications ──
  Widget _buildPubsHeader(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.grid_on_rounded,
                size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text('Mes publications',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            // Bouton recherche
            GestureDetector(
              onTap: () => setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchCtrl.clear();
                }
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _searchOpen
                      ? AppColors.primaryPink.withOpacity(0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _searchOpen
                        ? AppColors.primaryPink.withOpacity(0.4)
                        : AppColors.divider,
                  ),
                ),
                child: Icon(
                  _searchOpen
                      ? Icons.search_off_rounded
                      : Icons.search_rounded,
                  size: 16,
                  color: _searchOpen
                      ? AppColors.primaryPink
                      : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Bouton ajouter
            GestureDetector(
              onTap: _ajouterPublication,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:        AppColors.primaryPink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primaryPink.withOpacity(0.35)),
                ),
                child: const Row(children: [
                  Icon(Icons.add_rounded,
                      color: AppColors.primaryPink, size: 15),
                  SizedBox(width: 5),
                  Text('Ajouter',
                      style: TextStyle(
                          color:      AppColors.primaryPink,
                          fontSize:   12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),

          // Barre de recherche animée
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _searchOpen
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color:        AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryPink.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus:  true,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText:   'Rechercher dans mes publications…',
                          hintStyle:  const TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                          border:     InputBorder.none,
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.primaryPink, size: 18),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => setState(() => _searchCtrl.clear()),
                                  child: const Icon(Icons.close_rounded,
                                      size: 16, color: AppColors.textMuted),
                                )
                              : null,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildEmptyPubs(double hPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 40),
      child: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.photo_library_outlined,
              size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('Aucune publication pour le moment.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// WIDGETS LOCAUX
// ═══════════════════════════════════════════════════════

class _Avatar extends StatelessWidget {
  final EscortModel  escort;
  final Color        planCouleur;
  final double       size;
  final VoidCallback onTap;
  final Uint8List?   photoBytes; // prioritaire sur photoUrl réseau

  const _Avatar({
    required this.escort,
    required this.planCouleur,
    required this.size,
    required this.onTap,
    this.photoBytes,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape:  BoxShape.circle,
            border: Border.all(color: planCouleur, width: 2.5),
          ),
          child: ClipOval(
            child: photoBytes != null
                ? Image.memory(photoBytes!, fit: BoxFit.cover)
                : escort.photoUrl != null
                    ? Image.network(escort.photoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(size))
                    : _placeholder(size),
          ),
        ),
        // Bouton caméra
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:  planCouleur,
              shape:  BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2),
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 12),
          ),
        ),
        if (escort.estVerifie)
          Positioned(
            right: 0, top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: AppColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded,
                  color: Color(0xFF5DB8FF), size: 16),
            ),
          ),
      ]),
    );
  }

  Widget _placeholder(double size) => Container(
    color: AppColors.surfaceElevated,
    child: Icon(Icons.person, color: AppColors.textMuted, size: size * 0.45),
  );
}

class _PseudoBadge extends StatelessWidget {
  final EscortModel escort;
  final String      planNom;
  final Color       planCouleur;

  const _PseudoBadge({
    required this.escort,
    required this.planNom,
    required this.planCouleur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(escort.pseudo,
          style: const TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        planCouleur.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: planCouleur.withOpacity(0.4)),
        ),
        child: Text(planNom,
            style: TextStyle(
                fontSize:   10,
                fontWeight: FontWeight.w700,
                color:      planCouleur)),
      ),
    ]);
  }
}

class _EditProfilBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _EditProfilBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text('Modifier le profil',
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.textPrimary)),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final int?         badge;
  final Color?       color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.onTap,
    this.badge,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color:        AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, size: 18,
              color: color ?? AppColors.textMuted),
        ),
        if (badge != null)
          Positioned(
            top: -4, right: -4,
            child: Container(
              width: 18, height: 18,
              decoration: const BoxDecoration(
                  color: AppColors.primaryPink, shape: BoxShape.circle),
              child: Center(
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final Color  color;
  const _StatItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: TextStyle(
              fontSize:   18,
              fontWeight: FontWeight.w800,
              color:      color)),
      const SizedBox(height: 2),
      Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textMuted)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 32, color: AppColors.divider);
}

// ─────────────────────────────────────────────────────────
// TUILE PUBLICATION (grille)
// ─────────────────────────────────────────────────────────
class _PubGridTile extends StatelessWidget {
  final PublicationGestion publication;
  final VoidCallback       onSupprimer;
  final VoidCallback       onModifier;
  final VoidCallback       onToggleActif;
  final VoidCallback       onToggleDisponible;

  const _PubGridTile({
    required this.publication,
    required this.onSupprimer,
    required this.onModifier,
    required this.onToggleActif,
    required this.onToggleDisponible,
    
  });

  @override
  Widget build(BuildContext context) {
    final pub    = publication;
    final color  = pub.statut.couleur;
    final actif  = pub.statut == StatutPublication.active;

    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
          color: actif
              ? color.withOpacity(0.4)
              : AppColors.divider,
          width: actif ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image ──
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                // Image
                pub.imageUrl != null
                    ? Image.network(
                        pub.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    color: AppColors.surfaceElevated,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primaryPink),
                                    ),
                                  ),
                        errorBuilder: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),

                // Overlay sombre si inactif
                if (!actif)
                  Container(color: Colors.black.withOpacity(0.38)),

                // Badge statut
                Positioned(
                  top: 7, left: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color:        color.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(pub.statut.label,
                        style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   9,
                            fontWeight: FontWeight.w700)),
                  ),
                ),

                // Vues
                if (actif)
                  Positioned(
                    bottom: 6, right: 7,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.visibility_rounded,
                          size: 11, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text('${pub.vues}',
                          style: const TextStyle(
                              color:      Colors.white,
                              fontSize:   10,
                              fontWeight: FontWeight.w600,
                              shadows: [Shadow(blurRadius: 4)])),
                    ]),
                  ),
              ]),
            ),

            // ── Infos + actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pub.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      AppColors.textPrimary)),
                  const SizedBox(height: 5),
                  Row(children: [
                    // Bouton 1 — Statut actif/brouillon
                    // Désactivé si expiré (abonnement expiré)
_TileAction(
  icon:  actif
      ? Icons.pause_circle_outline_rounded
      : Icons.play_circle_outline_rounded,
  color: pub.statut == StatutPublication.expiree
      ? AppColors.textMuted
      : actif ? Colors.orange : const Color(0xFF25D366),
  onTap: pub.statut == StatutPublication.expiree
      ? null
      : onToggleActif,
),
const SizedBox(width: 4),
// Bouton 2 — Disponibilité (œil)
_TileAction(
  icon:  pub.estDisponible
      ? Icons.visibility_rounded
      : Icons.visibility_off_outlined,
  color: pub.estDisponible
      ? const Color(0xFF5DB8FF)
      : AppColors.textMuted,
  onTap: onToggleDisponible,
),
const SizedBox(width: 4),
                    const SizedBox(width: 4),
                    // Modifier
                    _TileAction(
                      icon:  Icons.edit_outlined,
                      color: AppColors.primaryPink,
                      onTap: onModifier,
                    ),
                    const SizedBox(width: 4),
                    // Supprimer
                    _TileAction(
                      icon:  Icons.delete_outline_rounded,
                      color: const Color(0xFFFF5252),
                      onTap: onSupprimer,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    color: AppColors.surfaceElevated,
    child: const Center(
      child: Icon(Icons.image_outlined,
          color: AppColors.textMuted, size: 28),
    ),
  );
}

class _TileAction extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback? onTap;
  const _TileAction({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: disabled ? 0.35 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(7),
              border:       Border.all(color: color.withOpacity(0.25)),
            ),
            child: Center(child: Icon(icon, size: 13, color: color)),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BOTTOM SHEET : ÉDITION PROFIL
// ═══════════════════════════════════════════════════════
class _EditProfilSheet extends StatefulWidget {
  final EscortModel escort;
  final Uint8List? photoProfilBytes;
  final void Function(EscortModel) onSave;
  final VoidCallback onChangerPhoto;

  const _EditProfilSheet({
    required this.escort,
    required this.onSave,
    required this.onChangerPhoto,
    this.photoProfilBytes,
  });

  @override
  State<_EditProfilSheet> createState() => _EditProfilSheetState();
}

class _EditProfilSheetState extends State<_EditProfilSheet> {
  late final TextEditingController _pseudoCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _pseudoCtrl = TextEditingController(text: widget.escort.pseudo);
    _telCtrl = TextEditingController(text: widget.escort.telephone);
    _emailCtrl = TextEditingController(text: widget.escort.email);
  }

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _confirmerSuppression(BuildContext ctx) {
  showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer le compte ?',
          style: TextStyle(color: Color(0xFFFF5252), fontSize: 16,
              fontWeight: FontWeight.w700)),
      content: const Text(
        'Cette action est irréversible. Toutes vos publications, '
        'abonnements et données seront définitivement supprimés.',
        style: TextStyle(color: AppColors.textSecondary,
            fontSize: 13, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler',
              style: TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final token = SessionManager().accessToken;
            if (token == null) return;
            try {
              await ProfilService(token).supprimerCompte();
              await SessionManager().deconnecter();
              if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
            } catch (_) {
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Erreur lors de la suppression.'),
                  backgroundColor: Color(0xFFFF5252),
                ));
            }
          },
          child: const Text('Supprimer définitivement',
              style: TextStyle(color: Color(0xFFFF5252),
                  fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

  void _ouvrirChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Changer le mot de passe', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Ancien mot de passe')),
            const SizedBox(height: 8),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Nouveau mot de passe')),
            const SizedBox(height: 8),
            TextField(controller: confCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Confirmer le nouveau mot de passe')),
          ]),
          actions: [
            TextButton(onPressed: () { Navigator.pop(ctx); }, child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted))),
            TextButton(
              onPressed: loading ? null : () async {
                final oldP = oldCtrl.text.trim();
                final newP = newCtrl.text.trim();
                final conf = confCtrl.text.trim();
                if (oldP.isEmpty || newP.isEmpty || conf.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tous les champs sont requis')));
                  return;
                }
                if (newP.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')));
                  return;
                }
                if (newP != conf) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La confirmation ne correspond pas')));
                  return;
                }

                setSt(() => loading = true);
                final token = SessionManager().accessToken;
                try {
                  if (token != null) {
                    await ProfilService(token).updatePassword(ancienMotDePasse: oldP, nouveauMotDePasse: newP);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe mis à jour')));
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                } finally {
                  setSt(() => loading = false);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Modifier le profil',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Photo de profil
          Center(
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryPink,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: widget.photoProfilBytes != null
                        ? Image.memory(
                            widget.photoProfilBytes!,
                            fit: BoxFit.cover,
                          )
                        : widget.escort.photoUrl != null
                            ? Image.network(
                                widget.escort.photoUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.surfaceElevated,
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.textMuted,
                                  size: 38,
                                ),
                              ),
                  ),
                ),
                // Bouton caméra
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: widget.onChangerPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Changer la photo',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryPink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Pseudo
          const Text(
            'Pseudo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          _EditField(
            controller: _pseudoCtrl,
            hint: 'Votre pseudo',
          ),

          const SizedBox(height: 14),

          // Téléphone
          const Text(
            'Téléphone',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          _EditField(
            controller: _telCtrl,
            hint: '+237 6XX XXX XXX',
            keyboard: TextInputType.phone,
          ),

          const SizedBox(height: 14),

          // Email
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          _EditField(
            controller: _emailCtrl,
            hint: 'votre@email.com',
            keyboard: TextInputType.emailAddress,
          ),

          const SizedBox(height: 14),

          // Changer mot de passe
          GestureDetector(
            onTap: () => _ouvrirChangePassword(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Center(
                child: Text('Changer le mot de passe',
                    style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.w700)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bouton supprimer compte
GestureDetector(
  onTap: () => _confirmerSuppression(context),
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFF5252).withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.3)),
    ),
    child: const Center(
      child: Text('Supprimer mon compte',
          style: TextStyle(color: Color(0xFFFF5252),
              fontWeight: FontWeight.w700, fontSize: 13)),
    ),
  ),
),

          const SizedBox(height: 20),

          // Bouton sauvegarder
          GestureDetector(
            onTap: () async {
              final pseudo = _pseudoCtrl.text.trim().isEmpty
                  ? widget.escort.pseudo
                  : _pseudoCtrl.text.trim();
              final tel = _telCtrl.text.trim().isEmpty
                  ? widget.escort.telephone
                  : _telCtrl.text.trim();
              final email = _emailCtrl.text.trim().isEmpty
                ? widget.escort.email
                : _emailCtrl.text.trim();

              final token = SessionManager().accessToken;
              if (token == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Utilisateur non authentifié.', style: TextStyle(color: Colors.white)),
                    backgroundColor: const Color(0xFFFF5252),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ));
                }
                return;
              }

              final svc = ProfilService(token);
              final changedPseudo = pseudo != widget.escort.pseudo ? pseudo : null;
              final changedTel = tel != widget.escort.telephone ? tel : null;
              final changedEmail = email != widget.escort.email ? email : null;

              if (changedPseudo != null || changedTel != null || changedEmail != null) {
                try {
                  await svc.updateProfil(
                    pseudo: changedPseudo,
                    telephone: changedTel,
                    email: changedEmail,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString(), style: const TextStyle(color: Colors.white)),
                      backgroundColor: const Color(0xFFFF5252),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
                  return;
                }
              }

              widget.onSave(EscortModel(
                id:              widget.escort.id,
                pseudo:          pseudo,
                email:           email,
                telephone:       tel,
                photoUrl:        widget.escort.photoUrl,
                estVerifie:      widget.escort.estVerifie,
                dateInscription: widget.escort.dateInscription,
              ));
              if (context.mounted) Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5DA8), Color(0xFFB68DFF)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Enregistrer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboard;

  const _EditField({
    required this.controller,
    required this.hint,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryPink,
              width: 1.5,
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════
// BOTTOM SHEET : NOTIFICATIONS
// ═══════════════════════════════════════════════════════
class _NotificationsSheet extends StatefulWidget {
  final List<NotificationModel> notifications;
  final Function(String)        onMarquerLue;
  final VoidCallback            onToutMarquer;
  final Function(String)        onSupprimer;

  const _NotificationsSheet({
    required this.notifications,
    required this.onMarquerLue,
    required this.onToutMarquer,
    required this.onSupprimer,
  });

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  int get _nonLues =>
      widget.notifications.where((n) => !n.lue).length;

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize:     0.4,
      maxChildSize:     0.92,
      snap:             true,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('Notifications',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              if (_nonLues > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.primaryPink,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('$_nonLues',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
              const Spacer(),
              if (_nonLues > 0)
                GestureDetector(
                  onTap: () {
                    widget.onToutMarquer();
                    setState(() {});
                  },
                  child: const Text('Tout lire',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryPink,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryPink)),
                ),
            ]),
          ),
          const Divider(
              color: AppColors.divider, height: 20,
              indent: 20, endIndent: 20),

          Expanded(
            child: widget.notifications.isEmpty
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text('Aucune notification',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14)),
                    ]),
                  )
                : ListView.builder(
                    controller: sc,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.notifications.length,
                    itemBuilder: (_, i) {
                      final n     = widget.notifications[i];
                      final color = n.type.couleur;
                      return Dismissible(
                        key:       Key(n.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          widget.onSupprimer(n.id);
                          setState(() {});
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding:   const EdgeInsets.only(right: 20),
                          margin:    const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color:        const Color(0x22FF5252),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Color(0xFFFF5252)),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (!n.lue) {
                              widget.onMarquerLue(n.id);
                              setState(() {});
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:   const EdgeInsets.only(bottom: 10),
                            padding:  const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: n.lue
                                  ? AppColors.surface
                                  : color.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: n.lue
                                    ? AppColors.divider
                                    : color.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(n.type.icone,
                                      color: color, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(n.type.label,
                                              style: TextStyle(
                                                  color: color,
                                                  fontSize: 9,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ),
                                        const Spacer(),
                                        Text(_formatDate(n.date),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textMuted)),
                                        if (!n.lue) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 7, height: 7,
                                            decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle),
                                          ),
                                        ],
                                      ]),
                                      const SizedBox(height: 6),
                                      Text(n.titre,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: n.lue
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                              color: AppColors.textPrimary)),
                                      const SizedBox(height: 3),
                                      Text(n.message,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════
// BOUTON D'ONGLET
// ═══════════════════════════════════════════════════════
class _TabBtn extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     selected;
  final Color    color;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: selected
                ? Border.all(color: color.withOpacity(0.35))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14,
                  color: selected ? color : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color:      selected ? color : AppColors.textMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// DASHBOARD STATISTIQUES CORRIGÉ
// ═══════════════════════════════════════════════════════
class _StatsDashboard extends StatefulWidget {
  final List<PublicationGestion> publications;
  final AbonnementSouscrit?      abonnement;
  final Color                    planCouleur;
  final int                      planPubMax;

  const _StatsDashboard({
    required this.publications,
    required this.abonnement,
    required this.planCouleur,
    required this.planPubMax,
  });

  @override
  State<_StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<_StatsDashboard> {
  int? _touchedDonutIndex;
  int? _touchedBarIndex;

  // ── Données calculées ──────────────────────────────────
  int get _nbActives    => widget.publications.where((p) => p.statut == StatutPublication.active).length;
  int get _nbBrouillons => widget.publications.where((p) => p.statut == StatutPublication.brouillon).length;
  int get _nbExpirees   => widget.publications.where((p) => p.statut == StatutPublication.expiree).length;
  int get _totalVues    => widget.publications.fold(0, (s, p) => s + p.vues);
  int get _total        => widget.publications.length;
  int get _totalAvis    => widget.publications.fold(0, (s, p) => s + p.nbAvis);

  // Note moyenne globale du compte (pondérée par le nombre d'avis de chaque publication)
  double get _noteMoyenneCompte {
    if (_totalAvis == 0) return 0.0;
    
    double somme = 0;
    int totalAvisValides = 0;
    
    for (final p in widget.publications) {
      if (p.nbAvis > 0) {
        // Optionnel : si votre modèle utilise une note ou noteMoyenne
        somme += (p.noteMoyenne ?? 0.0) * p.nbAvis;
        totalAvisValides += p.nbAvis;
      }
    }
    return totalAvisValides > 0 ? somme / totalAvisValides : 0.0;
  }

  // Catégories (top 6)
  List<MapEntry<String, int>> get _topCategories {
    final map = <String, int>{};
    for (final p in widget.publications) {
      // Évite un crash si p.categorie est null ou vide
      final cat = p.categorie.isEmpty ? 'Inconnue' : p.categorie;
      map[cat] = (map[cat] ?? 0) + 1;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).toList();
  }

  // Vues simulées sur 7 jours
  List<double> get _vues7Jours {
    if (_totalVues == 0) return List.filled(7, 0);
    final base = _totalVues / 7;
    final List<double> vals = [];
    final variations = [0.6, 0.8, 1.1, 0.9, 1.2, 1.4, 1.0];
    for (final v in variations) {
      vals.add((base * v).clamp(0, _totalVues.toDouble()));
    }
    return vals;
  }

  String _dayLabel(int offset) {
    final d = DateTime.now().subtract(Duration(days: 6 - offset));
    const j = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return j[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.publications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bar_chart_rounded, size: 48,
                color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Aucune donnée disponible',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Créez votre première publication pour voir les statistiques.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── KPIs en ligne ──────────────────────────────
        _buildKpis(),
        const SizedBox(height: 20),

        // ── Donut statuts ──────────────────────────────
        _buildDonutStatuts(),
        const SizedBox(height: 20),

        // ── Jauge quota ───────────────────────────────
        _buildJaugeQuota(),
      ],
    );
  }

  // ── KPIs ──────────────────────────────────────────────
  Widget _buildKpis() {
    return Row(children: [
      Expanded(
        child: _KpiCard(value: '$_total', label: 'Total pubs',
            color: widget.planCouleur, icon: Icons.article_outlined),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _KpiCard(value: '$_totalVues', label: 'Vues totales',
            color: AppColors.primaryPink, icon: Icons.visibility_outlined),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _KpiCard(
          value: _noteMoyenneCompte > 0
              ? _noteMoyenneCompte.toStringAsFixed(1)
              : '—',
          label: 'Note moyenne ★',
          color: const Color(0xFFFFB830),
          icon: Icons.star_rounded,
        ),
      ),
    ]);
  }

  // ── Donut répartition statuts ──────────────────────────
  Widget _buildDonutStatuts() {
    final sections = [
      _DonutSection(label: 'Actives',     value: _nbActives.toDouble(),    color: const Color(0xFF25D366)),
      _DonutSection(label: 'Brouillons', value: _nbBrouillons.toDouble(), color: const Color(0xFFFFB800)),
      _DonutSection(label: 'Expirées',   value: _nbExpirees.toDouble(),   color: const Color(0xFF8A8A9A)),
    ].where((s) => s.value > 0).toList();

    if (sections.isEmpty) return const SizedBox.shrink();

    return _StatCard(
      title: 'Répartition des publications',
      child: SizedBox(
        height: 220,
        child: Row(children: [
          // Donut manuel (ou via votre sous-widget personnalisé _DonutChart)
          Expanded(
            flex: 3,
            child: _DonutChart(
              sections:      sections,
              total:         _total,
              touchedIndex:  _touchedDonutIndex,
              onTouch:       (i) => setState(() =>
                  _touchedDonutIndex = _touchedDonutIndex == i ? null : i),
            ),
          ),
          const SizedBox(width: 16),
          // Légende
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections.asMap().entries.map((e) {
                final touched = _touchedDonutIndex == e.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.all(touched ? 8 : 6),
                    decoration: BoxDecoration(
                      color: touched
                          ? e.value.color.withOpacity(0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: touched
                          ? Border.all(color: e.value.color.withOpacity(0.3))
                          : null,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() =>
                          _touchedDonutIndex = touched ? null : e.key),
                      child: Row(children: [
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(
                              color:        e.value.color,
                              borderRadius: BorderRadius.circular(3),
                            )),
                        const SizedBox(width: 8),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.label,
                                style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: touched
                                      ? FontWeight.w700 : FontWeight.w500,
                                  color:      touched
                                      ? e.value.color : AppColors.textSecondary,
                                )),
                            Text('${e.value.value.toInt()} pub${e.value.value > 1 ? "s" : ""}',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.textMuted)),
                          ],
                        )),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Barres catégories ──────────────────────────────────
  Widget _buildBarresCategories() {
    final cats = _topCategories;
    if (cats.isEmpty) return const SizedBox.shrink();
    
    final max = cats.first.value.toDouble();

    return _StatCard(
      title: 'Publications par catégorie',
      child: Column(
        children: cats.asMap().entries.map((e) {
          final touched = _touchedBarIndex == e.key;
          final ratio   = max > 0 ? e.value.value / max : 0.0;
          
          // Génération d'une couleur dégradée basée sur votre planCouleur
          final color   = HSLColor.fromColor(widget.planCouleur)
              .withLightness((0.45 + e.key * 0.05).clamp(0.0, 1.0))
              .toColor();

          return GestureDetector(
            onTap: () => setState(() =>
                _touchedBarIndex = touched ? null : e.key),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                SizedBox(
                  width: 72,
                  child: Text(e.value.key,
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: touched ? FontWeight.w600 : FontWeight.w400,
                        color: touched ? widget.planCouleur : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color:        AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 400),
                      curve:    Curves.easeOutCubic,
                      widthFactor: ratio,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: touched
                              ? color.withOpacity(0.9)
                              : color.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: touched ? [BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 6,
                          )] : null,
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  child: Text('${e.value.value}',
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: touched ? FontWeight.w700 : FontWeight.w400,
                        color:      touched ? widget.planCouleur : AppColors.textMuted,
                      ),
                      textAlign: TextAlign.right),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Jauge quota ───────────────────────────────────────
  Widget _buildJaugeQuota() {
    final max    = widget.planPubMax > 0 ? widget.planPubMax : 1;
    final ratio  = (_nbActives / max).clamp(0.0, 1.0);
    final pct    = (ratio * 100).round();
    final color  = ratio >= 1.0
        ? const Color(0xFFFF5252)
        : ratio >= 0.7
            ? const Color(0xFFFFB800)
            : const Color(0xFF25D366);

    return _StatCard(
      title: 'Quota de publications actives',
      child: Column(children: [
        Column(children: [
          Row(children: [
            Expanded(
              child: Stack(children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color:        AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 600),
                  curve:    Curves.easeOutCubic,
                  widthFactor: ratio,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color:        color,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [BoxShadow(
                        color: color.withOpacity(0.40),
                        blurRadius: 8,
                      )],
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Text('$pct%',
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      color,
                )),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text('$_nbActives actives',
                style: TextStyle(fontSize: 11, color: color,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('$max max (plan ${widget.abonnement?.plan.nom ?? "—"})',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ]),
        ]),

        // Détail par statut en bas de carte
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _MiniStat(value: '$_nbActives',    label: 'Actives',    color: const Color(0xFF25D366)),
          _MiniStat(value: '$_nbBrouillons', label: 'Brouillons', color: const Color(0xFFFFB800)),
          _MiniStat(value: '$_nbExpirees',   label: 'Expirées',   color: const Color(0xFF8A8A9A)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGETS UTILITAIRES STATS
// ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _StatCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: AppColors.divider),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12, offset: const Offset(0, 3))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color  color;
  final IconData icon;
  const _KpiCard({required this.value, required this.label,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          fontSize: 10, color: AppColors.textMuted,
          fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color  color;
  const _MiniStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(
      fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(
      fontSize: 10, color: AppColors.textMuted)),
  ]);
}

// ─────────────────────────────────────────────────────────
// DONUT CHART CUSTOM (sans package externe)
// ─────────────────────────────────────────────────────────
class _DonutSection {
  final String label;
  final double value;
  final Color  color;
  const _DonutSection({required this.label, required this.value, required this.color});
}

class _DonutChart extends StatelessWidget {
  final List<_DonutSection> sections;
  final int    total;
  final int?   touchedIndex;
  final void Function(int) onTouch;

  const _DonutChart({
    required this.sections,
    required this.total,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        // Détecter quelle section est touchée via l'angle
        final box    = context.findRenderObject() as RenderBox;
        final local  = box.globalToLocal(details.globalPosition);
        final center = Offset(box.size.width / 2, box.size.height / 2);
        final angle  = (local - center).direction; // -π à π
        final norm   = (angle + 2 * 3.14159) % (2 * 3.14159); // 0 à 2π
        double start = -3.14159 / 2; // -90°
        final sum    = sections.fold<double>(0, (s, e) => s + e.value);
        for (int i = 0; i < sections.length; i++) {
          final sweep  = sections[i].value / sum * 2 * 3.14159;
          final end    = start + sweep;
          final normS  = (start + 2 * 3.14159) % (2 * 3.14159);
          final normE  = (end   + 2 * 3.14159) % (2 * 3.14159);
          if ((normS <= normE && norm >= normS && norm <= normE) ||
              (normS >  normE && (norm >= normS || norm <= normE))) {
            onTouch(i);
            break;
          }
          start = end;
        }
      },
      child: CustomPaint(
        painter: _DonutPainter(
          sections:     sections,
          touchedIndex: touchedIndex,
          total:        total,
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$total',
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
            const Text('pubs',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSection> sections;
  final int? touchedIndex;
  final int  total;

  const _DonutPainter({
    required this.sections,
    required this.touchedIndex,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 8;
    const strokeW = 22.0;
    final sum    = sections.fold<double>(0, (s, e) => s + e.value);
    double start = -3.14159 / 2;

    for (int i = 0; i < sections.length; i++) {
      final sweep   = sections[i].value / sum * 2 * 3.14159;
      final touched = touchedIndex == i;
      final paint   = Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = touched ? strokeW + 6 : strokeW
        ..strokeCap   = StrokeCap.round
        ..color       = touched
            ? sections[i].color
            : sections[i].color.withOpacity(0.75);

      final r = touched ? radius + 2 : radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start, sweep - 0.06, false, paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.touchedIndex != touchedIndex;
}
// ═══════════════════════════════════════════════════════════
// STATS PAR PUBLICATION — VERSION CORRIGÉE & STABLE
// ═══════════════════════════════════════════════════════════
class _PubStatsPanel extends StatefulWidget {
  final List<PublicationGestion> publications;
  final Color                    planCouleur;

  const _PubStatsPanel({
    required this.publications,
    required this.planCouleur,
  });

  @override
  State<_PubStatsPanel> createState() => _PubStatsPanelState();
}

class _PubStatsPanelState extends State<_PubStatsPanel> {
  int    _pubIndex     = 0;
  int    _periodeIndex = 1;  // 0=jour 1=semaine 2=mois 3=an
  bool   _loadingStats = false;
  bool   _loadingAvis  = false;
  bool   _showAvis     = false;
  PubStats?       _stats;
  List<AvisPub>   _avis  = [];
  String?         _erreurStats;

  static const _periodes = ['Aujourd\'hui', 'Semaine', 'Mois', 'Année'];
  static const _periodeKeys = ['jour', 'semaine', 'mois', 'an'];

  PublicationGestion get _pubSelectionnee => widget.publications[_pubIndex];

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    if (widget.publications.isEmpty) return;
    final token = SessionManager().accessToken;
    if (token == null) return;

    setState(() { 
      _loadingStats = true; 
      _erreurStats = null; 
    });

    try {
      final stats = await ProfilService(token).statsPublication(_pubSelectionnee.id);
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreurStats = 'Impossible de charger les statistiques.';
          _loadingStats = false;
        });
      }
    }
  }

  Future<void> _chargerAvis() async {
    final token = SessionManager().accessToken;
    if (token == null) return;
    setState(() => _loadingAvis = true);
    try {
      final avis = await ProfilService(token).avisPublication(_pubSelectionnee.id);
      if (mounted) setState(() { _avis = avis; _loadingAvis = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAvis = false);
    }
  }

  void _changerPub(int index) {
    setState(() {
      _pubIndex = index;
      _stats    = null;
      _avis     = [];
      _showAvis = false;
    });
    _chargerStats();
  }

  List<PeriodePoint> get _serieActuelle {
    if (_stats == null) return [];
    switch (_periodeKeys[_periodeIndex]) {
      case 'jour':    return _stats!.parJour;
      case 'semaine': return _stats!.parSemaine;
      case 'mois':    return _stats!.parMois;
      case 'an':      return _stats!.parAn;
      default:        return _stats!.parSemaine;
    }
  }

  int get _avisPeriode => _serieActuelle.fold(0, (s, p) => s + p.avis);

  @override
  Widget build(BuildContext context) {
    final couleur = widget.planCouleur;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Row(children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text('Statistiques par publication',
              style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 14),

        _buildSelectorPub(couleur),
        const SizedBox(height: 16),

        _buildSelectorPeriode(couleur),
        const SizedBox(height: 16),

        if (_loadingStats)
          const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
        else if (_erreurStats != null)
          _ErreurStats(message: _erreurStats!, onRetry: _chargerStats)
        else if (_stats != null) ...[
          _buildKpisPeriode(couleur),
          const SizedBox(height: 16),

          _buildGraphiqueBarres(couleur),
          const SizedBox(height: 16),

          _buildNoteMoyenne(couleur),
          const SizedBox(height: 16),

          _buildBoutonAvis(couleur),

          if (_showAvis) ...[
            const SizedBox(height: 12),
            _buildListeAvis(),
          ],
        ],
      ],
    );
  }

  // Sélecteur de publication
  Widget _buildSelectorPub(Color couleur) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: widget.publications.asMap().entries.map((e) {
            final i = e.key;
            final pub = e.value;
            final sel = i == _pubIndex;
            return GestureDetector(
              onTap: () => _changerPub(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? couleur.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? couleur.withOpacity(0.4) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (pub.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(pub.imageUrl!, width: 28, height: 28, fit: BoxFit.cover),
                    )
                  else
                    Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.article_outlined, size: 14)),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 90, child: Text(pub.titre, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? couleur : AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                    Text('${pub.vues} vue${pub.vues > 1 ? "s" : ""}', style: TextStyle(fontSize: 9, color: sel ? couleur.withOpacity(0.7) : AppColors.textMuted)),
                  ]),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Sélecteur de période
  Widget _buildSelectorPeriode(Color couleur) {
    return Container(
      height: 38,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: _periodes.asMap().entries.map((e) {
          final sel = e.key == _periodeIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _periodeIndex = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel ? couleur.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: sel ? Border.all(color: couleur.withOpacity(0.35)) : null,
                ),
                child: Center(child: Text(e.value, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? couleur : AppColors.textMuted))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // KPIs
  Widget _buildKpisPeriode(Color couleur) {
    return Row(children: [
      Expanded(child: _MiniKpi(icon: Icons.visibility_outlined, label: 'Total vues', value: '${_stats!.vuesTotal}', color: couleur)),
      const SizedBox(width: 8),
      Expanded(child: _MiniKpi(icon: Icons.rate_review_outlined, label: 'Total avis', value: '${_stats!.avisTotal}', color: AppColors.primaryPink)),
      const SizedBox(width: 8),
      Expanded(child: _MiniKpi(icon: Icons.star_outline_rounded, label: 'Note moyenne', value: _stats!.noteMoyenne.toStringAsFixed(1), color: const Color(0xFFFFD700))),
    ]);
  }

  // Graphique Barres (corrigé)
  Widget _buildGraphiqueBarres(Color couleur) {
    final serie = _serieActuelle;
    if (serie.isEmpty) {
      return _StatCard(
        title: 'Évolution des avis — ${_periodes[_periodeIndex]}',
        child: const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('Aucune donnée pour cette période', style: TextStyle(color: AppColors.textMuted)))),
      );
    }

    final maxAvis = serie.map((p) => p.avis).reduce((a, b) => a > b ? a : b);

    return _StatCard(
      title: 'Évolution des avis — ${_periodes[_periodeIndex]}',
      child: SizedBox(
        height: 190,
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: serie.map((p) {
                  final ratio = maxAvis > 0 ? p.avis / maxAvis : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${p.avis}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFFFD700))),
                          const SizedBox(height: 4),
                          Flexible(
                            flex: (ratio * 100).round().clamp(8, 100),
                            child: Container(
                              decoration: BoxDecoration(
                                color: couleur.withOpacity(0.85),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(p.label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Note moyenne
  Widget _buildNoteMoyenne(Color couleur) {
    final note = _stats?.noteMoyenne ?? 0.0;
    return _StatCard(
      title: 'Note moyenne',
      child: Row(children: [
        Row(children: List.generate(5, (i) => Icon(i < note ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFFFD700), size: 24))),
        const SizedBox(width: 16),
        Text(note.toStringAsFixed(1), style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: couleur)),
        const Text(' / 5', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
      ]),
    );
  }

  // Bouton avis
  Widget _buildBoutonAvis(Color couleur) {
    return GestureDetector(
      onTap: () {
        setState(() => _showAvis = !_showAvis);
        if (_showAvis && _avis.isEmpty) _chargerAvis();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: couleur.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(Icons.rate_review_outlined, color: couleur),
          const SizedBox(width: 10),
          Expanded(child: Text(_showAvis ? 'Masquer les avis' : 'Voir les avis', style: TextStyle(color: couleur, fontWeight: FontWeight.w600))),
          Icon(_showAvis ? Icons.expand_less : Icons.expand_more, color: couleur),
        ]),
      ),
    );
  }

  // Liste des avis
  Widget _buildListeAvis() {
    if (_loadingAvis) return const Center(child: CircularProgressIndicator());
    if (_avis.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
        child: const Center(child: Text('Aucun avis pour le moment', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return Column(
      children: _avis.map((avis) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Row(children: List.generate(5, (i) => Icon(i < avis.note ? Icons.star_rounded : Icons.star_outline_rounded, size: 14, color: const Color(0xFFFFD700)))),
            const Spacer(),
            Text(avis.dateFormatee, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
          if (avis.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(avis.message, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
        ]),
      )).toList(),
    );
  }
}

// ── Mini KPI card ────────────────────────────────────────
class _MiniKpi extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _MiniKpi({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border:       Border.all(color: AppColors.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(
        fontSize: 10, color: AppColors.textMuted),
        overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ── Erreur avec retry ────────────────────────────────────
class _ErreurStats extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErreurStats({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color:        AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border:       Border.all(color: AppColors.divider),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.textMuted),
      const SizedBox(height: 8),
      Text(message,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: onRetry,
        child: const Text('Réessayer',
          style: TextStyle(color: AppColors.primaryPink,
            fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}