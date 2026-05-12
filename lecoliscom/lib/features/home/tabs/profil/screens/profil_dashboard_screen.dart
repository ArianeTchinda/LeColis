// lib/features/home/tabs/profil/screens/profil_dashboard_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '/core/models/escort_model.dart';
import '../widgets/image_editor_screen.dart';
import 'publication_form_screen.dart';

class ProfilDashboard extends StatefulWidget {
  final EscortModel  escort;
  final VoidCallback onDeconnexion;

  const ProfilDashboard({
    super.key,
    required this.escort,
    required this.onDeconnexion,
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

  // Plan mock
  final _planNom          = 'Standard';
  final _planCouleur      = Color(0xFF5DB8FF);
  final _planPubMax       = 3;
  final _planJoursRestants = 22;

  int get _nonLues    => _notifications.where((n) => !n.lue).length;
  int get _pubActives => _publications.where((p) => p.statut == StatutPublication.active).length;
  int get _totalVues  => _publications.fold(0, (s, p) => s + p.vues);

  @override
  void initState() {
    super.initState();
    _escort        = widget.escort;
    _publications  = List.from(mockPublicationsEscort);
    _notifications = List.from(mockNotifications);
    _searchCtrl.addListener(() {
      _searchQuery.value = _searchCtrl.text.trim().toLowerCase();
    });
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
            onPressed: () {
              setState(() => _publications.remove(pub));
              Navigator.pop(context);
              _snack('Publication supprimée', color: const Color(0xFFFF5252));
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
  }

  void _toggleActiver(PublicationGestion pub) {
    final peutActiver = _pubActives < _planPubMax;
    final estActive   = pub.statut == StatutPublication.active;
    if (!estActive && !peutActiver) {
      _snack('Limite de $_planPubMax publications atteinte pour le plan $_planNom.');
      return;
    }
    setState(() {
      final idx = _publications.indexOf(pub);
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
    _snack(estActive ? 'Publication désactivée' : 'Publication activée');
  }

  void _ajouterPublication() {
    if (_pubActives >= _planPubMax) {
      _snack('Limite de $_planPubMax publications atteinte pour le plan $_planNom.');
      return;
    }
    Navigator.push<PublicationFormResult>(
      context,
      MaterialPageRoute(builder: (_) => const PublicationFormScreen()),
    ).then((result) {
      if (result == null || !mounted) return;
      setState(() {
        _publications.insert(0, PublicationGestion(
          id:             'pg_${DateTime.now().millisecondsSinceEpoch}',
          titre:          result.titre,
          categorie:      result.categories.isNotEmpty
              ? result.categories.first : 'Autre',
          imageUrl:       result.imageUrls.isNotEmpty
              ? result.imageUrls.first : null,
          statut:         result.estDisponible
              ? StatutPublication.active
              : StatutPublication.brouillon,
          vues:           0,
          dateExpiration: DateTime.now().add(const Duration(days: 7)),
        ));
      });
      _snack('Publication créée !', color: const Color(0xFF25D366));
    });
  }

  // Ouvre l'éditeur d'image pour la photo de profil
  Future<void> _changerPhotoProfil() async {
    final bytes = await ouvrirEditeurImage(context);
    if (bytes != null) {
      setState(() => _photoProfilBytes = bytes);
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
  Widget build(BuildContext context) {
    final w         = MediaQuery.of(context).size.width;
    final isMobile  = w < 700;
    final isDesktop = w >= 1100;
    final hPad      = isDesktop ? 60.0 : isMobile ? 16.0 : 28.0;
    final gridCols  = isDesktop ? 4 : isMobile ? 3 : 3;

    return CustomScrollView(
      slivers: [
        // ── Bandeau profil style Instagram ──
        SliverToBoxAdapter(
          child: isMobile
              ? _buildMobileHeader(hPad)
              : _buildWideHeader(hPad, isDesktop),
        ),

        // ── Statistiques (publications / jours restants / vues) ──
        SliverToBoxAdapter(child: _buildStats(hPad, isMobile)),

        // ── Séparateur + titre section publications ──
        SliverToBoxAdapter(child: _buildPubsHeader(hPad)),

        // ── Grille de publications (filtrée par recherche) ──
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
                  padding: EdgeInsets.symmetric(
                      horizontal: hPad, vertical: 32),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.search_off_rounded,
                          size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        _publications.isEmpty
                            ? 'Aucune publication pour le moment.'
                            : 'Aucun résultat pour "$query".',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
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
                  crossAxisCount:   gridCols,
                  crossAxisSpacing: 8,
                  mainAxisSpacing:  8,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final pub = filtered[i];
                    final realIdx = _publications.indexOf(pub);
                    return _PubGridTile(
                      publication: pub,
                      onSupprimer: () => _supprimerPublication(pub),
                      onModifier: () {
                        Navigator.push<PublicationFormResult>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicationFormScreen(
                              existing: pub,
                            ),
                          ),
                        ).then((result) {
                          if (result == null || !mounted) return;
                          setState(() {
                            _publications[realIdx] = PublicationGestion(
                              id:             pub.id,
                              titre:          result.titre,
                              categorie:      result.categories.isNotEmpty
                                  ? result.categories.first : pub.categorie,
                              imageUrl:       result.imageUrls.isNotEmpty
                                  ? result.imageUrls.first : pub.imageUrl,
                              statut:         result.estDisponible
                                  ? StatutPublication.active
                                  : StatutPublication.brouillon,
                              vues:           pub.vues,
                              dateExpiration: pub.dateExpiration,
                            );
                          });
                          _snack('Publication mise à jour.',
                              color: const Color(0xFF5DB8FF));
                        });
                      },
                      onToggleActif: () => _toggleActiver(pub),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            );
          },
        ),
      ],
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
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
      child: Container(
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
              color: _planCouleur,
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

  const _PubGridTile({
    required this.publication,
    required this.onSupprimer,
    required this.onModifier,
    required this.onToggleActif,
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
                    ? Image.network(pub.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imgPlaceholder())
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
                    // Activer / désactiver
                    _TileAction(
                      icon:  actif
                          ? Icons.pause_circle_outline_rounded
                          : Icons.play_circle_outline_rounded,
                      color: actif
                          ? Colors.orange
                          : const Color(0xFF25D366),
                      onTap: onToggleActif,
                    ),
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
  final IconData icon; final Color color; final VoidCallback onTap;
  const _TileAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
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
  );
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

  @override
  void initState() {
    super.initState();
    _pseudoCtrl = TextEditingController(text: widget.escort.pseudo);
    _telCtrl = TextEditingController(text: widget.escort.telephone);
  }

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
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

          const SizedBox(height: 20),

          // Bouton sauvegarder
          GestureDetector(
            onTap: () {
              widget.onSave(
                EscortModel(
                  id: widget.escort.id,
                  pseudo: _pseudoCtrl.text.trim().isEmpty
                      ? widget.escort.pseudo
                      : _pseudoCtrl.text.trim(),
                  email: widget.escort.email,
                  telephone: _telCtrl.text.trim().isEmpty
                      ? widget.escort.telephone
                      : _telCtrl.text.trim(),
                  photoUrl: widget.escort.photoUrl,
                  estVerifie: widget.escort.estVerifie,
                  dateInscription: widget.escort.dateInscription,
                ),
              );
              Navigator.pop(context);
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