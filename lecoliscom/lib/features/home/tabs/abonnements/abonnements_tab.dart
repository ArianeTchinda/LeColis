import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/abonnement_model.dart';
import '../../../../core/models/transaction_model.dart';
import '/core/models/escort_model.dart';
import './widgets/transaction_card.dart';
import './screens/payment_selection_screen.dart';

class AbonnementsTab extends StatefulWidget {
  final ValueNotifier<String>? searchQuery;

  /// ← NOUVEAU : callback fourni par HomeScreen pour basculer vers l'onglet Profil
  final VoidCallback? onGoToLogin;

  const AbonnementsTab({
    super.key,
    this.searchQuery,
    this.onGoToLogin, // ← NOUVEAU
  });

  @override
  State<AbonnementsTab> createState() => _AbonnementsTabState();
}

class _AbonnementsTabState extends State<AbonnementsTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTabController;
  final SessionManager _session = SessionManager();

  bool get estConnecte => _session.estConnecte;
  String get activePlanId => 'p1';

  final List<PlanAbonnement> _plans = [
    const PlanAbonnement(
      id: 'p1', nom: 'Basique',
      description: 'Offert à chaque nouvelle inscription. Idéal pour découvrir la plateforme.',
      prix: 0, nbPublications: 1, dureeJours: 7,
      avantages: ['1 publication active', 'Visible pendant 7 jours', 'Accès au profil public', 'Gratuit, sans engagement'],
      accentColor: Color(0xFF8A8A9A), icone: Icons.star_outline_rounded,
    ),
    const PlanAbonnement(
      id: 'p2', nom: 'Standard',
      description: 'Plus de visibilité pour développer votre clientèle.',
      prix: 5000, nbPublications: 3, dureeJours: 30,
      avantages: ['3 publications actives', 'Visible pendant 30 jours', 'Badge "Standard" vérifié', 'Support prioritaire'],
      accentColor: Color(0xFFFF5DA8), icone: Icons.verified_outlined,
    ),
    const PlanAbonnement(
      id: 'p3', nom: 'Premium',
      description: 'Mise en avant maximale et publications illimitées.',
      prix: 15000, nbPublications: 10, dureeJours: 30,
      avantages: ['10 publications actives', 'Mise en avant prioritaire', 'Badge "Premium" ✦ doré', 'Statistiques de vues avancées'],
      accentColor: Color(0xFFFFB800), icone: Icons.workspace_premium_rounded,
    ),
  ];

  final List<TransactionModel> _transactions = [
    TransactionModel(id: 't1', planNom: 'Standard', montant: 5000,
      date: DateTime(2025, 5, 6), statut: TransactionStatus.succes, methodePaiement: 'Orange Money'),
    TransactionModel(id: 't2', planNom: 'Premium', montant: 15000,
      date: DateTime(2025, 4, 1), statut: TransactionStatus.succes, methodePaiement: 'MTN MoMo'),
  ];

  PlanAbonnement get _planActuel => _plans.firstWhere((p) => p.id == activePlanId);

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 3, vsync: this);
    _session.addListener(_onSessionChange);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChange);
    _innerTabController.dispose();
    super.dispose();
  }

  void _onSessionChange() {
    if (mounted) setState(() {});
  }

  void _allerAuPaiement(PlanAbonnement plan) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentSelectionScreen(plan: plan),
    ));
  }

  /// ← MODIFIÉ : au lieu de pushNamed('/login'), on appelle le callback
  /// qui fait basculer HomeScreen sur l'onglet Profil (index 2)
  void _goToLogin() {
    widget.onGoToLogin?.call();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final width     = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final hPad      = isDesktop ? 32.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── EN-TÊTE
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Abonnements',
              style: GoogleFonts.cormorantGaramond(
                fontSize: isDesktop ? 36 : 28, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text('Choisissez le plan qui vous correspond',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 16),
          ]),
        ),

        // ── BANDEAU NON CONNECTÉ
        if (!estConnecte)
          Container(
            margin: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryPink.withOpacity(0.22)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primaryPink, size: 18),
              const SizedBox(width: 10),
              const Expanded(child: Text('Connectez-vous pour profiter de la plateforme.',
                style: TextStyle(fontSize: 13, color: AppColors.primaryPinkSoft))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _goToLogin, // ← MODIFIÉ
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primaryPink, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Connexion', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),

        // ── TABBAR
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              controller: _innerTabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.primaryPink.withOpacity(0.35)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: AppColors.primaryPink,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              tabs: const [Tab(text: 'Plans'), Tab(text: 'Mon abonnement'), Tab(text: 'Historique')],
            ),
          ),
        ),

        const SizedBox(height: 4),

        // ── CONTENU TABS
        Expanded(
          child: TabBarView(
            controller: _innerTabController,
            children: [
              _buildPlansView(isDesktop, hPad),
              _buildAbonnementActifView(isDesktop, hPad),
              _buildHistoriqueView(isDesktop, hPad),
            ],
          ),
        ),
      ],
    );
  }

  // ── VUE 1 : PLANS
  Widget _buildPlansView(bool isDesktop, double hPad) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.searchQuery ?? ValueNotifier(''),
      builder: (context, query, _) {
        final filtered = _plans.where((p) =>
          p.nom.toLowerCase().contains(query.toLowerCase())).toList();

        if (filtered.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Aucun plan pour "$query"',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ]));
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 100),
          child: isDesktop
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: filtered.map((plan) =>
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _PlanCard(
                    plan: plan,
                    isActuel: plan.id == activePlanId,
                    estConnecte: estConnecte,
                    onTap: () => estConnecte
                        ? _allerAuPaiement(plan)
                        : _goToLogin(), // ← MODIFIÉ
                  ),
                ))).toList())
            : Column(children: filtered.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PlanCard(
                  plan: plan,
                  isActuel: plan.id == activePlanId,
                  estConnecte: estConnecte,
                  onTap: () => estConnecte
                      ? _allerAuPaiement(plan)
                      : _goToLogin(), // ← MODIFIÉ
                ),
              )).toList()),
        );
      },
    );
  }

  // ── VUE 2 : MON ABONNEMENT
  Widget _buildAbonnementActifView(bool isDesktop, double hPad) {
    if (!estConnecte) return _murConnexion();
    final plan      = _planActuel;
    final color     = plan.accentColor;
    final dateDebut = DateTime.now().subtract(const Duration(days: 3));
    final dateFin   = dateDebut.add(Duration(days: plan.dureeJours));
    final progress  = (3.0 / plan.dureeJours).clamp(0.0, 1.0);
    final restants  = dateFin.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isDesktop ? 80 : hPad, 16, isDesktop ? 80 : hPad, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [color.withOpacity(0.13), AppColors.surface]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.30), width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
                child: Icon(plan.icone, color: color, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Plan ${plan.nom}', style: GoogleFonts.cormorantGaramond(
                  fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(plan.prix == 0 ? 'Gratuit' : '${plan.prix} FCFA',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF25D366).withOpacity(0.35)),
                ),
                child: const Text('● Actif', style: TextStyle(
                  color: Color(0xFF25D366), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 20),
            Divider(color: AppColors.divider.withOpacity(0.5)),
            const SizedBox(height: 16),
            _row(Icons.calendar_today_rounded, 'Début',         _fmtDate(dateDebut), color),
            const SizedBox(height: 10),
            _row(Icons.event_rounded,          'Expiration',    _fmtDate(dateFin),   color),
            const SizedBox(height: 10),
            _row(Icons.hourglass_bottom_rounded,'Jours restants','$restants jours',  color),
            const SizedBox(height: 10),
            _row(Icons.layers_outlined,        'Publications',  '0 / ${plan.nbPublications}', color),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Progression', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text('${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(color), minHeight: 6)),
          ]),
        ),
        const SizedBox(height: 24),
        Text('Actions disponibles', style: GoogleFonts.cormorantGaramond(
          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (plan.id != 'p1')
          _bouton(icon: Icons.refresh_rounded, label: 'Renouveler le plan ${plan.nom}',
            sousTitre: 'Commencera après expiration', color: color,
            onTap: () => _allerAuPaiement(plan)),
        const SizedBox(height: 10),
        ..._plans.where((p) => _plans.indexOf(p) > _plans.indexOf(plan)).map((p) =>
          Padding(padding: const EdgeInsets.only(bottom: 10),
            child: _bouton(icon: Icons.arrow_upward_rounded,
              label: 'Passer au plan ${p.nom}',
              sousTitre: p.prix == 0 ? 'Gratuit' : '${p.prix} FCFA / mois',
              color: p.accentColor, onTap: () => _allerAuPaiement(p)))),
      ]),
    );
  }

  // ── VUE 3 : HISTORIQUE
  Widget _buildHistoriqueView(bool isDesktop, double hPad) {
    if (!estConnecte) return _murConnexion();

    return ListView(
      padding: EdgeInsets.fromLTRB(isDesktop ? 80 : hPad, 16, isDesktop ? 80 : hPad, 100),
      children: [
        Text('Historique des paiements', style: GoogleFonts.cormorantGaramond(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('${_transactions.length} transaction(s)',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        ..._transactions.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TransactionCard(transaction: t))),
      ],
    );
  }

  // ── HELPERS UI
  Widget _row(IconData icon, String label, String value, Color color) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 10),
    Text('$label : ', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
    Expanded(child: Text(value, style: const TextStyle(
      fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis)),
  ]);

  Widget _bouton({required IconData icon, required String label,
      required String sousTitre, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 17)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(sousTitre, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ])),
          Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  /// Mur affiché dans "Mon abonnement" et "Historique" quand non connecté
  Widget _murConnexion() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: AppColors.primaryPink.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryPink, size: 42)),
      const SizedBox(height: 20),
      Text('Accès restreint', style: GoogleFonts.cormorantGaramond(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      const Text('Connectez-vous pour accéder à cette section.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: _goToLogin, // ← MODIFIÉ
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF5DA8), Color(0xFFB68DFF)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('Se connecter', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ),
    ]),
  ));
}

// ═══════════════════════════════════════════════════════════
// PLAN CARD — widget interne
// ═══════════════════════════════════════════════════════════
class _PlanCard extends StatelessWidget {
  final PlanAbonnement plan;
  final bool           isActuel;
  final bool           estConnecte;
  final VoidCallback   onTap;

  const _PlanCard({
    required this.plan, required this.isActuel,
    required this.estConnecte, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color    = plan.accentColor;
    final isBasique = plan.id == 'p1';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActuel ? color.withOpacity(0.5) : AppColors.divider,
          width: isActuel ? 1.5 : 1,
        ),
        boxShadow: isActuel ? [BoxShadow(
          color: color.withOpacity(0.14), blurRadius: 20, offset: const Offset(0, 6))] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 4, color: color),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(plan.icone, color: color, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(plan.nom, style: GoogleFonts.cormorantGaramond(
                    fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('${plan.dureeJours}j · ${plan.nbPublications} pub.',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ])),
                if (isActuel)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.35)),
                    ),
                    child: Text('Actif', style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ]),

              const SizedBox(height: 14),

              RichText(text: TextSpan(children: [
                TextSpan(text: plan.prix == 0 ? 'Gratuit' : '${plan.prix}',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color,
                    fontFamily: 'Roboto')),
                if (plan.prix > 0) TextSpan(text: ' FCFA/mois',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted,
                    fontFamily: 'Roboto')),
              ])),

              const SizedBox(height: 6),
              Text(plan.description, style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5)),

              const SizedBox(height: 14),
              Divider(color: AppColors.divider.withOpacity(0.6)),
              const SizedBox(height: 10),

              ...plan.avantages.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a, style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary))),
                ]),
              )),

              const SizedBox(height: 18),
              _buildCTA(color, isBasique, context),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildCTA(Color color, bool isBasique, BuildContext context) {
    if (isBasique && isActuel) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(14)),
        child: const Text('Plan offert à l\'inscription', textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
      );
    }

    // Non connecté → bouton qui remonte via onTap (déjà branché sur _goToLogin)
    if (!estConnecte) {
      return GestureDetector(
        onTap: onTap, // ← pointe sur _goToLogin via le parent
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.primaryPink.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryPink.withOpacity(0.35))),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.login_rounded, size: 14, color: AppColors.primaryPink),
            SizedBox(width: 6),
            Text('Connectez-vous pour souscrire',
              style: TextStyle(color: AppColors.primaryPink, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.11), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.32)),
        ),
        child: Text(isActuel ? 'Renouveler' : 'Choisir ce plan',
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}