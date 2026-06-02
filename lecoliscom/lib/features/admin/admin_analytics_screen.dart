// lib/features/admin/screens/admin_analytics_screen.dart
//
// Design : dark luxury — glassmorphism, gradients, animations fl_chart
// Responsive : mobile (<600) · tablette (600–1024) · desktop (>1024)
// Dépendances : fl_chart: ^0.68.0  |  google_fonts  |  intl

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/services/admin_service.dart';

// ─────────────────────────────────────────────────────────
// PALETTE INTERNE
// ─────────────────────────────────────────────────────────
class _P {
  static const bg          = Color(0xFF0A0A0F);
  static const surface     = Color(0xFF111118);
  static const card        = Color(0xFF16161F);
  static const cardBorder  = Color(0xFF252535);

  static const pink    = Color(0xFFFF4D8F);
  static const violet  = Color(0xFF9B5FFF);
  static const cyan    = Color(0xFF00D4FF);
  static const emerald = Color(0xFF00E5A0);
  static const amber   = Color(0xFFFFB830);
  static const coral   = Color(0xFFFF6B6B);
  static const indigo  = Color(0xFF6366F1);

  static const textPrimary   = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFF9090B0);
  static const textMuted     = Color(0xFF555570);

  static const List<Color> chartPalette = [
    violet, cyan, emerald, amber, coral, pink, indigo,
    Color(0xFF38BDF8), Color(0xFFA78BFA),
  ];
}

// ─────────────────────────────────────────────────────────
// POINT D'ENTRÉE
// ─────────────────────────────────────────────────────────
class AdminAnalyticsScreen extends StatefulWidget {
  final AdminService            adminService;
  final List<CompteEscortAdmin> comptes;

  const AdminAnalyticsScreen({
    super.key,
    required this.adminService,
    required this.comptes,
  });

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with TickerProviderStateMixin {

  late final TabController        _tabs;
  late final AnimationController  _fadeCtrl;
  late final Animation<double>    _fadeAnim;

  // ── Data ────────────────────────────────────────────────
  Map<String, dynamic>? _analytics;
  bool _loadingAnalytics = true;

  List<dynamic> _notifHistory  = [];
  int           _notifTotal    = 0;
  bool          _loadingNotifs = true;
  int           _notifPage     = 1;
  String?       _filterCible;
  String?       _filterEscortId;
  final _notifScroll = ScrollController();
  final _searchCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs     = TabController(length: 2, vsync: this);
    _fadeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadAnalytics();
    _loadNotifHistory(reset: true);
    _notifScroll.addListener(() {
      if (_notifScroll.position.pixels >=
          _notifScroll.position.maxScrollExtent - 300) {
        _loadMoreNotifs();
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _fadeCtrl.dispose();
    _notifScroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loadingAnalytics = true);
    final data = await widget.adminService.getAnalytics();
    if (!mounted) return;
    setState(() { _analytics = data; _loadingAnalytics = false; });
    _fadeCtrl.forward(from: 0);
  }

  Future<void> _loadNotifHistory({bool reset = false}) async {
    if (reset) { _notifPage = 1; _notifHistory = []; }
    setState(() => _loadingNotifs = true);
    final res = await widget.adminService.getHistoriqueNotifications(
      page: _notifPage, cible: _filterCible, escortId: _filterEscortId,
    );
    if (!mounted) return;
    setState(() {
      _notifTotal = res['total'] ?? 0;
      final items = List<dynamic>.from(res['data'] ?? []);
      if (reset) _notifHistory = items; else _notifHistory.addAll(items);
      _loadingNotifs = false;
    });
  }

  Future<void> _loadMoreNotifs() async {
    if (_loadingNotifs || _notifHistory.length >= _notifTotal) return;
    _notifPage++;
    await _loadNotifHistory();
  }

  // ── Layout principal ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w        = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isDesktop= w >= 1024;

    return Container(
      color: _P.bg,
      child: Column(children: [
        _buildHeader(isMobile),
        _buildTabBar(isMobile),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildGraphiques(isMobile, isDesktop),
              _buildNotifHistorique(isMobile),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          isMobile ? 20 : 28, 20, isMobile ? 16 : 24, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [_P.violet, _P.cyan],
              ).createShader(b),
              child: Text('Analytiques',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: isMobile ? 26 : 32,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: -0.5,
                )),
            ),
            const SizedBox(height: 3),
            const Text('Vue d\'ensemble de la plateforme',
              style: TextStyle(fontSize: 12, color: _P.textMuted,
                  letterSpacing: 0.2)),
          ]),
        ),
        _GlassButton(
          icon: Icons.refresh_rounded,
          onTap: () { _loadAnalytics(); _loadNotifHistory(reset: true); },
        ),
      ]),
    );
  }

  // ── TabBar ──────────────────────────────────────────────
  Widget _buildTabBar(bool isMobile) {
    return Container(
      margin: EdgeInsets.fromLTRB(
          isMobile ? 20 : 28, 18, isMobile ? 20 : 28, 0),
      height: 44,
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _P.cardBorder),
      ),
      child: TabBar(
        controller: _tabs,
        padding: const EdgeInsets.all(4),
        indicator: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_P.violet, Color(0xFF6B3FBF)]),
          borderRadius: BorderRadius.circular(9),
          boxShadow: [BoxShadow(
            color: _P.violet.withOpacity(0.4),
            blurRadius: 12, offset: const Offset(0, 2),
          )],
        ),
        indicatorSize:  TabBarIndicatorSize.tab,
        dividerColor:   Colors.transparent,
        labelColor:     Colors.white,
        unselectedLabelColor: _P.textMuted,
        labelStyle:     GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 13),
        tabs: const [
          Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.auto_graph_rounded, size: 15),
            SizedBox(width: 7),
            Text('Graphiques'),
          ])),
          Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.send_rounded, size: 14),
            SizedBox(width: 7),
            Text('Notifs envoyées'),
          ])),
        ],
      ),
    );
  }


  // ═════════════════════════════════════════════════════════
  // ONGLET 1 — GRAPHIQUES
  // ═════════════════════════════════════════════════════════
  Widget _buildGraphiques(bool isMobile, bool isDesktop) {
    if (_loadingAnalytics) return _buildLoadingState();
    if (_analytics == null) return _buildErrorState();

    final a   = _analytics!;
    final pad = isMobile ? 16.0 : (isDesktop ? 28.0 : 22.0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: _P.violet,
        backgroundColor: _P.card,
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, 20, pad, 40),
          children: [
            _buildKpiGrid(a, isMobile, isDesktop),
            const SizedBox(height: 20),
            if (isDesktop) ...[
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(children: [
                  _buildInscriptionsCard(a),
                  const SizedBox(height: 16),
                  _buildSignalementsCard(a),
                  const SizedBox(height: 16),
                  _buildSanctionsCard(a),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(children: [
                  _buildRevenusCard(a),
                  const SizedBox(height: 16),
                  _buildDonutRow(a, false),
                  const SizedBox(height: 16),
                  _buildMethodesCard(a),
                ])),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _buildTopVillesCard(a)),
                const SizedBox(width: 16),
                Expanded(child: _buildEscortsCard(a)),
              ]),
              const SizedBox(height: 16),
              _buildAvisCard(a),
            ] else if (!isMobile) ...[
              _buildInscriptionsCard(a), const SizedBox(height: 16),
              _buildRevenusCard(a),      const SizedBox(height: 16),
              _buildDonutRow(a, false),  const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _buildTopVillesCard(a)),
                const SizedBox(width: 14),
                Expanded(child: _buildSignalementsCard(a)),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _buildMethodesCard(a)),
                const SizedBox(width: 14),
                Expanded(child: _buildSanctionsCard(a)),
              ]),
              const SizedBox(height: 16),
              _buildEscortsCard(a), const SizedBox(height: 16),
              _buildAvisCard(a),
            ] else ...[
              _buildInscriptionsCard(a), const SizedBox(height: 14),
              _buildRevenusCard(a),      const SizedBox(height: 14),
              _buildDonutRow(a, true),   const SizedBox(height: 14),
              _buildTopVillesCard(a),    const SizedBox(height: 14),
              _buildSignalementsCard(a), const SizedBox(height: 14),
              _buildMethodesCard(a),     const SizedBox(height: 14),
              _buildSanctionsCard(a),    const SizedBox(height: 14),
              _buildEscortsCard(a),      const SizedBox(height: 14),
              _buildAvisCard(a),
            ],
          ],
        ),
      ),
    );
  }

  // ── KPI Grid ────────────────────────────────────────────
  Widget _buildKpiGrid(Map<String, dynamic> a, bool isMobile, bool isDesktop) {
    final stats = Map<String, dynamic>.from(a['escortsStats'] ?? {});
    final avis  = Map<String, dynamic>.from(a['avisStats']    ?? {});
    double revenu = 0;
    for (final m in (a['revenusParMois'] as List? ?? [])) {
      revenu += (m['total'] as num?)?.toDouble() ?? 0;
    }
    int abActifs = 0;
    for (final ab in (a['abonnementsStatut'] as List? ?? [])) {
      if (ab['statut'] == 'ACTIF') abActifs = ab['total'] as int;
    }

    final kpis = [
      _KpiData('Escorts',       '${stats['total'] ?? 0}',
          Icons.people_alt_rounded,        _P.violet,  _P.cyan),
      _KpiData('Revenu total',  _fmtShort(revenu),
          Icons.trending_up_rounded,       _P.emerald, const Color(0xFF00B4D8)),
      _KpiData('Abonnés actifs','$abActifs',
          Icons.workspace_premium_rounded, _P.amber,   _P.coral),
      _KpiData('Note moyenne',  '${avis['noteMoyenne'] ?? 0}★',
          Icons.star_rounded,              _P.pink,    _P.violet),
    ];

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : (isMobile ? 2 : 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.55 : 1.75,
      children: kpis.map((k) => _KpiCard(data: k)).toList(),
    );
  }

  // ── Builders cartes individuelles ───────────────────────
  Widget _buildInscriptionsCard(Map<String, dynamic> a) => _AnalyticsCard(
    titre: 'Inscriptions par semaine', icone: Icons.person_add_rounded,
    gradient: [_P.cyan, _P.violet],
    child: _InscriptionsChart(
      data: List<Map<String, dynamic>>.from(a['inscriptionsParSemaine'] ?? [])),
  );

  Widget _buildRevenusCard(Map<String, dynamic> a) => _AnalyticsCard(
    titre: 'Revenus mensuels (FCFA)', icone: Icons.bar_chart_rounded,
    gradient: [_P.emerald, const Color(0xFF00B4D8)],
    child: _RevenusChart(
      data: List<Map<String, dynamic>>.from(a['revenusParMois'] ?? [])),
  );

  Widget _buildDonutRow(Map<String, dynamic> a, bool isMobile) {
    final plans = _AnalyticsCard(
      titre: 'Plans actifs', icone: Icons.donut_large_rounded,
      gradient: [_P.violet, _P.pink], height: 200,
      child: _DonutChart(
        data: List<Map<String, dynamic>>.from(a['plansActifs'] ?? []),
        labelKey: 'nom', colorKey: 'couleur', valueKey: 'total',
      ),
    );
    final pubs = _AnalyticsCard(
      titre: 'Publications', icone: Icons.article_rounded,
      gradient: [_P.amber, _P.coral], height: 200,
      child: _DonutChart(
        data: List<Map<String, dynamic>>.from(a['pubsParStatut'] ?? []),
        labelKey: 'statut', valueKey: 'total',
        staticColors: const {
          'ACTIVE':    _P.emerald, 'EXPIREE': _P.coral,
          'BROUILLON': Color(0xFF6B7280), 'SUSPENDUE': _P.amber,
        },
        labelMapper: const {
          'ACTIVE': 'Active', 'EXPIREE': 'Expirée',
          'BROUILLON': 'Brouillon', 'SUSPENDUE': 'Suspendue',
        },
      ),
    );
    if (isMobile) return Column(children: [plans, const SizedBox(height: 14), pubs]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: plans), const SizedBox(width: 14), Expanded(child: pubs),
    ]);
  }

  Widget _buildTopVillesCard(Map<String, dynamic> a) => _AnalyticsCard(
    titre: 'Top villes', icone: Icons.location_city_rounded,
    gradient: [_P.amber, _P.pink],
    child: _HBarChart(
      data: List<Map<String, dynamic>>.from(a['topVilles'] ?? []),
      labelKey: 'ville', valueKey: 'total', color: _P.amber,
    ),
  );

  Widget _buildSignalementsCard(Map<String, dynamic> a) => _AnalyticsCard(
    titre: 'Signalements par motif', icone: Icons.flag_rounded,
    gradient: [_P.coral, _P.pink],
    child: _HBarChart(
      data: List<Map<String, dynamic>>.from(a['signalementsParMotif'] ?? []),
      labelKey: 'motif', valueKey: 'total', color: _P.coral,
    ),
  );

  Widget _buildMethodesCard(Map<String, dynamic> a) => _AnalyticsCard(
    titre: 'Méthodes de paiement', icone: Icons.credit_card_rounded,
    gradient: [_P.cyan, _P.emerald], height: 200,
    child: _DonutChart(
      data: List<Map<String, dynamic>>.from(a['methodesPaiement'] ?? []),
      labelKey: 'methode', valueKey: 'total',
    ),
  );

  Widget _buildSanctionsCard(Map<String, dynamic> a) => _AnalyticsCard(
    titre: 'Sanctions appliquées', icone: Icons.gavel_rounded,
    gradient: [_P.pink, _P.violet],
    child: _HBarChart(
      data: (a['sanctionsParType'] as List? ?? []).map((d) => {
        'label': _sanctionLabel(d['type'] as String? ?? ''),
        'total': d['total'],
        'barColor': _sanctionColor(d['type'] as String? ?? ''),
      }).toList(),
      labelKey: 'label', valueKey: 'total',
      colorKey: 'barColor', color: _P.pink,
    ),
  );

  Widget _buildEscortsCard(Map<String, dynamic> a) => _AnalyticsCard(
    titre: 'Statuts des comptes', icone: Icons.shield_rounded,
    gradient: [_P.violet, _P.indigo],
    child: _EscortsStatutWidget(
        stats: Map<String, dynamic>.from(a['escortsStats'] ?? {})),
  );

  Widget _buildAvisCard(Map<String, dynamic> a) {
    final avis = Map<String, dynamic>.from(a['avisStats'] ?? {});
    return _AnalyticsCard(
      titre: 'Satisfaction — Note moyenne', icone: Icons.star_half_rounded,
      gradient: [_P.amber, _P.pink],
      child: _AvisWidget(
        note:  (avis['noteMoyenne'] as num?)?.toDouble() ?? 0.0,
        total: avis['total'] as int? ?? 0,
      ),
    );
  }

  // ── États loading / error ─────────────────────────────
  Widget _buildLoadingState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 44, height: 44,
        child: CircularProgressIndicator(strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(_P.violet.withOpacity(0.8)))),
      const SizedBox(height: 16),
      const Text('Chargement…',
          style: TextStyle(fontSize: 12, color: _P.textMuted)),
    ]),
  );

  Widget _buildErrorState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, color: _P.textMuted, size: 44),
      const SizedBox(height: 14),
      const Text('Données indisponibles',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              color: _P.textPrimary)),
      const SizedBox(height: 18),
      _GlassButton(icon: Icons.refresh_rounded, label: 'Réessayer',
          onTap: _loadAnalytics),
    ]),
  );

  // ── Helpers ──────────────────────────────────────────
  String _fmtShort(double v) {
    if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)}M';
    if (v >= 1_000)     return '${(v / 1_000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _sanctionLabel(String t) => const {
    'AVERTISSEMENT': 'Avertissement', 'BLOCAGE_TEMPORAIRE': 'Blocage',
    'BANNISSEMENT': 'Bannissement',
  }[t] ?? t;

  Color _sanctionColor(String t) => const {
    'AVERTISSEMENT': _P.amber, 'BLOCAGE_TEMPORAIRE': _P.coral,
    'BANNISSEMENT': _P.pink,
  }[t] ?? _P.violet;


  // ═════════════════════════════════════════════════════════
  // ONGLET 2 — NOTIFS ENVOYÉES
  // ═════════════════════════════════════════════════════════
  Widget _buildNotifHistorique(bool isMobile) {
    return Column(children: [
      _buildNotifHeader(isMobile),
      Expanded(
        child: _loadingNotifs && _notifHistory.isEmpty
          ? _buildLoadingState()
          : _notifHistory.isEmpty
            ? _buildEmptyNotifs()
            : RefreshIndicator(
                onRefresh: () => _loadNotifHistory(reset: true),
                color: _P.violet, backgroundColor: _P.card,
                child: ListView.builder(
                  controller: _notifScroll,
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24, 12, isMobile ? 16 : 24, 40),
                  itemCount: _notifHistory.length + 1,
                  itemBuilder: (_, i) {
                    if (i == _notifHistory.length) {
                      return _notifHistory.length < _notifTotal
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _P.violet))))
                        : Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Center(child: Text(
                              '${_notifHistory.length} / $_notifTotal affichées',
                              style: const TextStyle(
                                  fontSize: 11, color: _P.textMuted))));
                    }
                    return _NotifHistCard(
                      notif:   Map<String, dynamic>.from(_notifHistory[i]),
                      comptes: widget.comptes,
                    );
                  },
                ),
              ),
      ),
    ]);
  }

  Widget _buildNotifHeader(bool isMobile) {
    final cibles = [null, 'TOUS', 'INDIVIDUEL', 'MULTIPLE'];
    final labels = ['Tous', 'Global', 'Individuel', 'Multiple'];
    final icons  = [
      Icons.all_inclusive_rounded, Icons.public_rounded,
      Icons.person_rounded, Icons.group_rounded,
    ];

    return Container(
      color: _P.surface,
      padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24, 14, isMobile ? 16 : 24, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [_P.violet, _P.cyan]).createShader(b),
            child: Text('$_notifTotal',
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          const Text('notifications envoyées',
            style: TextStyle(fontSize: 13, color: _P.textSecondary)),
        ]),
        const SizedBox(height: 12),
        // Filtres cible
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(cibles.length, (i) {
              final sel = _filterCible == cibles[i];
              return GestureDetector(
                onTap: () {
                  setState(() => _filterCible = cibles[i]);
                  _loadNotifHistory(reset: true);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: sel
                      ? const LinearGradient(
                          colors: [_P.violet, Color(0xFF6B3FBF)])
                      : null,
                    color: sel ? null : _P.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? _P.violet.withOpacity(0.5) : _P.cardBorder),
                    boxShadow: sel ? [BoxShadow(
                      color: _P.violet.withOpacity(0.3),
                      blurRadius: 10, offset: const Offset(0, 3),
                    )] : null,
                  ),
                  child: Row(children: [
                    Icon(icons[i], size: 13,
                        color: sel ? Colors.white : _P.textMuted),
                    const SizedBox(width: 6),
                    Text(labels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? Colors.white : _P.textMuted,
                      )),
                  ]),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        // Recherche
        SizedBox(
          height: 38,
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 12, color: _P.textPrimary),
            decoration: InputDecoration(
              hintText: 'Filtrer par compte (pseudo ou email)…',
              hintStyle: const TextStyle(fontSize: 12, color: _P.textMuted),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 15, color: _P.textMuted),
              suffixIcon: _filterEscortId != null
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _filterEscortId = null);
                      _loadNotifHistory(reset: true);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _P.cardBorder,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 12, color: _P.textMuted),
                    ),
                  )
                : null,
              filled: true, fillColor: _P.card,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _P.cardBorder)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _P.cardBorder)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _P.violet, width: 1.5)),
            ),
            onSubmitted: (v) {
              if (v.trim().isEmpty) {
                setState(() => _filterEscortId = null);
              } else {
                if (widget.comptes.isEmpty) return;
                final match = widget.comptes.firstWhere(
                  (c) =>
                    c.escort.pseudo.toLowerCase().contains(v.toLowerCase()) ||
                    c.escort.email.toLowerCase().contains(v.toLowerCase()),
                  orElse: () => widget.comptes.first,
                );
                setState(() => _filterEscortId = match.escort.id);
              }
              _loadNotifHistory(reset: true);
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyNotifs() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: _P.violet.withOpacity(0.1), shape: BoxShape.circle,
          border: Border.all(
              color: _P.violet.withOpacity(0.2), width: 1.5)),
        child: const Icon(Icons.notifications_off_outlined,
            color: _P.violet, size: 32),
      ),
      const SizedBox(height: 16),
      const Text('Aucune notification',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              color: _P.textPrimary)),
      const SizedBox(height: 6),
      const Text('Les notifications envoyées apparaîtront ici',
          style: TextStyle(fontSize: 12, color: _P.textMuted)),
    ]),
  );
}


// ─────────────────────────────────────────────────────────
// _AnalyticsCard — carte glassmorphique premium
// ─────────────────────────────────────────────────────────
class _AnalyticsCard extends StatelessWidget {
  final String      titre;
  final IconData    icone;
  final List<Color> gradient;
  final Widget      child;
  final double?     height;

  const _AnalyticsCard({
    required this.titre, required this.icone,
    required this.gradient, required this.child, this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.cardBorder),
        boxShadow: [BoxShadow(
          color: gradient[0].withOpacity(0.07),
          blurRadius: 20, offset: const Offset(0, 6),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  gradient[0].withOpacity(0.25),
                  gradient[1].withOpacity(0.15),
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: gradient[0].withOpacity(0.3), width: 1),
              ),
              child: Icon(icone, color: gradient[0], size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(titre,
              style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: _P.textPrimary, letterSpacing: 0.1))),
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: gradient[0].withOpacity(0.6), blurRadius: 6)],
              ),
            ),
          ]),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              gradient[0].withOpacity(0.4),
              gradient[1].withOpacity(0.1),
              Colors.transparent,
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: height != null
              ? SizedBox(height: height, child: child)
              : child,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _KpiCard
// ─────────────────────────────────────────────────────────
class _KpiData {
  final String label, valeur;
  final IconData icon;
  final Color c1, c2;
  const _KpiData(this.label, this.valeur, this.icon, this.c1, this.c2);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.cardBorder),
        boxShadow: [BoxShadow(
          color: data.c1.withOpacity(0.08),
          blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Stack(children: [
        Positioned(right: -14, top: -14,
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [
                data.c1.withOpacity(0.15), Colors.transparent]),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    data.c1.withOpacity(0.2), data.c2.withOpacity(0.1)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: data.c1.withOpacity(0.3), width: 1),
                ),
                child: Icon(data.icon, size: 15, color: data.c1),
              ),
              const Spacer(),
              ShaderMask(
                shaderCallback: (b) =>
                    LinearGradient(colors: [data.c1, data.c2]).createShader(b),
                child: Text(data.valeur,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22, color: Colors.white, letterSpacing: -0.5)),
              ),
              const SizedBox(height: 2),
              Text(data.label,
                style: const TextStyle(
                    fontSize: 11, color: _P.textMuted, letterSpacing: 0.2)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// GRAPHIQUE — Inscriptions (LineChart)
// ─────────────────────────────────────────────────────────
class _InscriptionsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _InscriptionsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _EmptyData();
    final spots = [
      for (int i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), (data[i]['total'] as int).toDouble()),
    ];
    final maxY = spots.map((s) => s.y).reduce(math.max) * 1.3 + 1;

    return SizedBox(
      height: 170,
      child: LineChart(LineChartData(
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: _P.cardBorder, strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 30,
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
              style: const TextStyle(fontSize: 9, color: _P.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 22,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= data.length || i % 2 != 0)
                return const SizedBox();
              final s = data[i]['semaine'] as String? ?? '';
              final d = s.length >= 10
                  ? '${s.substring(8, 10)}/${s.substring(5, 7)}' : '';
              return Text(d,
                  style: const TextStyle(fontSize: 8, color: _P.textMuted));
            })),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0, maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, curveSmoothness: 0.4,
            gradient: const LinearGradient(colors: [_P.cyan, _P.violet]),
            barWidth: 2.5,
            dotData: FlDotData(
              show: spots.length <= 8,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3.5, color: _P.cyan,
                strokeWidth: 2, strokeColor: _P.card)),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _P.violet.withOpacity(0.25),
                  _P.cyan.withOpacity(0.04),
                ],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────
// GRAPHIQUE — Revenus (BarChart)
// ─────────────────────────────────────────────────────────
class _RevenusChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  const _RevenusChart({required this.data});
  @override State<_RevenusChart> createState() => _RevenusChartState();
}
class _RevenusChartState extends State<_RevenusChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return _EmptyData();
    final maxY = widget.data.map((d) =>
        (d['total'] as num?)?.toDouble() ?? 0.0)
        .fold(0.0, math.max) * 1.3 + 1;
    const mois = ['','J','F','M','A','M','J','J','A','S','O','N','D'];

    return SizedBox(
      height: 170,
      child: BarChart(BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _P.card,
            getTooltipItem: (g, _, rod, __) => BarTooltipItem(
              '${NumberFormat('#,###', 'fr').format(rod.toY.toInt())} F',
              GoogleFonts.dmSans(color: _P.emerald, fontSize: 11,
                  fontWeight: FontWeight.w600))),
          touchCallback: (e, r) => setState(() =>
            _touched = r?.spot?.touchedBarGroupIndex),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 24,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= widget.data.length) return const SizedBox();
              final m = widget.data[i]['mois'] as String? ?? '';
              final idx = int.tryParse(m.length >= 7 ? m.substring(5,7) : '0') ?? 0;
              return Text(idx > 0 && idx < mois.length ? mois[idx] : '',
                  style: const TextStyle(fontSize: 9, color: _P.textMuted));
            })),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 38,
            getTitlesWidget: (v, _) {
              String t;
              if (v >= 1_000_000)      t = '${(v/1_000_000).toStringAsFixed(0)}M';
              else if (v >= 1_000)     t = '${(v/1_000).toStringAsFixed(0)}K';
              else                     t = v.toInt().toString();
              return Text(t, style: const TextStyle(
                  fontSize: 8, color: _P.textMuted));
            })),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: _P.cardBorder, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(widget.data.length, (i) {
          final v = (widget.data[i]['total'] as num?)?.toDouble() ?? 0.0;
          final isTouched = _touched == i;
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: v,
              gradient: LinearGradient(
                colors: isTouched
                    ? [_P.emerald, const Color(0xFF00B4D8)]
                    : [_P.emerald.withOpacity(0.7),
                       const Color(0xFF00B4D8).withOpacity(0.5)],
                begin: Alignment.bottomCenter, end: Alignment.topCenter),
              width: isTouched ? 14 : 11,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ]);
        }),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────
// GRAPHIQUE — Donut générique
// ─────────────────────────────────────────────────────────
class _DonutChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String  labelKey, valueKey;
  final String? colorKey;
  final Map<String, Color>?  staticColors;
  final Map<String, String>? labelMapper;

  const _DonutChart({
    required this.data, required this.labelKey, required this.valueKey,
    this.colorKey, this.staticColors, this.labelMapper,
  });

  @override State<_DonutChart> createState() => _DonutChartState();
}
class _DonutChartState extends State<_DonutChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return _EmptyData();
    final total = widget.data.fold<double>(
        0, (s, d) => s + ((d[widget.valueKey] as num?)?.toDouble() ?? 0));

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      SizedBox(
        width: 120, height: 140,
        child: PieChart(PieChartData(
          sectionsSpace: 3, centerSpaceRadius: 34,
          pieTouchData: PieTouchData(
            touchCallback: (e, r) => setState(() =>
              _touched = r?.touchedSection?.touchedSectionIndex ?? -1)),
          sections: List.generate(widget.data.length, (i) {
            final d = widget.data[i];
            final v = (d[widget.valueKey] as num?)?.toDouble() ?? 0;
            final pct = total > 0 ? v / total * 100 : 0.0;
            final isTouched = _touched == i;
            final color = _getColor(d, i);
            return PieChartSectionData(
              value: v, color: color,
              radius: isTouched ? 46 : 40,
              title: pct >= 10 ? '${pct.toStringAsFixed(0)}%' : '',
              titleStyle: const TextStyle(
                  fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
            );
          }),
        )),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(math.min(widget.data.length, 6), (i) {
            final d = widget.data[i];
            final label = widget.labelMapper?[d[widget.labelKey]]
                ?? d[widget.labelKey] as String? ?? '?';
            final v     = d[widget.valueKey] as int? ?? 0;
            final color = _getColor(d, i);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(children: [
                Container(width: 7, height: 7,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: color.withOpacity(0.5), blurRadius: 4)])),
                const SizedBox(width: 8),
                Expanded(child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: _P.textSecondary))),
                Text('$v', style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: _P.textPrimary)),
              ]),
            );
          }),
        ),
      ),
    ]);
  }

  Color _getColor(Map<String, dynamic> d, int i) {
    if (widget.staticColors != null) {
      final key = d[widget.labelKey] as String? ?? '';
      if (widget.staticColors!.containsKey(key))
        return widget.staticColors![key]!;
    }
    if (widget.colorKey != null && d[widget.colorKey] is String)
      return _hexToColor(d[widget.colorKey] as String);
    return _P.chartPalette[i % _P.chartPalette.length];
  }
}

// ─────────────────────────────────────────────────────────
// GRAPHIQUE — Barres horizontales
// ─────────────────────────────────────────────────────────
class _HBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String  labelKey, valueKey;
  final String? colorKey;
  final Color   color;

  const _HBarChart({
    required this.data, required this.labelKey,
    required this.valueKey, required this.color, this.colorKey,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _EmptyData();
    final maxVal = data.map((d) =>
        (d[valueKey] as num?)?.toDouble() ?? 0.0).fold(0.0, math.max);

    return Column(
      children: data.map((d) {
        final label = d[labelKey] as String? ?? '?';
        final val   = (d[valueKey] as num?)?.toDouble() ?? 0;
        final pct   = maxVal > 0 ? val / maxVal : 0.0;
        final c     = (colorKey != null && d[colorKey] is Color)
            ? d[colorKey] as Color : color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: _P.textSecondary))),
              const SizedBox(width: 8),
              Text('${val.toInt()}', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: c)),
            ]),
            const SizedBox(height: 5),
            Stack(children: [
              Container(height: 6,
                decoration: BoxDecoration(
                    color: _P.cardBorder,
                    borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [c, c.withOpacity(0.5)]),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [BoxShadow(
                        color: c.withOpacity(0.4),
                        blurRadius: 6, offset: const Offset(0, 1))],
                  ),
                ),
              ),
            ]),
          ]),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGET — Statuts escorts
// ─────────────────────────────────────────────────────────
class _EscortsStatutWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _EscortsStatutWidget({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total    = stats['total']    as int? ?? 0;
    final verifies = stats['verifies'] as int? ?? 0;
    final normaux  = stats['normaux']  as int? ?? 0;
    final bloques  = stats['bloques']  as int? ?? 0;
    final bannis   = stats['bannis']   as int? ?? 0;

    if (total == 0) return _EmptyData();

    final rows = [
      ('Vérifiés', verifies, _P.emerald),
      ('Normaux',  normaux,  _P.cyan),
      ('Bloqués',  bloques,  _P.amber),
      ('Bannis',   bannis,   _P.coral),
    ];

    return Column(
      children: rows.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 7, height: 7,
              decoration: BoxDecoration(color: r.$3, shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: r.$3.withOpacity(0.6), blurRadius: 5)])),
            const SizedBox(width: 8),
            Expanded(child: Text(r.$1,
                style: const TextStyle(
                    fontSize: 11, color: _P.textSecondary))),
            Text('${r.$2}', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: r.$3)),
            Text(' / $total', style: const TextStyle(
                fontSize: 10, color: _P.textMuted)),
          ]),
          const SizedBox(height: 5),
          Stack(children: [
            Container(height: 5,
              decoration: BoxDecoration(
                  color: _P.cardBorder,
                  borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(
              widthFactor: total > 0
                  ? (r.$2 / total).clamp(0.0, 1.0) : 0.0,
              child: Container(height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [r.$3, r.$3.withOpacity(0.5)]),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(
                      color: r.$3.withOpacity(0.4), blurRadius: 6)],
                )),
            ),
          ]),
        ]),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGET — Note moyenne
// ─────────────────────────────────────────────────────────
class _AvisWidget extends StatelessWidget {
  final double note;
  final int    total;
  const _AvisWidget({required this.note, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            _P.amber.withOpacity(0.2), _P.amber.withOpacity(0.04)]),
          border: Border.all(
              color: _P.amber.withOpacity(0.3), width: 1.5)),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [_P.amber, _P.coral]).createShader(b),
            child: Text(note.toStringAsFixed(1),
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 24, color: Colors.white))),
          const Text('/ 5', style: TextStyle(
              fontSize: 9, color: _P.textMuted)),
        ])),
      ),
      const SizedBox(width: 20),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: List.generate(5, (i) {
          if (i < note.floor())
            return const Icon(Icons.star_rounded, color: _P.amber, size: 20);
          else if (i < note)
            return const Icon(Icons.star_half_rounded, color: _P.amber, size: 20);
          else
            return Icon(Icons.star_border_rounded,
                color: _P.textMuted.withOpacity(0.5), size: 20);
        })),
        const SizedBox(height: 8),
        Text('$total avis clients',
            style: const TextStyle(fontSize: 12, color: _P.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _P.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _P.amber.withOpacity(0.25))),
          child: Text(
            note >= 4.5 ? 'Excellent' : note >= 3.5 ? 'Très bien' :
            note >= 2.5 ? 'Bien' : note >= 1.5 ? 'Moyen' : 'À améliorer',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: _P.amber)),
        ),
      ]),
    ]);
  }
}

// ─────────────────────────────────────────────────────────
// CARTE NOTIFICATION ENVOYÉE
// ─────────────────────────────────────────────────────────
class _NotifHistCard extends StatelessWidget {
  final Map<String, dynamic>    notif;
  final List<CompteEscortAdmin> comptes;

  const _NotifHistCard({
    required this.notif, required this.comptes,
  });

  static const _typeGradients = <String, List<Color>>{
    'SYSTEME':     [Color(0xFF38BDF8), Color(0xFF6366F1)],
    'ADMIN':       [_P.pink,    _P.violet],
    'ABONNEMENT':  [_P.violet,  _P.cyan],
    'PUBLICATION': [_P.amber,   _P.coral],
  };

  @override
  Widget build(BuildContext context) {
    final titre   = notif['titre']    as String? ?? '';
    final message = notif['message']  as String? ?? '';
    final type    = notif['type']     as String? ?? 'ADMIN';
    final cible   = notif['cible']    as String? ?? 'TOUS';
    final ids     = List<String>.from(notif['escortIds'] ?? []);
    final date    = DateTime.tryParse(notif['createdAt'] as String? ?? '');
    final ciblesL = List<Map<String, dynamic>>.from(
        notif['escortsCibles'] ?? []);

    final grad    = _typeGradients[type] ?? [_P.violet, _P.cyan];

    final (cibleIcon, cibleLabel, cibleColor) = switch (cible) {
      'INDIVIDUEL' => (Icons.person_rounded,  '1 compte',            _P.cyan),
      'MULTIPLE'   => (Icons.group_rounded,   '${ids.length} comptes', _P.violet),
      _            => (Icons.public_rounded,  'Tous les comptes',    _P.emerald),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.cardBorder),
        boxShadow: [BoxShadow(
          color: grad[0].withOpacity(0.06),
          blurRadius: 14, offset: const Offset(0, 3))],
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          // Barre colorée latérale
          Container(
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    // Badge type
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          grad[0].withOpacity(0.2),
                          grad[1].withOpacity(0.1),
                        ]),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: grad[0].withOpacity(0.3), width: 1)),
                      child: Text(type, style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: grad[0], letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 8),
                    Icon(cibleIcon, size: 11, color: cibleColor),
                    const SizedBox(width: 4),
                    Text(cibleLabel,
                        style: TextStyle(fontSize: 10, color: cibleColor)),
                    const Spacer(),
                    if (date != null)
                      Text(DateFormat('dd/MM/yy • HH:mm').format(date),
                          style: const TextStyle(
                              fontSize: 10, color: _P.textMuted)),
                  ]),
                  const SizedBox(height: 9),
                  Text(titre,
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: _P.textPrimary)),
                  const SizedBox(height: 4),
                  Text(message,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: _P.textSecondary, height: 1.5)),
                  if (ciblesL.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 5,
                      children: ciblesL.take(8).map((e) =>
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: _P.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _P.cardBorder)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.person_rounded,
                                size: 9, color: _P.textMuted),
                            const SizedBox(width: 4),
                            Text(e['pseudo'] as String? ?? '?',
                              style: const TextStyle(
                                  fontSize: 10, color: _P.textSecondary)),
                          ]),
                        )
                      ).toList(),
                    ),
                    if (ciblesL.length < ids.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text('+ ${ids.length - ciblesL.length} autres',
                          style: const TextStyle(
                              fontSize: 10, color: _P.textMuted))),
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGETS UTILITAIRES
// ─────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final IconData     icone;
  final String?      label;
  final VoidCallback onTap;

  const _GlassButton({
    required IconData  icon,
    required this.onTap,
    this.label,
  }) : icone = icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: label != null ? 14 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _P.cardBorder)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 16, color: _P.textSecondary),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(label!, style: const TextStyle(
                fontSize: 12, color: _P.textSecondary)),
          ],
        ]),
      ),
    );
  }
}

class _EmptyData extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Text('Aucune donnée',
          style: TextStyle(fontSize: 11, color: _P.textMuted))),
  );
}

Color _hexToColor(String hex) {
  try {
    final clean = hex.replaceAll('#', '').padLeft(8, 'FF');
    return Color(int.parse(clean, radix: 16));
  } catch (_) {
    return _P.violet;
  }
}