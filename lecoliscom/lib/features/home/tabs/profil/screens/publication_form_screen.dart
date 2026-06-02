// lib/features/home/tabs/profil/screens/publication_form_screen.dart
//
// Formulaire d'ajout / modification d'une publication.
// Utilisé depuis ProfilDashboard pour créer ou éditer.
// Structure : titre, description, catégories (multi-select),
//             localisation hiérarchique (pays→région→ville→quartier),
//             tarif, disponibilité, images (placeholder upload).

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/data/categories_data.dart';
import '../../../../../core/services/referentiel_service.dart';
import '../widgets/image_editor_screen.dart';
import '/core/models/escort_model.dart';
import '/core/services/profil_service.dart';
import '/core/models/publication_model.dart';
import '/core/models/categorie_model.dart';

// ─────────────────────────────────────────────────────────
// Résultat du formulaire — transmis au dashboard
// ─────────────────────────────────────────────────────────
class PublicationFormResult {
  final String       id;
  final String       titre;
  final String       description;
  final List<String> categories;
  final String       pays;
  final String       region;
  final String       ville;
  final String       quartier;
  final double?      tarif;
  final bool         estDisponible;
  final List<String> imageUrls;
  final DateTime     dateExpiration;
  final int          vues;

  const PublicationFormResult({
    required this.id,
    required this.titre,
    required this.description,
    required this.categories,
    required this.pays,
    required this.region,
    required this.ville,
    required this.quartier,
    this.tarif,
    required this.estDisponible,
    required this.imageUrls,
    required this.dateExpiration,
    required this.vues,
  });
}

// ─────────────────────────────────────────────────────────
// ÉCRAN PRINCIPAL
// ─────────────────────────────────────────────────────────
class PublicationFormScreen extends StatefulWidget {
  // null → création, non-null → modification (modèle simplifié pour la grille)
  final PublicationGestion? existing;

  // Modèle complet chargé depuis l'API (prioritaire sur [existing] en mode édition).
  // Permet de pré-remplir tous les champs, y compris les images MinIO.
  final PublicationModel? existingModel;

  const PublicationFormScreen({super.key, this.existing, this.existingModel});

  @override
  State<PublicationFormScreen> createState() => _PublicationFormScreenState();
}

class _PublicationFormScreenState extends State<PublicationFormScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titreCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _tarifCtrl   = TextEditingController();

  // Localisation
  String  _pays      = 'Cameroun';
  String  _region    = '';
  String  _ville     = '';
  String  _quartier  = '';

  // Catégories sélectionnées
  final Set<String> _categories = {};

  // Catégories chargées depuis l'API (groupes nom -> list<CategorieModel>)
  Map<String, List<CategorieModel>> _groupedCategories = {};
  Map<String, String> _categorieIdToName = {};

  // Localisation : listes chargées depuis l'API (avec id + nom)
  List<PaysRef>     _paysList      = [];
  List<RegionRef>   _regionsList   = [];
  List<VilleRef>    _villesList    = [];
  List<QuartierRef> _quartiersList = [];

  // Flags : true si la valeur saisie n'existe pas encore en BD
  bool _paysNouveau     = false;
  bool _regionNouveau   = false;
  bool _villeNouveau    = false;
  bool _quartierNouveau = false;

  // Disponibilité
  bool _estDisponible = true;

  bool _loading = false; // true pendant la soumission du formulaire

  // Images réseau déjà uploadées (MinIO) — on garde leurs URLs pour ne pas
  // les re-uploader si elles ne sont pas modifiées.
  // Structure : { 'url': String, 'bytes': Uint8List? }
  // Structure de chaque entrée :
  //   'id'       : ID Prisma (String?) — pour suppression backend
  //   'url'      : URL proxifiée (String) — pour affichage
  //   'bytes'    : Uint8List? — pour aperçu et éditeur
  //   'modifiee' : bool — false = réseau intacte, true = à uploader
  final List<Map<String, dynamic>> _imagesState = [];

  final List<String> _imagesToDelete = [];

  bool _loadingImages = false; // true pendant le téléchargement depuis MinIO

  bool get _estModification => widget.existing != null || widget.existingModel != null;
  String get _existingId => widget.existingModel?.id ?? widget.existing?.id ?? '';

  @override
void initState() {
  super.initState();

  final model = widget.existingModel;
  final e = widget.existing;

  if (model != null) {
  // MODE MODIFICATION - Données complètes
  _titreCtrl.text = model.titre;
  _descCtrl.text = model.description;
  _tarifCtrl.text = model.tarif != null ? model.tarif!.toInt().toString() : '';

  _estDisponible = model.estDisponible;
  _pays = model.pays.isNotEmpty ? model.pays : 'Cameroun';
  _region = model.region;
  _ville = model.ville;
  _quartier = model.quartier;

  // === CATÉGORIES - Correction importante ===
  if (model.categorie.isNotEmpty) {
    _categories.add(model.categorie); // fallback sur l'ancienne logique
  }

  // Meilleure récupération depuis le tableau categories (recommandé)
  // (À ajouter si tu veux être plus robuste dans le futur)
  // for (var cat in model.categories ?? []) {  // si tu ajoutes ce champ dans le model
  //   _categories.add(cat);
  // }

  // Images — on passe imageItems (id + url) pour pouvoir supprimer plus tard
  if (model.imageItems.isNotEmpty) {
    _loadingImages = true;
    _prechargerImagesReseau(model.imageItems);
  }
}
  else if (e != null) {
    // MODE CRÉATION ou fallback
    _titreCtrl.text = e.titre;
    _descCtrl.text = '';
    if (e.categorie.isNotEmpty) {
      _categories.add(e.categorie);
    }
    _pays = 'Cameroun';

    if (e.imageUrl != null && e.imageUrl!.isNotEmpty) {
      _imagesState.add({'url': e.imageUrl!, 'bytes': null});
    }
  }

  _loadReferentiel();
}

// Supprime une image de la liste (et la marque pour suppression côté backend plus tard)
void _supprimerImage(int index) {
  final entry = _imagesState[index];
  final imageId = entry['id'] as String?;   // On aura besoin de l'ID plus tard

  if (imageId != null && imageId.isNotEmpty) {
    _imagesToDelete.add(imageId);
  }

  setState(() {
    _imagesState.removeAt(index);
  });
}

  // Télécharge les images depuis MinIO et les stocke en bytes.
  // Chaque entrée contient :
  //   'id'       : ID Prisma (pour suppression)
  //   'url'      : URL proxifiée (pour affichage)
  //   'bytes'    : bytes (pour aperçu et éditeur)
  //   'modifiee' : false → image réseau intacte, ne pas re-uploader
  //                true  → image nouvelle ou éditée, à uploader
  Future<void> _prechargerImagesReseau(List<ImagePub> items) async {
    final List<Map<String, dynamic>> loaded = [];

    for (final item in items) {
      try {
        final res = await http.get(Uri.parse(item.url))
            .timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          loaded.add({
            'id':       item.id,
            'url':      item.url,
            'bytes':    res.bodyBytes,
            'modifiee': false,   // ← intacte : ne sera PAS re-uploadée
          });
        } else {
          loaded.add({
            'id':       item.id,
            'url':      item.url,
            'bytes':    null,
            'modifiee': false,
          });
        }
      } catch (_) {
        loaded.add({
          'id':       item.id,
          'url':      item.url,
          'bytes':    null,
          'modifiee': false,
        });
      }
    }

    if (mounted) {
      setState(() {
        _imagesState.clear();
        _imagesState.addAll(loaded);
        _loadingImages = false;
      });
    }
  }

  // Liste des bytes disponibles (pour l'aperçu et l'upload).
  // Null si l'image est réseau et non modifiée.
  List<Uint8List?> get _imagesBytesOuNull =>
      _imagesState.map((e) => e['bytes'] as Uint8List?).toList();

  Future<void> _loadReferentiel() async {
  try {
    // 1. Charger les catégories depuis l'API
    final grouped = await ReferentielService.getCategoriesGrouped();
    final map = <String, String>{};
    grouped.forEach((g, list) {
      for (final c in list) {
        map[c.id] = c.nom;
      }
    });

    setState(() {
      _groupedCategories = grouped;
      _categorieIdToName = map;
    });

    // 2. Pré-sélection des catégories (MULTI-CATÉGORIES)
    if (widget.existingModel != null) {
      final model = widget.existingModel!;

      // Priorité au tableau categories (le plus complet)
      if (model.categories.isNotEmpty) {
        for (final catName in model.categories) {
          if (catName.isEmpty) continue;

          final entry = map.entries.firstWhere(
            (e) => e.value.toLowerCase().trim() == catName.toLowerCase().trim(),
            orElse: () => const MapEntry('', ''),
          );

          if (entry.key.isNotEmpty) {
            _categories.add(entry.key);
          }
        }
      } 
      // Fallback sur l'ancienne propriété "categorie" (String)
      else if (model.categorie.isNotEmpty) {
        final entry = map.entries.firstWhere(
          (e) => e.value.toLowerCase().trim() == model.categorie.toLowerCase().trim(),
          orElse: () => const MapEntry('', ''),
        );
        if (entry.key.isNotEmpty) {
          _categories.add(entry.key);
        }
      }
    } 
    // Cas fallback pour PublicationGestion (ancien modèle)
    else if (widget.existing != null && widget.existing!.categorie.isNotEmpty) {
      final entry = map.entries.firstWhere(
        (e) => e.value.toLowerCase().trim() == widget.existing!.categorie.toLowerCase().trim(),
        orElse: () => const MapEntry('', ''),
      );
      if (entry.key.isNotEmpty) {
        _categories.add(entry.key);
      }
    }

    // 3. Charger les pays
    final paysRefs = await ProfilService.getPays();
    setState(() => _paysList = paysRefs);

    // 4. Cascade localisation pour la modification
    if (widget.existingModel != null) {
      final m = widget.existingModel!;
      if (m.region.isNotEmpty) {
        await _fetchRegionsForPaysWithValue(_pays, m.region);
      }
      if (m.ville.isNotEmpty) {
        await _fetchVillesForRegionWithValue(m.region, m.ville);
      }
      if (m.quartier.isNotEmpty) {
        await _fetchQuartiersForVilleWithValue(m.ville, m.quartier);
      }
    }
  } catch (e) {
    print('[PublicationForm] Erreur chargement référentiel: $e');
  }
}

  Future<void> _fetchRegionsForPays(String pays) async {
    try {
      final regs = await ProfilService.getRegions(pays);
      setState(() {
        _regionsList = regs;
        if (_regionsList.isNotEmpty &&
            !_regionsList.any((r) => r.nom == _region)) {
          _region = _regionsList.first.nom;
          _regionNouveau = false;
        }
      });
      if (_region.isNotEmpty) await _fetchVillesForRegion(_region);
    } catch (_) {}
  }

  Future<void> _fetchRegionsForPaysWithValue(String pays, String cibleRegion) async {
    try {
      final regs = await ProfilService.getRegions(pays);
      setState(() {
        _regionsList = regs;
        if (regs.any((r) => r.nom == cibleRegion)) {
          _region = cibleRegion;
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchVillesForRegionWithValue(String region, String cibleVille) async {
    try {
      final villes = await ProfilService.getVilles(region);
      setState(() {
        _villesList = villes;
        if (villes.any((v) => v.nom == cibleVille)) {
          _ville = cibleVille;
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchQuartiersForVilleWithValue(String ville, String cibleQuartier) async {
    try {
      final quartiers = await ProfilService.getQuartiers(ville);
      setState(() {
        _quartiersList = quartiers;
        if (quartiers.any((q) => q.nom == cibleQuartier)) {
          _quartier = cibleQuartier;
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchVillesForRegion(String region) async {
    try {
      final villes = await ProfilService.getVilles(region);
      setState(() {
        _villesList = villes;
        if (_villesList.isNotEmpty &&
            !_villesList.any((v) => v.nom == _ville)) {
          _ville = _villesList.first.nom;
          _villeNouveau = false;
        }
      });
      if (_ville.isNotEmpty) await _fetchQuartiersForVille(_ville);
    } catch (_) {}
  }

  Future<void> _fetchQuartiersForVille(String ville) async {
    try {
      final quartiers = await ProfilService.getQuartiers(ville);
      setState(() {
        _quartiersList = quartiers;
        if (_quartiersList.isNotEmpty &&
            !_quartiersList.any((q) => q.nom == _quartier)) {
          _quartier = _quartiersList.first.nom;
          _quartierNouveau = false;
        }
      });
    } catch (_) {}
  }

  // _sync* supprimées : la cascade est gérée par _fetchRegionsForPays,
  // _fetchVillesForRegion, _fetchQuartiersForVille (données API).

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _tarifCtrl.dispose();
    super.dispose();
  }

  void _submit() {
  if (!_formKey.currentState!.validate()) return;

  if (_categories.isEmpty) {
    _showError('Sélectionnez au moins une catégorie.');
    return;
  }

  if (_pays.trim().isEmpty) {
    _showError('Renseignez un pays.');
    return;
  }

  if (_ville.trim().isEmpty) {
    _showError('Renseignez une ville.');
    return;
  }

  if (_imagesState.isEmpty && !_estModification) {
    _showError('Ajoutez au moins une photo pour la publication.');
    return;
  }

  setState(() => _loading = true);

  (() async {
    if (!mounted) return;
    final token = SessionManager().accessToken;
    if (token == null) {
      _showError('Utilisateur non authentifié.');
      setState(() => _loading = false);
      return;
    }

    try {
      print('📤 Catégories envoyées (IDs): ${_categories.toList()}');

      String paysNomFinal     = _pays.trim();
      String regionNomFinal   = _region.trim();
      String villeNomFinal    = _ville.trim();
      String quartierNomFinal = _quartier.trim();
      String? quartierIdFinal;

      // Upsert localisation si nécessaire
      if (_paysNouveau && paysNomFinal.isNotEmpty) {
        await ProfilServiceUpsert.upsertPays(token, nom: paysNomFinal);
      }
      if (_regionNouveau && regionNomFinal.isNotEmpty) {
        await ProfilServiceUpsert.upsertRegion(
          token, nom: regionNomFinal, paysNom: paysNomFinal,
        );
      }
      if (_villeNouveau && villeNomFinal.isNotEmpty) {
        await ProfilServiceUpsert.upsertVille(
          token,
          nom: villeNomFinal,
          regionNom: regionNomFinal,
          paysNom: paysNomFinal,
        );
      }
      if (quartierNomFinal.isNotEmpty) {
        final qRef = await ProfilServiceUpsert.upsertQuartier(
          token,
          nom: quartierNomFinal,
          villeNom: villeNomFinal,
          regionNom: regionNomFinal,
          paysNom: paysNomFinal,
        );
        quartierIdFinal = qRef.id;
      }

      final svc = ProfilService(token);
      final tarifVal = double.tryParse(
          _tarifCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''));

      PublicationModel pub;

      // Images à uploader : uniquement celles marquées 'modifiee': true
      // Les images réseau intactes ('modifiee': false) ne sont PAS re-uploadées
      final newImages = _imagesState
          .where((e) => e['modifiee'] == true && e['bytes'] != null)
          .map((e) => e['bytes'] as Uint8List)
          .toList();

      if (_estModification) {
        // ── Détection "rien n'a changé" ──────────────────────────
        // On bloque seulement si AUCUNE des conditions suivantes n'est vraie :
        // - images supprimées
        // - nouvelles images / images éditées
        // On laisse toujours passer les changements de texte/catégorie/localisation
        // car ils sont difficiles à comparer proprement (et peu coûteux).
        // Le seul cas vraiment problématique était la duplication d'images.
        // ─────────────────────────────────────────────────────────

        print('🔄 Modification de la publication ID: $_existingId');
        print('   → images à uploader : ${newImages.length}');
        print('   → images à supprimer : ${_imagesToDelete.length}');

        pub = await svc.modifierPublication(
          _existingId,
          titre:          _titreCtrl.text.trim(),
          description:    _descCtrl.text.trim(),
          estDisponible:  _estDisponible,
          tarif:          tarifVal,
          quartierId:     quartierIdFinal,
          villeNom:       villeNomFinal,
          regionNom:      regionNomFinal,
          paysNom:        paysNomFinal,
          categorieIds:   _categories.toList(),
          imagesToDelete: _imagesToDelete,
        );

        // Upload uniquement des images nouvelles ou éditées
        if (newImages.isNotEmpty) {
          pub = await svc.ajouterImages(pub.id, newImages);
        }
      } else {
        print('➕ Création d\'une nouvelle publication');

        pub = await svc.creerPublication(
          titre:         _titreCtrl.text.trim(),
          description:   _descCtrl.text.trim(),
          estDisponible: _estDisponible,
          tarif:         tarifVal,
          quartierId:    quartierIdFinal,
          villeNom:      villeNomFinal,
          regionNom:     regionNomFinal,
          paysNom:       paysNomFinal,
          categorieIds:  _categories.toList(),
        );

        if (newImages.isNotEmpty) {
          pub = await svc.ajouterImages(pub.id, newImages);
        }
      }

      if (!mounted) return;

      final result = PublicationFormResult(
        id:             pub.id,
        titre:          pub.titre,
        description:    pub.description,
        categories:     pub.categories.isNotEmpty ? pub.categories : [pub.categorie],
        pays:           pub.pays,
        region:         pub.region,
        ville:          pub.ville,
        quartier:       pub.quartier,
        tarif:          pub.tarif,
        estDisponible:  pub.estDisponible,
        imageUrls:      pub.imageUrls,
        dateExpiration: pub.dateExpiration,
        vues:           pub.vues,
      );

      Navigator.pop(context, result);
      
      // Message de succès
      _scaffoldSuccess('Publication mise à jour avec succès !');

    } catch (e) {
      print('❌ Erreur lors de la soumission: $e');
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  })();
}

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _scaffoldSuccess(String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ),
  );
}

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final hPad   = isWide ? 40.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor:  AppColors.background,
        elevation:        0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _estModification ? 'Modifier la publication' : 'Nouvelle publication',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryPink))
                : GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5DA8), Color(0xFFB68DFF)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _estModification ? 'Enregistrer' : 'Publier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 48),
                    child: isWide
                        ? _buildWideLayout()
                        : _buildNarrowLayout(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Layout 2 colonnes (tablette/desktop) ─────────────

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne gauche : images + disponibilité
        SizedBox(
          width: 260,
          child: Column(children: [
            _ImagesSection(
              imagesState:    _imagesState,
              loadingImages:  _loadingImages,
              onAddImage:     _ajouterImage,
              onEditImage:    _modifierImage,
              onRemove:       _supprimerImage,
            ),
            const SizedBox(height: 16),
            _DisponibiliteToggle(
              value:     _estDisponible,
              onChanged: (v) => setState(() => _estDisponible = v),
            ),
          ]),
        ),
        const SizedBox(width: 24),
        // Colonne droite : tous les champs texte
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildFormFields(),
          ),
        ),
      ],
    );
  }

  // ── Layout 1 colonne (mobile) ─────────────────────────

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ImagesSection(
          imagesState:    _imagesState,
          loadingImages:  _loadingImages,
          onAddImage:     _ajouterImage,
          onEditImage:    _modifierImage,
          onRemove:       _supprimerImage,
        ),
        const SizedBox(height: 16),
        ..._buildFormFields(),
        const SizedBox(height: 16),
        _DisponibiliteToggle(
          value:     _estDisponible,
          onChanged: (v) => setState(() => _estDisponible = v),
        ),
      ],
    );
  }

  // ── Champs communs ────────────────────────────────────

  List<Widget> _buildFormFields() {
    return [
      // Titre
      _SectionLabel('Titre de l\'annonce'),
      const SizedBox(height: 8),
      _FormField(
        controller: _titreCtrl,
        hint:       'Ex: Disponible ce soir à Bastos',
        maxLength:  80,
        validator:  (v) {
          if (v == null || v.trim().length < 5) return '5 caractères minimum';
          return null;
        },
      ),

      const SizedBox(height: 18),

      // Description
      _SectionLabel('Description'),
      const SizedBox(height: 8),
      _FormField(
        controller: _descCtrl,
        hint:       'Décrivez vos services, disponibilités, conditions…',
        maxLines:   5,
        maxLength:  600,
        validator:  (v) {
          if (v == null || v.trim().length < 20) return '20 caractères minimum';
          return null;
        },
      ),

      const SizedBox(height: 18),

      // Catégories
      _SectionLabel('Catégories'),
      const SizedBox(height: 4),
      const Text(
        'Sélectionnez les catégories qui correspondent à votre profil.',
        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
      const SizedBox(height: 10),
      _CategoriesSelector(
        selected:  _categories,
        groupedCategories: _groupedCategories,
        categorieIdToName: _categorieIdToName,
        onToggle:  (catId) => setState(() {
          if (_categories.contains(catId)) {
            _categories.remove(catId);
          } else {
            _categories.add(catId);
          }
        }),
      ),

      const SizedBox(height: 18),

      // Localisation
      _SectionLabel('Localisation'),
      const SizedBox(height: 4),
      const Text(
        'Saisissez votre localisation. Si elle n\'existe pas encore, elle sera créée automatiquement.',
        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
      const SizedBox(height: 8),
      _LocalisationAutocomplete(
        pays:          _pays,
        region:        _region,
        ville:         _ville,
        quartier:      _quartier,
        paysList:      _paysList.map((p) => p.nom).toList(),
        regionsList:   _regionsList.map((r) => r.nom).toList(),
        villesList:    _villesList.map((v) => v.nom).toList(),
        quartiersList: _quartiersList.map((q) => q.nom).toList(),
        onPays: (v, estNouveau) {
          setState(() {
            _pays         = v;
            _paysNouveau  = estNouveau;
            _region       = '';   _regionNouveau   = false;
            _ville        = '';   _villeNouveau    = false;
            _quartier     = '';   _quartierNouveau = false;
            _regionsList  = [];
            _villesList   = [];
            _quartiersList = [];
          });
          if (!estNouveau) _fetchRegionsForPays(v);
        },
        onRegion: (v, estNouveau) {
          setState(() {
            _region        = v;
            _regionNouveau = estNouveau;
            _ville         = '';  _villeNouveau    = false;
            _quartier      = '';  _quartierNouveau = false;
            _villesList    = [];
            _quartiersList = [];
          });
          if (!estNouveau) _fetchVillesForRegion(v);
        },
        onVille: (v, estNouveau) {
          setState(() {
            _ville         = v;
            _villeNouveau  = estNouveau;
            _quartier      = '';  _quartierNouveau = false;
            _quartiersList = [];
          });
          if (!estNouveau) _fetchQuartiersForVille(v);
        },
        onQuartier: (v, estNouveau) => setState(() {
          _quartier        = v;
          _quartierNouveau = estNouveau;
        }),
      ),

      const SizedBox(height: 18),

      // Tarif
      _SectionLabel('Tarif (FCFA) — optionnel'),
      const SizedBox(height: 8),
      _FormField(
        controller: _tarifCtrl,
        hint:       'Ex: 25000',
        keyboard:   TextInputType.number,
      ),
    ];
  }

  Future<void> _ajouterImage() async {
    if (_imagesState.length >= 6) {
      _showError('Maximum 6 images par publication.');
      return;
    }
    final bytes = await ouvrirEditeurImage(context);
    if (bytes != null) {
      setState(() => _imagesState.add({
        'id':       '',     // pas encore d'ID (nouvelle image)
        'url':      '',
        'bytes':    bytes,
        'modifiee': true,   // ← nouvelle image : à uploader
      }));
    }
  }

  Future<void> _modifierImage(int index) async {
  final entry = _imagesState[index];
  final String url = entry['url'] as String? ?? '';
  final Uint8List? currentBytes = entry['bytes'] as Uint8List?;

  Uint8List? imageInitiale = currentBytes;

  // Si c'est une image existante (venue de MinIO) et qu'on n'a pas encore les bytes
  if (imageInitiale == null && url.isNotEmpty) {
    try {
      print('📥 Téléchargement de l\'image existante pour édition...');
      final res = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        imageInitiale = res.bodyBytes;
      }
    } catch (e) {
      print('⚠️ Impossible de télécharger l\'image pour édition: $e');
    }
  }

  // Ouvrir l'éditeur avec l'image actuelle
  final bytes = await ouvrirEditeurImage(
    context, 
    imageInitiale: imageInitiale
  );

  if (bytes != null) {
    setState(() {
      _imagesState[index] = {
        'id':       entry['id'] ?? '',   // on garde l'ID pour pouvoir supprimer l'ancienne dans MinIO
        'url':      url,                 // on garde l'URL de l'originale
        'bytes':    bytes,               // nouvelle version éditée
        'modifiee': true,                // ← éditée : à re-uploader
      };
    });
  }
}
}

// ═══════════════════════════════════════════════════════
// SECTION IMAGES
// ═══════════════════════════════════════════════════════
class _ImagesSection extends StatelessWidget {
  // Liste d'états images : {'url': String, 'bytes': Uint8List?, 'id': String?}
  final List<Map<String, dynamic>> imagesState;
  final bool loadingImages;
  final VoidCallback onAddImage;
  final void Function(int) onEditImage;
  final void Function(int) onRemove;

  const _ImagesSection({
    required this.imagesState,
    required this.loadingImages,
    required this.onAddImage,
    required this.onEditImage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Photos (max 6)'),
        const SizedBox(height: 4),
        const Text(
          'La première photo sera la vignette principale. Appuyez sur une photo pour la modifier.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),

        if (loadingImages)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: const [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryPink),
              ),
              SizedBox(width: 8),
              Text('Chargement des photos…',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          itemCount: imagesState.length + (imagesState.length < 6 ? 1 : 0),
          itemBuilder: (_, i) {
            // Bouton "Ajouter"
            if (i == imagesState.length) {
              return GestureDetector(
                onTap: onAddImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryPink.withOpacity(0.35)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_photo_alternate_rounded,
                          color: AppColors.primaryPink, size: 26),
                      SizedBox(height: 6),
                      Text('Ajouter',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryPink,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }

            // Image existante
            final entry = imagesState[i];
            final bytes = entry['bytes'] as Uint8List?;
            final url = entry['url'] as String? ?? '';

            // Widget image
            Widget imageWidget;
            if (bytes != null) {
              imageWidget = Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            } else if (url.isNotEmpty) {
              imageWidget = Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.grey),
              );
            } else {
              imageWidget = const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                // Image cliquable
                GestureDetector(
                  onTap: () => onEditImage(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageWidget,
                  ),
                ),

                // Badge "Cover" sur la première image
                if (i == 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Cover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Bouton Modifier
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: GestureDetector(
                    onTap: () => onEditImage(i),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),

                // Bouton Supprimer
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => onRemove(i),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}


// ═══════════════════════════════════════════════════════
// SÉLECTEUR DE CATÉGORIES (par groupes, expansible)
// ═══════════════════════════════════════════════════════
class _CategoriesSelector extends StatefulWidget {
  final Set<String>                    selected;
  final Map<String, List<CategorieModel>> groupedCategories;
  final Map<String, String>            categorieIdToName;
  final void Function(String)          onToggle;

  const _CategoriesSelector({
    required this.selected,
    required this.groupedCategories,
    required this.categorieIdToName,
    required this.onToggle,
  });

  @override
  State<_CategoriesSelector> createState() => _CategoriesSelectorState();
}

class _CategoriesSelectorState extends State<_CategoriesSelector> {
  final Set<String> _expandedGroups = {'Morphologie', 'Âge'};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.groupedCategories.entries.map((entry) {
        final groupeNom = entry.key;
        final cats = entry.value;
        final isExpanded = _expandedGroups.contains(groupeNom);
        final selectedInGroup = cats.where((c) => widget.selected.contains(c.id)).length;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(
              color: selectedInGroup > 0
                  ? AppColors.primaryPink.withOpacity(0.35)
                  : AppColors.divider,
            ),
          ),
          child: Column(children: [
            // En-tête groupe
            GestureDetector(
              onTap: () => setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(groupeNom);
                } else {
                  _expandedGroups.add(groupeNom);
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                child: Row(children: [
                    Text(groupeNom,
                      style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color: selectedInGroup > 0
                              ? AppColors.primaryPink
                              : AppColors.textPrimary)),
                  if (selectedInGroup > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:        AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$selectedInGroup',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size:  18,
                    color: AppColors.textMuted,
                  ),
                ]),
              ),
            ),
            // Chips catégories
            if (isExpanded) ...[
              const Divider(
                  color: AppColors.divider, height: 1,
                  indent: 14, endIndent: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Wrap(
                  spacing:     8,
                  runSpacing:  8,
                  children: cats.map((cat) {
                    final sel = widget.selected.contains(cat.id);
                    return GestureDetector(
                      onTap: () => widget.onToggle(cat.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:        sel
                              ? AppColors.primaryPink.withOpacity(0.15)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border:       Border.all(
                            color: sel
                                ? AppColors.primaryPink.withOpacity(0.5)
                                : AppColors.divider,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(cat.nom,
                            style: TextStyle(
                                fontSize:   12,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: sel
                                    ? AppColors.primaryPink
                                    : AppColors.textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ]),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SÉLECTEUR DE LOCALISATION — bottom sheet + ajout inline
// ═══════════════════════════════════════════════════════
// Chaque niveau (pays → région → ville → quartier) :
//   • Affiche la valeur sélectionnée dans un champ tappable
//   • Ouvre un bottom sheet avec liste filtrée + barre de recherche
//   • Si la recherche ne trouve rien → bouton "+ Créer"
//   • Cascade automatique : changer pays vide région/ville/quartier
// ─────────────────────────────────────────────────────────
class _LocalisationAutocomplete extends StatelessWidget {
  final String pays, region, ville, quartier;
  final List<String> paysList, regionsList, villesList, quartiersList;
  // callback(valeur, estNouveau)
  final void Function(String, bool) onPays, onRegion, onVille, onQuartier;

  const _LocalisationAutocomplete({
    required this.pays,
    required this.region,
    required this.ville,
    required this.quartier,
    required this.paysList,
    required this.regionsList,
    required this.villesList,
    required this.quartiersList,
    required this.onPays,
    required this.onRegion,
    required this.onVille,
    required this.onQuartier,
  });

  Future<void> _ouvrir(
    BuildContext context, {
    required String label,
    required List<String> options,
    required String valeurActuelle,
    required void Function(String, bool) onSelect,
    required bool enabled,
  }) async {
    if (!enabled) return;
    final choix = await showModalBottomSheet<_LocalisationChoix>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _LocalisationSheet(
        label:         label,
        options:       options,
        valeurActuelle: valeurActuelle,
      ),
    );
    if (choix != null) {
      onSelect(choix.valeur, choix.estNouveau);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Column(children: [
        // Ligne 1 : Pays + Région
        Row(children: [
          Expanded(child: _LocalisationField(
            label:         'Pays',
            valeur:        pays,
            estNouveau:    pays.isNotEmpty && !paysList.contains(pays),
            enabled:       true,
            hint:          'Sélectionner…',
            onTap: () => _ouvrir(context,
              label:         'Pays',
              options:       paysList,
              valeurActuelle: pays,
              onSelect:      onPays,
              enabled:       true,
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: _LocalisationField(
            label:         'Région',
            valeur:        region,
            estNouveau:    region.isNotEmpty && !regionsList.contains(region),
            enabled:       pays.isNotEmpty,
            hint:          pays.isEmpty ? '— d\'abord un pays' : 'Sélectionner…',
            onTap: () => _ouvrir(context,
              label:         'Région',
              options:       regionsList,
              valeurActuelle: region,
              onSelect:      onRegion,
              enabled:       pays.isNotEmpty,
            ),
          )),
        ]),
        const SizedBox(height: 10),
        // Ligne 2 : Ville + Quartier
        Row(children: [
          Expanded(child: _LocalisationField(
            label:         'Ville',
            valeur:        ville,
            estNouveau:    ville.isNotEmpty && !villesList.contains(ville),
            enabled:       region.isNotEmpty,
            hint:          region.isEmpty ? '— d\'abord une région' : 'Sélectionner…',
            onTap: () => _ouvrir(context,
              label:         'Ville',
              options:       villesList,
              valeurActuelle: ville,
              onSelect:      onVille,
              enabled:       region.isNotEmpty,
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: _LocalisationField(
            label:         'Quartier (opt.)',
            valeur:        quartier,
            estNouveau:    quartier.isNotEmpty && !quartiersList.contains(quartier),
            enabled:       ville.isNotEmpty,
            hint:          ville.isEmpty ? '— d\'abord une ville' : 'Optionnel',
            onTap: () => _ouvrir(context,
              label:         'Quartier',
              options:       quartiersList,
              valeurActuelle: quartier,
              onSelect:      onQuartier,
              enabled:       ville.isNotEmpty,
            ),
          )),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Champ tappable affichant la valeur sélectionnée
// ─────────────────────────────────────────────────────────
class _LocalisationField extends StatelessWidget {
  final String      label;
  final String      valeur;
  final bool        estNouveau;
  final bool        enabled;
  final String      hint;
  final VoidCallback onTap;

  const _LocalisationField({
    required this.label,
    required this.valeur,
    required this.estNouveau,
    required this.enabled,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = valeur.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        )),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.surfaceElevated
                  : AppColors.surfaceElevated.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: estNouveau
                    ? AppColors.primaryPink.withOpacity(0.5)
                    : AppColors.divider,
                width: estNouveau ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  hasValue ? valeur : hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasValue
                        ? (estNouveau
                            ? AppColors.primaryPink
                            : AppColors.textPrimary)
                        : AppColors.textMuted,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (estNouveau) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryPink.withOpacity(0.4)),
                  ),
                  child: const Text('Nouveau', style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.primaryPink,
                  )),
                ),
              ] else ...[
                const SizedBox(width: 6),
                Icon(
                  enabled ? Icons.expand_more_rounded : Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Résultat renvoyé par le bottom sheet
// ─────────────────────────────────────────────────────────
class _LocalisationChoix {
  final String valeur;
  final bool   estNouveau;
  const _LocalisationChoix(this.valeur, {required this.estNouveau});
}

// ─────────────────────────────────────────────────────────
// Bottom sheet : liste filtrée + barre de recherche + "+ Créer"
// ─────────────────────────────────────────────────────────
class _LocalisationSheet extends StatefulWidget {
  final String       label;
  final List<String> options;
  final String       valeurActuelle;

  const _LocalisationSheet({
    required this.label,
    required this.options,
    required this.valeurActuelle,
  });

  @override
  State<_LocalisationSheet> createState() => _LocalisationSheetState();
}

class _LocalisationSheetState extends State<_LocalisationSheet> {
  final _searchCtrl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.options);
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _norm(String s) {
    const acc = {
      'à':'a','â':'a','ä':'a','é':'e','è':'e','ê':'e','ë':'e',
      'î':'i','ï':'i','ô':'o','ö':'o','ù':'u','û':'u','ü':'u','ç':'c',
      'À':'a','Â':'a','Ä':'a','É':'e','È':'e','Ê':'e','Ë':'e',
      'Î':'i','Ï':'i','Ô':'o','Ö':'o','Ù':'u','Û':'u','Ü':'u','Ç':'c',
    };
    return s.trim().toLowerCase().splitMapJoin(
      RegExp('.'),
      onMatch:    (m) => acc[m.group(0)] ?? m.group(0)!,
      onNonMatch: (n) => n,
    );
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _filtered = List.from(widget.options));
      return;
    }
    final nq = _norm(q);
    final exact    = <String>[];
    final debut    = <String>[];
    final contient = <String>[];
    for (final o in widget.options) {
      final no = _norm(o);
      if (no == nq)              exact.add(o);
      else if (no.startsWith(nq)) debut.add(o);
      else if (no.contains(nq))   contient.add(o);
    }
    setState(() => _filtered = [...exact, ...debut, ...contient]);
  }

  bool get _saisieEstNouveau {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return false;
    final nq = _norm(q);
    return !widget.options.any((o) => _norm(o) == nq);
  }

  @override
  Widget build(BuildContext context) {
    final saisie = _searchCtrl.text.trim();

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Poignée
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 6),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Titre
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            Text(
              'Choisir : ${widget.label}',
              style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close_rounded,
                  size: 20, color: AppColors.textMuted),
            ),
          ]),
        ),
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color:        AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller:  _searchCtrl,
              autofocus:   true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText:  'Rechercher ou saisir ${widget.label.toLowerCase()}…',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textMuted),
                border:         InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        // Liste des résultats
        Expanded(
          child: ListView.builder(
            itemCount: _filtered.length + (_saisieEstNouveau && saisie.isNotEmpty ? 1 : 0),
            itemBuilder: (_, i) {
              // Bouton "+ Créer" en dernier si nouvelle valeur
              if (i == _filtered.length) {
                return InkWell(
                  onTap: () => Navigator.pop(
                    context,
                    _LocalisationChoix(saisie, estNouveau: true),
                  ),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color:        AppColors.primaryPink.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:       Border.all(
                          color: AppColors.primaryPink.withOpacity(0.3),
                          width: 1.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 18, color: AppColors.primaryPink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13),
                            children: [
                              const TextSpan(
                                text: 'Créer « ',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                              TextSpan(
                                text: saisie,
                                style: const TextStyle(
                                  color:      AppColors.primaryPink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(
                                text: ' »',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Nouveau',
                            style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w700,
                                color: AppColors.primaryPink)),
                      ),
                    ]),
                  ),
                );
              }

              // Entrée normale depuis la BD
              final opt = _filtered[i];
              final sel = opt == widget.valeurActuelle;
              return InkWell(
                onTap: () => Navigator.pop(
                  context,
                  _LocalisationChoix(opt, estNouveau: false),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 13),
                  color: sel
                      ? AppColors.primaryPink.withOpacity(0.07)
                      : Colors.transparent,
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(opt, style: TextStyle(
                        fontSize:   13,
                        color:      sel
                            ? AppColors.primaryPink
                            : AppColors.textPrimary,
                        fontWeight: sel
                            ? FontWeight.w600
                            : FontWeight.w400,
                      )),
                    ),
                    if (sel)
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.primaryPink),
                  ]),
                ),
              );
            },
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════
// DISPONIBILITÉ TOGGLE
// ═══════════════════════════════════════════════════════
class _DisponibiliteToggle extends StatelessWidget {
  final bool                  value;
  final void Function(bool)   onChanged;

  const _DisponibiliteToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
          color: value
              ? const Color(0xFF25D366).withOpacity(0.35)
              : AppColors.divider,
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? const Color(0xFF25D366).withOpacity(0.12)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            value
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            size:  18,
            color: value
                ? const Color(0xFF25D366)
                : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Disponible maintenant',
                style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      AppColors.textPrimary)),
            Text(
              value
                  ? 'Votre annonce sera marquée disponible'
                  : 'Votre annonce sera marquée indisponible',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ]),
        ),
        Switch(
          value:            value,
          onChanged:        onChanged,
          activeColor:      const Color(0xFF25D366),
          activeTrackColor: const Color(0xFF25D366).withOpacity(0.25),
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: AppColors.divider,
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
// WIDGETS UTILITAIRES
// ═══════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize:   13,
        fontWeight: FontWeight.w600,
        color:      AppColors.textSecondary),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final int                        maxLines;
  final int?                       maxLength;
  final TextInputType              keyboard;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLines  = 1,
    this.maxLength,
    this.keyboard  = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   controller,
    maxLines:     maxLines,
    maxLength:    maxLength,
    keyboardType: keyboard,
    validator:    validator,
    style: const TextStyle(
        color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText:       hint,
      hintStyle:      const TextStyle(
          color: AppColors.textMuted, fontSize: 13),
      filled:         true,
      fillColor:      AppColors.surface,
      counterStyle:   const TextStyle(
          color: AppColors.textMuted, fontSize: 11),
      errorStyle:     const TextStyle(
          color: Color(0xFFFF5252), fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 13),
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
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF5252))),
    ),
  );
}