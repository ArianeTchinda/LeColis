// lib/features/home/tabs/abonnements/screens/payment_selection_screen.dart
//
// Écran de paiement complet :
//  1. Résumé du plan
//  2. Choix du mode (Orange Money / MTN MoMo / Carte)
//  3. Formulaire selon le mode (numéro téléphone ou email)
//  4. Appel backend Express → TaraMoney → affichage des vrais liens
//  5. Polling statut toutes les 5s pour détecter la confirmation paiement

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/abonnement_model.dart';

// ─────────────────────────────────────────────────────────
// MODÈLE RÉPONSE BACKEND → liens TaraMoney
// ─────────────────────────────────────────────────────────
class TaraPaymentLinks {
  final String  transactionId; // ID en DB — utilisé pour le polling
  final String? whatsappLink;
  final String? generalLink;
  final String? cardLink;
  final String? smsLink;

  const TaraPaymentLinks({
    required this.transactionId,
    this.whatsappLink,
    this.generalLink,
    this.cardLink,
    this.smsLink,
  });

  factory TaraPaymentLinks.fromJson(Map<String, dynamic> json) {
    final liens = json['liens'] as Map<String, dynamic>? ?? json;
    return TaraPaymentLinks(
      transactionId: json['transactionId'] ?? '',
      whatsappLink:  liens['whatsappLink'],
      generalLink:   liens['generalLink'],
      cardLink:      liens['cardLink'],
      smsLink:       liens['smsLink'],
    );
  }
}

// ─────────────────────────────────────────────────────────
// MODES DE PAIEMENT — tous les moyens disponibles sur TaraMoney
// Source : taramoney.com/# (section "Nos Méthodes Paiement")
// ─────────────────────────────────────────────────────────
enum ModePaiement {
  orangeMoney,
  mtnMomo,
  wave,
  visa,
  mastercard,
  paypal,
  googlePay,
  amazonPay,
}

extension ModePaiementExt on ModePaiement {
  String get label {
    switch (this) {
      case ModePaiement.orangeMoney: return 'Orange Money';
      case ModePaiement.mtnMomo:     return 'MTN MoMo';
      case ModePaiement.wave:        return 'Wave';
      case ModePaiement.visa:        return 'Carte Visa';
      case ModePaiement.mastercard:  return 'Mastercard';
      case ModePaiement.paypal:      return 'PayPal';
      case ModePaiement.googlePay:   return 'Google Pay';
      case ModePaiement.amazonPay:   return 'Amazon Pay';
    }
  }

  String get sousTitre {
    switch (this) {
      case ModePaiement.orangeMoney: return 'Mobile Money — Orange Cameroun';
      case ModePaiement.mtnMomo:     return 'Mobile Money — MTN Cameroun';
      case ModePaiement.wave:        return 'Paiement instantané via Wave';
      case ModePaiement.visa:        return 'Carte bancaire Visa internationale';
      case ModePaiement.mastercard:  return 'Carte bancaire Mastercard internationale';
      case ModePaiement.paypal:      return 'Compte PayPal (paiement international)';
      case ModePaiement.googlePay:   return 'Paiement rapide via Google Pay';
      case ModePaiement.amazonPay:   return 'Paiement via Amazon Pay';
    }
  }

  Color get couleur {
    switch (this) {
      case ModePaiement.orangeMoney: return const Color(0xFFFF6600);
      case ModePaiement.mtnMomo:     return const Color(0xFFFFCC00);
      case ModePaiement.wave:        return const Color(0xFF1DC8FF);
      case ModePaiement.visa:        return const Color(0xFF1A1F71);
      case ModePaiement.mastercard:  return const Color(0xFFEB001B);
      case ModePaiement.paypal:      return const Color(0xFF003087);
      case ModePaiement.googlePay:   return const Color(0xFF4285F4);
      case ModePaiement.amazonPay:   return const Color(0xFFFF9900);
    }
  }

  IconData get icone {
    switch (this) {
      case ModePaiement.orangeMoney: return Icons.phone_android_rounded;
      case ModePaiement.mtnMomo:     return Icons.phone_android_rounded;
      case ModePaiement.wave:        return Icons.waves_rounded;
      case ModePaiement.visa:        return Icons.credit_card_rounded;
      case ModePaiement.mastercard:  return Icons.credit_card_rounded;
      case ModePaiement.paypal:      return Icons.account_balance_wallet_rounded;
      case ModePaiement.googlePay:   return Icons.g_mobiledata_rounded;
      case ModePaiement.amazonPay:   return Icons.shopping_bag_rounded;
    }
  }

  // Catégorie pour regrouper visuellement
  String get categorie {
    switch (this) {
      case ModePaiement.orangeMoney:
      case ModePaiement.mtnMomo:
      case ModePaiement.wave:
        return 'Mobile Money';
      case ModePaiement.visa:
      case ModePaiement.mastercard:
        return 'Carte bancaire';
      case ModePaiement.paypal:
      case ModePaiement.googlePay:
      case ModePaiement.amazonPay:
        return 'Paiement international';
    }
  }

  // Nécessite un numéro de téléphone (Mobile Money)
  bool get necessiteNumero {
    switch (this) {
      case ModePaiement.orangeMoney:
      case ModePaiement.mtnMomo:
      case ModePaiement.wave:
        return true;
      default:
        return false;
    }
  }

  // Nécessite un email (cartes et wallets internationaux)
  bool get necessiteEmail {
    switch (this) {
      case ModePaiement.visa:
      case ModePaiement.mastercard:
      case ModePaiement.paypal:
      case ModePaiement.googlePay:
      case ModePaiement.amazonPay:
        return true;
      default:
        return false;
    }
  }
}

// ─────────────────────────────────────────────────────────
// ÉCRAN PRINCIPAL
// ─────────────────────────────────────────────────────────
class PaymentSelectionScreen extends StatefulWidget {
  final PlanAbonnement plan;
  final String         token; // JWT de l'escort connectée

  const PaymentSelectionScreen({
    super.key,
    required this.plan,
    required this.token,
  });

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  // ── État ──────────────────────────────────────────────
  ModePaiement _mode      = ModePaiement.orangeMoney;
  bool         _loading   = false;
  TaraPaymentLinks? _links;
  String?      _erreur;
  Timer? _pollTimer;
  bool   _paiementConfirme = false;

  // Polling — vérifie toutes les 5s si le paiement est confirmé
  // ignore: unused_field
  String?      _transactionId;

  final _formKey    = GlobalKey<FormState>();
  final _telCtrl    = TextEditingController();
  final _nomCtrl    = TextEditingController();
  final _emailCtrl  = TextEditingController();

  @override
  void dispose() {
    _telCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Vrai appel backend Express ────────────────────────
  // POST /api/paiement/creer-lien
  // Le backend appelle TaraMoney et retourne les liens.
  Future<TaraPaymentLinks> _appelBackend() async {
    // Récupérer le token depuis le stockage sécurisé
    // Adapter selon ton système d'auth (Provider, Riverpod, SharedPreferences…)
    final token = widget.token;

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/paiement/creer-lien'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({ 'planId': widget.plan.id }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return TaraPaymentLinks.fromJson(body);
    }

    try {
      final err = jsonDecode(res.body);
      throw Exception(err['message'] ?? 'Erreur serveur (${res.statusCode}).');
    } catch (_) {
      throw Exception('Erreur serveur (${res.statusCode}).');
    }
  }

  Future<void> _initierPaiement() async {
    // Validation manuelle — l'accordéon AnimatedCrossFade empêche
    // _formKey.currentState?.validate() d'atteindre tous les champs
    final nom = _nomCtrl.text.trim();
    if (nom.isEmpty) {
      setState(() => _erreur = 'Veuillez entrer votre nom complet.');
      return;
    }
    if (_mode.necessiteNumero) {
      final tel = _telCtrl.text.trim().replaceAll(' ', '');
      if (tel.isEmpty || tel.length < 8) {
        setState(() => _erreur = 'Veuillez entrer un numéro de téléphone valide.');
        return;
      }
    }
    if (_mode.necessiteEmail) {
      final email = _emailCtrl.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        setState(() => _erreur = 'Veuillez entrer une adresse email valide.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _erreur  = null;
      _links   = null;
    });

    try {
      // /paiement/creer-lien crée la transaction + l'abonnement EN_ATTENTE
      // et appelle TaraMoney en une seule requête.
      final links = await _appelBackend();
      setState(() {
        _links         = links;
        _transactionId = links.transactionId;
        _loading       = false;
      });
      _showLinksBottomSheet(links);
      _startPolling();
    } catch (e) {
      setState(() {
        _erreur  = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _ouvrirLien(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Impossible d\'ouvrir ce lien'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _startPolling() {
  _pollTimer?.cancel();
  _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
    if (_transactionId == null || _paiementConfirme) return;
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/paiement/statut/$_transactionId'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['statut'] == 'SUCCES') {
          _pollTimer?.cancel();
          _paiementConfirme = true;
          if (mounted) {
            Navigator.pop(context); // fermer le bottom sheet si ouvert
            Navigator.pop(context, true); // retourner true à abonnements_tab
          }
        }
      }
    } catch (_) {} // silencieux — on réessaiera dans 5s
  });
}

  void _copierLien(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Lien copié !', style: TextStyle(color: Colors.white)),
      backgroundColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Bottom sheet des liens de paiement ───────────────
  void _showLinksBottomSheet(TaraPaymentLinks links) {
    showModalBottomSheet(
      context:           context,
      isScrollControlled: true,
      backgroundColor:   Colors.transparent,
      builder: (_) => _LinksBottomSheet(
        links:   links,
        plan:    widget.plan,
        mode:    _mode,
        onOuvrir: _ouvrirLien,
        onCopier: _copierLien,
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide  = MediaQuery.of(context).size.width >= 700;
    final color   = widget.plan.accentColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 20,
          vertical:   24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. RÉSUMÉ DU PLAN ──
                  _ResumePlan(plan: widget.plan),

                  const SizedBox(height: 28),

                  // ── 2. CHOIX DU MODE + FORMULAIRE INLINE ──
                  _SectionLabel(text: 'Mode de paiement'),
                  const SizedBox(height: 4),
                  const Text(
                    'Sélectionnez un mode — le formulaire s\'affiche directement.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _buildModesAccordion(),

                  // Message erreur
                  if (_erreur != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:        const Color(0x22FF5252),
                        borderRadius: BorderRadius.circular(12),
                        border:       Border.all(color: const Color(0x55FF5252)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFFF5252), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_erreur!,
                            style: const TextStyle(
                                color: Color(0xFFFF5252), fontSize: 13))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── 3. BOUTON CTA ──
                  _buildCTA(color),

                  const SizedBox(height: 16),

                  // Note de sécurité
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Paiement sécurisé via TaraMoney',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ]),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation:       0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: AppColors.divider),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              size: 18, color: AppColors.textSecondary),
        ),
      ),
      title: Text(
        'Souscrire au plan ${widget.plan.nom}',
        style: GoogleFonts.cormorantGaramond(
          fontSize:   20,
          fontWeight: FontWeight.w700,
          color:      AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  // ─────────────────────────────────────────────────────
  // MODES DE PAIEMENT — accordion avec formulaire inline
  // ─────────────────────────────────────────────────────
  Widget _buildModesAccordion() {
    final categories = <String, List<ModePaiement>>{};
    for (final mode in ModePaiement.values) {
      categories.putIfAbsent(mode.categorie, () => []).add(mode);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label de catégorie
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                entry.key.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            // Modes de cette catégorie
            ...entry.value.map((mode) {
              final isSelected = _mode == mode;
              final color      = mode.couleur;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.07) : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color.withOpacity(0.55) : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Column(
                  children: [
                    // ── En-tête du mode ──
                    GestureDetector(
                      onTap: () => setState(() => _mode = mode),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        child: Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(mode.icone, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(mode.label,
                                  style: TextStyle(
                                    fontSize:   13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                  )),
                              Text(mode.sousTitre,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ]),
                          ),
                          // Radio visuel
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? color : AppColors.divider,
                                width: isSelected ? 5 : 2,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),

                    // ── Formulaire inline (accordéon) ──
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      firstCurve: Curves.easeOut,
                      secondCurve: Curves.easeIn,
                      crossFadeState: isSelected
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: color.withOpacity(0.20), height: 16),
                            const SizedBox(height: 4),
                            // Nom complet
                            _ChampTexte(
                              controller: _nomCtrl,
                              label:      'Nom complet',
                              hint:       'Ex : Jean Dupont',
                              icone:      Icons.person_outline_rounded,
                              clavier:    TextInputType.name,
                              validateur: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Veuillez entrer votre nom' : null,
                            ),
                            const SizedBox(height: 12),
                            // Numéro ou email selon le mode
                            if (mode.necessiteNumero)
                              _ChampTexte(
                                controller: _telCtrl,
                                label:      'Numéro ${mode.label}',
                                hint:       'Ex : 6XX XXX XXX',
                                icone:      Icons.phone_outlined,
                                clavier:    TextInputType.phone,
                                prefixText: '+237 ',
                                validateur: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Numéro requis';
                                  if (v.trim().replaceAll(' ', '').length < 8)
                                    return 'Numéro invalide';
                                  return null;
                                },
                              )
                            else if (mode.necessiteEmail)
                              _ChampTexte(
                                controller: _emailCtrl,
                                label:      'Email associé à ${mode.label}',
                                hint:       'votre@email.com',
                                icone:      Icons.email_outlined,
                                clavier:    TextInputType.emailAddress,
                                validateur: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email requis';
                                  if (!v.contains('@')) return 'Email invalide';
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        );
      }).toList(),
    );
  }

  // Conservé pour compatibilité mais plus utilisé directement
  // ignore: unused_element
  Widget _buildModesRow() => _buildModesAccordion();

  // ─────────────────────────────────────────────────────
  // BOUTON CTA
  // ─────────────────────────────────────────────────────
  Widget _buildCTA(Color color) {
    return GestureDetector(
      onTap: _loading ? null : _initierPaiement,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFF5DA8), Color(0xFFB68DFF)],
                ),
          color: _loading ? AppColors.surfaceElevated : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _loading ? null : [
            BoxShadow(
              color:      AppColors.primaryPink.withOpacity(0.30),
              blurRadius: 20,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        child: _loading
            ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryPink)),
                SizedBox(width: 12),
                Text('Génération du lien…',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ])
            : const Text(
                'Générer le lien de paiement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:      Colors.white,
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
// BOTTOM SHEET — LIENS DE PAIEMENT
// ═════════════════════════════════════════════════════════
class _LinksBottomSheet extends StatelessWidget {
  final TaraPaymentLinks links;
  final PlanAbonnement   plan;
  final ModePaiement     mode;
  final Function(String) onOuvrir;
  final Function(String) onCopier;

  const _LinksBottomSheet({
    required this.links,
    required this.plan,
    required this.mode,
    required this.onOuvrir,
    required this.onCopier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: const BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),

          // Icône succès
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0x2225D366), shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF25D366), size: 32),
          ),
          const SizedBox(height: 14),

          Text(
            'Lien de paiement généré !',
            style: GoogleFonts.cormorantGaramond(
              fontSize:   22,
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisissez comment finaliser le paiement pour le plan ${plan.nom}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),

          const SizedBox(height: 24),

          // Lien WhatsApp
          if (links.whatsappLink != null)
            _LienBouton(
              icon:    Icons.chat_rounded,
              label:   'Payer via WhatsApp',
              color:   const Color(0xFF25D366),
              onTap:   () => onOuvrir(links.whatsappLink!),
              onCopier: () => onCopier(links.whatsappLink!),
            ),

          const SizedBox(height: 10),

          // Lien général
          if (links.generalLink != null)
            _LienBouton(
              icon:    Icons.link_rounded,
              label:   'Lien de paiement général',
              color:   AppColors.primaryPink,
              onTap:   () => onOuvrir(links.generalLink!),
              onCopier: () => onCopier(links.generalLink!),
            ),

          const SizedBox(height: 10),

          // Carte bancaire
          if (links.cardLink != null)
            _LienBouton(
              icon:    Icons.credit_card_rounded,
              label:   'Payer par carte bancaire',
              color:   const Color(0xFF5DB8FF),
              onTap:   () => onOuvrir(links.cardLink!),
              onCopier: () => onCopier(links.cardLink!),
            ),

          const SizedBox(height: 20),

          Text(
            'Votre abonnement sera activé automatiquement après confirmation du paiement.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _LienBouton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  final VoidCallback onCopier;

  const _LienBouton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.onCopier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        // Bouton principal
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                    style: TextStyle(
                      color:      color,
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                    )),
                ),
                Icon(Icons.open_in_new_rounded, color: color, size: 16),
              ]),
            ),
          ),
        ),
        // Séparateur vertical
        Container(width: 1, height: 40, color: color.withOpacity(0.20)),
        // Bouton copier
        GestureDetector(
          onTap: onCopier,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.copy_rounded, color: color, size: 17),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════
// WIDGETS INTERNES PARTAGÉS
// ═════════════════════════════════════════════════════════

class _ResumePlan extends StatelessWidget {
  final PlanAbonnement plan;
  const _ResumePlan({required this.plan});

  @override
  Widget build(BuildContext context) {
    final color = plan.accentColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:  color.withOpacity(0.14),
            shape:  BoxShape.circle,
          ),
          child: Icon(plan.icone, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Plan ${plan.nom}',
            style: const TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary,
            )),
          Text('${plan.dureeJours} jours · ${plan.nbPublications} publication(s)',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            plan.prix == 0 ? 'Gratuit' : '${plan.prix} FCFA',
            style: TextStyle(
              fontSize:   18,
              fontWeight: FontWeight.w800,
              color:      color,
            ),
          ),
          if (plan.prix > 0)
            const Text('/mois',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.cormorantGaramond(
      fontSize:   18,
      fontWeight: FontWeight.w700,
      color:      AppColors.textPrimary,
    ),
  );
}

class _ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String                label;
  final String                hint;
  final IconData              icone;
  final TextInputType         clavier;
  final String?               prefixText;
  final String? Function(String?)? validateur;

  const _ChampTexte({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icone,
    required this.clavier,
    this.prefixText,
    this.validateur,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
        style: const TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.w500,
          color:      AppColors.textSecondary,
        )),
      const SizedBox(height: 6),
      TextFormField(
        controller:  controller,
        keyboardType: clavier,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        validator:   validateur,
        decoration: InputDecoration(
          hintText:    hint,
          hintStyle:   const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixText:  prefixText,
          prefixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon:  Icon(icone, size: 18, color: AppColors.textMuted),
          filled:      true,
          fillColor:   AppColors.surface,
          errorStyle:  const TextStyle(color: Color(0xFFFF5252), fontSize: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   const BorderSide(color: AppColors.primaryPink, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   const BorderSide(color: Color(0xFFFF5252)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    ]);
  }
}