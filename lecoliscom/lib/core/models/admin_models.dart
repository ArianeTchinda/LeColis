// lib/core/models/admin_models.dart

import 'package:flutter/material.dart';
import 'escort_model.dart';
import 'abonnement_model.dart';
import 'transaction_model.dart';
import '../services/admin_service.dart';

// ─────────────────────────────────────────────────────────
// SESSION ADMIN (singleton)
// ─────────────────────────────────────────────────────────
class AdminSession extends ChangeNotifier {
  static final AdminSession _instance = AdminSession._internal();
  factory AdminSession() => _instance;
  AdminSession._internal();

  final AdminService _service = AdminService();

  bool    _connecte = false;
  String? _erreur;
  Map<String, dynamic>? _admin; // { id, email, nom }

  bool    get estConnecte => _connecte;
  String? get erreur      => _erreur;
  Map<String, dynamic>? get admin => _admin;

  Future<bool> connecter(String email, String motDePasse) async {
    _erreur = null;
    final res = await _service.login(email, motDePasse);
    if (res['success'] == true) {
      _connecte = true;
      _admin    = res['admin'] as Map<String, dynamic>?;
      notifyListeners();
      return true;
    }
    _erreur = res['message'] ?? 'Identifiants incorrects.';
    notifyListeners();
    return false;
  }

  Future<void> deconnecter() async {
    await _service.logout();
    _connecte = false;
    _admin    = null;
    _erreur   = null;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────
// TYPE DE SANCTION
// ─────────────────────────────────────────────────────────
enum TypeSanction { avertissement, blocageTemporaire, bannissement }

extension TypeSanctionExt on TypeSanction {
  String get label {
    switch (this) {
      case TypeSanction.avertissement:     return 'Avertissement';
      case TypeSanction.blocageTemporaire: return 'Blocage temporaire';
      case TypeSanction.bannissement:      return 'Bannissement';
    }
  }

  Color get couleur {
    switch (this) {
      case TypeSanction.avertissement:     return const Color(0xFFFFB800);
      case TypeSanction.blocageTemporaire: return const Color(0xFFFF6600);
      case TypeSanction.bannissement:      return const Color(0xFFFF5252);
    }
  }

  IconData get icone {
    switch (this) {
      case TypeSanction.avertissement:     return Icons.warning_amber_rounded;
      case TypeSanction.blocageTemporaire: return Icons.lock_clock_rounded;
      case TypeSanction.bannissement:      return Icons.block_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────
// SANCTION
// ─────────────────────────────────────────────────────────
class Sanction {
  final String       id;
  final String       escortId;
  final TypeSanction type;
  final String       motif;
  final DateTime     dateDebut;
  final DateTime?    dateFin;   // null = permanent (bannissement)
  final String       adminId;
  bool               active;

  Sanction({
    required this.id,
    required this.escortId,
    required this.type,
    required this.motif,
    required this.dateDebut,
    this.dateFin,
    required this.adminId,
    this.active = true,
  });
}

// ─────────────────────────────────────────────────────────
// STATUT SIGNALEMENT
// ─────────────────────────────────────────────────────────
enum StatutSignalement { enAttente, traite, ignore }

extension StatutSignalementExt on StatutSignalement {
  String get label {
    switch (this) {
      case StatutSignalement.enAttente: return 'En attente';
      case StatutSignalement.traite:    return 'Traité';
      case StatutSignalement.ignore:    return 'Ignoré';
    }
  }

  Color get couleur {
    switch (this) {
      case StatutSignalement.enAttente: return const Color(0xFFFFB800);
      case StatutSignalement.traite:    return const Color(0xFF25D366);
      case StatutSignalement.ignore:    return const Color(0xFF8A8A9A);
    }
  }
}

// ─────────────────────────────────────────────────────────
// SIGNALEMENT
// ─────────────────────────────────────────────────────────
class SignalementAdmin {
  final String  id;
  final String  escortId;
  final String  escortPseudo;
  final String  motif;
  final String? description;
  // Titre de la publication signalée (null si le signalement est direct sur le compte)
  final String? titrePublication;
  final DateTime date;
  StatutSignalement statut;

  SignalementAdmin({
    required this.id,
    required this.escortId,
    required this.escortPseudo,
    this.description,
    this.titrePublication,
    required this.motif,
    required this.date,
    this.statut = StatutSignalement.enAttente,
  });

  /// Le backend renvoie :
  /// { id, motif, description, statut, createdAt,
  ///   escortSignalee: { id, pseudo, photoUrl },
  ///   publication: { id, titre } | null }
  factory SignalementAdmin.fromJson(Map<String, dynamic> j) {
    StatutSignalement parseStatut(String? s) {
      switch ((s ?? '').toUpperCase()) {
        case 'TRAITE':    return StatutSignalement.traite;
        case 'IGNORE':    return StatutSignalement.ignore;
        case 'EN_ATTENTE':
        default:          return StatutSignalement.enAttente;
      }
    }

    final escortSignalee  = j['escortSignalee']  as Map<String, dynamic>? ?? {};
    final publicationData = j['publication']      as Map<String, dynamic>?;

    return SignalementAdmin(
      id:                j['id']?.toString() ?? '',
      escortId:          escortSignalee['id']?.toString()
                         ?? j['escortId']?.toString() ?? '',
      escortPseudo:      escortSignalee['pseudo']
                         ?? j['escortPseudo'] ?? 'Inconnu',
      motif:             j['motif'] ?? '',
      description:       j['description'],
      // Titre de la publication si le signalement porte sur une publication
      titrePublication:  publicationData?['titre'],
      date:              DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      statut:            parseStatut(j['statut']),
    );
  }
}

// ─────────────────────────────────────────────────────────
// COMPTE ESCORT VU PAR L'ADMIN
// ─────────────────────────────────────────────────────────
class CompteEscortAdmin {
  final EscortModel            escort;
  final AbonnementSouscrit?    abonnementActif;
  final List<TransactionModel> transactions;
  final List<SignalementAdmin> signalements;
  final List<Sanction>         sanctions;
  final int                    nbPublications;
  final int                    nbVues;
  bool                         estBloque;
  bool                         estBanni;

  CompteEscortAdmin({
    required this.escort,
    this.abonnementActif,
    this.transactions   = const [],
    this.signalements   = const [],
    this.sanctions      = const [],
    this.nbPublications = 0,
    this.nbVues         = 0,
    this.estBloque      = false,
    this.estBanni       = false,
  });

  /// Le backend (GET /admin/escorts) renvoie les champs à plat :
  /// { id, pseudo, email, telephone, photoUrl, estVerifie, estBloque,
  ///   estBanni, createdAt,
  ///   abonnementActif: { id, plan:{...}, dateFin, statut, createdAt,
  ///                      nbPublicationsAdm } | null,
  ///   stats: { publications: N, transactions: N, signalements: N, vues: N } }
  factory CompteEscortAdmin.fromJson(Map<String, dynamic> j) {
    // ── EscortModel — champs à plat (pas d'objet imbriqué ici) ──
    final escort = EscortModel.fromJsonAdmin(j);

    // ── Abonnement actif ──
    AbonnementSouscrit? abonnement;
    final abData = j['abonnementActif'];
    if (abData != null) {
      try {
        // Le backend n'envoie pas quotaUtilise/quotaRestant ici
        // On construit un AbonnementSouscrit minimal
        abonnement = AbonnementSouscrit(
          id:               abData['id']?.toString() ?? '',
          plan:             PlanAbonnement.fromJson(abData['plan'] as Map<String, dynamic>),
          dateDebut:        DateTime.tryParse(abData['createdAt'] ?? '') ?? DateTime.now(),
          dateFin:          DateTime.tryParse(abData['dateFin'] ?? '') ?? DateTime.now(),
          statut:           abData['statut'] ?? 'ACTIF',
          nbPublicationsAdm: abData['nbPublicationsAdm'],
          quotaTotal:       abData['nbPublicationsAdm'] ?? 0,
          quotaUtilise:     0,
          quotaRestant:     abData['nbPublicationsAdm'] ?? 0,
        );
      } catch (_) {
        abonnement = null;
      }
    }

    // ── Stats (à plat dans stats:{}) ──
    final stats          = j['stats'] as Map<String, dynamic>? ?? {};
    final nbPublications = (stats['publications'] ?? 0) as int;
    final nbVues         = (stats['vues']         ?? 0) as int;
    final nbSignalements = (stats['signalements'] ?? 0) as int;

    // On construit des SignalementAdmin "résumés" à partir du compteur stats.
    // Les données complètes (motif, description, publication) sont chargées
    // dans la section Signalements (GET /admin/signalements?escortId=...).
    // Ici on génère des entrées synthétiques pour afficher le badge sur la carte.
    // Le champ escortPseudo est connu depuis l'escort, escortId idem.
    final signalementsResumes = List.generate(
      nbSignalements,
      (i) => SignalementAdmin(
        id:           '${j['id']}_sig_$i',   // ID synthétique (non utilisé pour actions)
        escortId:     j['id']?.toString() ?? '',
        escortPseudo: j['pseudo'] ?? '',
        motif:        'Signalement',          // motif générique — détail dans la section Signalements
        statut:       StatutSignalement.enAttente,
        date:         DateTime.now(),
      ),
    );

    return CompteEscortAdmin(
      escort:          escort,
      abonnementActif: abonnement,
      transactions:    const [],            // chargées au détail uniquement
      signalements:    signalementsResumes, // ← compte les signalements pour le badge
      sanctions:       const [],
      nbPublications:  nbPublications,
      nbVues:          nbVues,
      estBloque:       j['estBloque'] ?? false,
      estBanni:        j['estBanni']  ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────
// CONFIGURATION PLAN (modifiable par l'admin)
// ─────────────────────────────────────────────────────────
class PlanConfig {
  final String id;
  final String nom;
  final bool   estBasique;
  final bool   estBase;
  double       prix;
  int          nbPublications;
  int          dureeJours;
  Color        accentColor;  // mutable — modifiable par l'admin
  final IconData   icone;
  final String?    description;
  List<String>     avantages;

  PlanConfig({
    required this.id,
    required this.nom,
    required this.estBasique,
    this.estBase = true,
    required this.prix,
    required this.nbPublications,
    required this.dureeJours,
    this.accentColor = const Color(0xFF8A8A9A),
    this.icone       = Icons.star_outline_rounded,
    this.description,
    this.avantages   = const [],
  });

  /// Le backend (GET /admin/plans) renvoie le modèle Prisma PlanAbonnement :
  /// { id, nom, description, prix, nbPublications, dureeJours,
  ///   avantages (JSON array), accentColor (hex), estBasique, actif, ordre }
  factory PlanConfig.fromJson(Map<String, dynamic> j) {
    Color parseColor(String? hex) {
      if (hex == null || hex.isEmpty) return const Color(0xFF8A8A9A);
      final h = hex.replaceAll('#', '');
      try { return Color(int.parse('FF$h', radix: 16)); }
      catch (_) { return const Color(0xFF8A8A9A); }
    }

    IconData parseIcone(String nom) {
      switch (nom.toLowerCase()) {
        case 'premium':  return Icons.workspace_premium_rounded;
        case 'standard': return Icons.verified_outlined;
        default:         return Icons.star_outline_rounded;
      }
    }

    final avantagesRaw = j['avantages'];
    final avantages = avantagesRaw is List
        ? avantagesRaw.map((e) => e.toString()).toList()
        : <String>[];

    return PlanConfig(
      id:             j['id']?.toString() ?? '',
      nom:            j['nom'] ?? '',
      estBasique:     j['estBasique'] ?? false,
      estBase: ['Basique', 'Standard', 'Premium'].contains(j['nom']),
      prix:           (j['prix'] ?? 0).toDouble(),
      nbPublications: j['nbPublications'] ?? 1,
      dureeJours:     j['dureeJours'] ?? 7,
      accentColor:    parseColor(j['accentColor']),
      icone:          parseIcone(j['nom'] ?? ''),
      description:    j['description'],
      avantages:      avantages,
    );
  }
}

// ─────────────────────────────────────────────────────────
// NOTIFICATION ADMIN (envoyée)
// ─────────────────────────────────────────────────────────
enum CibleNotification { tous, individuel, multiple }

// On réutilise TypeNotification depuis escort_model.dart

class NotificationAdmin {
  final String           id;
  final String           titre;
  final String           message;
  final CibleNotification cible;
  final List<String>     escortIds; // vide = tous
  final DateTime         dateEnvoi;
  final TypeNotification type;

  const NotificationAdmin({
    required this.id,
    required this.titre,
    required this.message,
    required this.cible,
    required this.escortIds,
    required this.dateEnvoi,
    required this.type,
  });
}

// ─────────────────────────────────────────────────────────
// DONNÉES MOCK ADMIN
// ─────────────────────────────────────────────────────────

// Plans configurables
List<PlanConfig> mockPlansConfig = [
  PlanConfig(
    id: 'plan_basique', nom: 'Basique', estBasique: true, estBase: true,
    prix: 0, nbPublications: 1, dureeJours: 7,
    accentColor: const Color(0xFF8A8A9A), icone: Icons.star_outline_rounded,
    description: 'Plan offert à l\'inscription.',
    avantages: ['1 publication active', 'Visible 7 jours', 'Gratuit'],
  ),
  PlanConfig(
    id: 'plan_standard', nom: 'Standard', estBasique: false, estBase: true,
    prix: 5000, nbPublications: 3, dureeJours: 30,
    accentColor: const Color(0xFFFF5DA8), icone: Icons.verified_outlined,
    description: 'Plus de visibilité.',
    avantages: ['3 publications actives', 'Visible 30 jours', 'Badge Standard', 'Support prioritaire'],
  ),
  PlanConfig(
    id: 'plan_premium', nom: 'Premium', estBasique: false, estBase: true,
    prix: 15000, nbPublications: 10, dureeJours: 30,
    accentColor: const Color(0xFFFFB800), icone: Icons.workspace_premium_rounded,
    description: 'Mise en avant maximale.',
    avantages: ['10 publications actives', 'Priorité maximale', 'Badge Premium doré', 'Statistiques avancées'],
  ),
];

// Plans sous forme PlanAbonnement pour les AbonnementSouscrit
final _planBasiqueMock = PlanAbonnement(
  id: 'plan_basique', nom: 'Basique', description: 'Plan offert',
  prix: 0, nbPublications: 1, dureeJours: 7, avantages: [],
  accentColor: const Color(0xFF8A8A9A), icone: Icons.star_outline_rounded,
);
final _planStandardMock = PlanAbonnement(
  id: 'plan_standard', nom: 'Standard', description: 'Plan standard',
  prix: 5000, nbPublications: 3, dureeJours: 30, avantages: [],
  accentColor: const Color(0xFFFF5DA8), icone: Icons.verified_outlined,
);
final _planPremiumMock = PlanAbonnement(
  id: 'plan_premium', nom: 'Premium', description: 'Plan premium',
  prix: 15000, nbPublications: 10, dureeJours: 30, avantages: [],
  accentColor: const Color(0xFFFFB800), icone: Icons.workspace_premium_rounded,
);

// Comptes escorts mock
List<CompteEscortAdmin> mockComptesAdmin = [
  CompteEscortAdmin(
    escort: EscortModel(
      id: 'e001', pseudo: 'Sofia K.', email: 'sofia.k@proton.me',
      telephone: '+237600000001',
      photoUrl: 'https://randomuser.me/api/portraits/women/11.jpg',
      estVerifie: true,
      dateInscription: DateTime.now().subtract(const Duration(days: 45)),
    ),
    abonnementActif: AbonnementSouscrit(
      id: 'sub_001', plan: _planStandardMock,
      dateDebut: DateTime.now().subtract(const Duration(days: 8)),
      dateFin:   DateTime.now().add(const Duration(days: 22)),
      statut: 'actif',
    ),
    transactions: [
      TransactionModel(id: 't1', planNom: 'Standard', montant: 5000,
        date: DateTime.now().subtract(const Duration(days: 8)),
        statut: TransactionStatus.succes, methodePaiement: 'MTN MoMo'),
    ],
    signalements: [],
    sanctions:    [],
    nbPublications: 2,
    nbVues:         340,
  ),
  CompteEscortAdmin(
    escort: EscortModel(
      id: 'e002', pseudo: 'Naomi B.', email: 'naomi.b@proton.me',
      telephone: '+237600000002',
      photoUrl: 'https://randomuser.me/api/portraits/women/22.jpg',
      estVerifie: true,
      dateInscription: DateTime.now().subtract(const Duration(days: 30)),
    ),
    abonnementActif: AbonnementSouscrit(
      id: 'sub_002', plan: _planPremiumMock,
      dateDebut: DateTime.now().subtract(const Duration(days: 5)),
      dateFin:   DateTime.now().add(const Duration(days: 25)),
      statut: 'actif',
    ),
    transactions: [
      TransactionModel(id: 't2', planNom: 'Premium', montant: 15000,
        date: DateTime.now().subtract(const Duration(days: 5)),
        statut: TransactionStatus.succes, methodePaiement: 'Orange Money'),
    ],
    signalements: [
      SignalementAdmin(
        id: 's001', escortId: 'e002', escortPseudo: 'Naomi B.',
        motif: 'Faux compte',
        description: 'Les photos semblent appartenir à quelqu\'un d\'autre.',
        date: DateTime.now().subtract(const Duration(days: 2)),
        statut: StatutSignalement.enAttente,
      ),
    ],
    sanctions:    [],
    nbPublications: 5,
    nbVues:         890,
  ),
  CompteEscortAdmin(
    escort: EscortModel(
      id: 'e003', pseudo: 'Jade L.', email: 'jade.l@mail.com',
      telephone: '+237600000005',
      photoUrl: 'https://randomuser.me/api/portraits/women/55.jpg',
      estVerifie: false,
      dateInscription: DateTime.now().subtract(const Duration(days: 12)),
    ),
    abonnementActif: AbonnementSouscrit(
      id: 'sub_003', plan: _planBasiqueMock,
      dateDebut: DateTime.now().subtract(const Duration(days: 12)),
      dateFin:   DateTime.now().subtract(const Duration(days: 5)),
      statut: 'expire',
    ),
    transactions: [],
    signalements: [
      SignalementAdmin(
        id: 's002', escortId: 'e003', escortPseudo: 'Jade L.',
        motif: 'Spam',
        description: 'Envoie des messages non sollicités.',
        date: DateTime.now().subtract(const Duration(days: 1)),
        statut: StatutSignalement.enAttente,
      ),
    ],
    sanctions: [],
    nbPublications: 1,
    nbVues: 45,
    estBloque: false,
  ),
];

// Signalements globaux (agrégation de tous les comptes)
List<SignalementAdmin> mockSignalements = mockComptesAdmin
    .expand((c) => c.signalements)
    .toList();