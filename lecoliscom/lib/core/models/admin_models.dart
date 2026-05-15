// lib/core/models/admin_models.dart

import 'package:flutter/material.dart';
import 'escort_model.dart';
import 'abonnement_model.dart';
import 'transaction_model.dart';

// ─────────────────────────────────────────────────────────
// SESSION ADMIN (singleton)
// ─────────────────────────────────────────────────────────
class AdminSession extends ChangeNotifier {
  static final AdminSession _instance = AdminSession._internal();
  factory AdminSession() => _instance;
  AdminSession._internal();

  bool _connecte = false;
  bool get estConnecte => _connecte;

  // En prod : vérifier le token JWT admin via POST /admin/login
  Future<bool> connecter(String email, String motDePasse) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock : identifiants hardcodés — en prod, appel API
    if (email == 'admin@lecolis.com' && motDePasse == 'Admin@2025!') {
      _connecte = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void deconnecter() {
    _connecte = false;
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
  final DateTime date;
  StatutSignalement statut;

  SignalementAdmin({
    required this.id,
    required this.escortId,
    required this.escortPseudo,
    required this.motif,
    this.description,
    required this.date,
    this.statut = StatutSignalement.enAttente,
  });
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
}

// ─────────────────────────────────────────────────────────
// CONFIGURATION PLAN (modifiable par l'admin)
// ─────────────────────────────────────────────────────────
class PlanConfig {
  final String id;
  final String nom;
  final bool   estBasique;
  final bool   estBase;       // ← AJOUTER (true = basique/standard/premium non supprimables)
  double       prix;
  int          nbPublications;
  int          dureeJours;
  final Color      accentColor;  // ← AJOUTER
  final IconData   icone;        // ← AJOUTER
  final String?    description;  // ← AJOUTER
  List<String>     avantages;    // ← AJOUTER

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