// lib/features/home/tabs/profil/screens/mot_de_passe_oublie_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/reset_mdp_service.dart';

// ─────────────────────────────────────────────────────────
// ÉCRAN PRINCIPAL — 3 étapes gérées via un PageView interne
// ─────────────────────────────────────────────────────────
class MotDePasseOublieScreen extends StatefulWidget {
  const MotDePasseOublieScreen({super.key});

  @override
  State<MotDePasseOublieScreen> createState() => _MotDePasseOublieScreenState();
}

class _MotDePasseOublieScreenState extends State<MotDePasseOublieScreen> {
  final _service = ResetMdpService();

  // Étape actuelle : 1 → email, 2 → code, 3 → nouveau mdp
  int _etape = 1;

  // Données partagées entre étapes
  String _email    = '';
  String _reinitId = '';

  // Erreur globale
  String? _erreur;
  bool    _loading = false;

  void _setErreur(String? msg) => setState(() => _erreur = msg);
  void _setLoading(bool v)     => setState(() { _loading = v; _erreur = null; });

  void _allerEtape(int n) => setState(() { _etape = n; _erreur = null; });

  // ── Étape 1 → envoyer le code ────────────────────────────
  Future<void> _envoyerCode(String email) async {
    _setLoading(true);
    try {
      await _service.demanderCode(email: email);
      _email = email.trim().toLowerCase();
      _allerEtape(2);
    } on ResetException catch (e) {
      _setErreur(e.message);
    } finally {
      _setLoading(false);
    }
  }

  // ── Étape 2 → vérifier le code ───────────────────────────
  Future<void> _verifierCode(String code) async {
    _setLoading(true);
    try {
      final id = await _service.verifierCode(email: _email, code: code);
      _reinitId = id;
      _allerEtape(3);
    } on ResetException catch (e) {
      _setErreur(e.message);
    } finally {
      _setLoading(false);
    }
  }

  // ── Étape 3 → changer le mot de passe ────────────────────
  Future<void> _changerMdp(String nouveauMdp) async {
    _setLoading(true);
    try {
      await _service.reinitialiserMdp(
        reinitId:          _reinitId,
        nouveauMotDePasse: nouveauMdp,
      );
      _allerEtape(4); // étape "succès"
    } on ResetException catch (e) {
      _setErreur(e.message);
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation:       0,
        leading: _etape > 1 && _etape < 4
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 18),
                onPressed: () => _allerEtape(_etape - 1),
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textPrimary, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          _etape == 4 ? 'Succès !' : 'Mot de passe oublié',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16, fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicateur d'étape (1-2-3)
              if (_etape < 4) _IndicateurEtapes(etape: _etape),
              const SizedBox(height: 28),

              // Contenu selon l'étape
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim, child: child),
                child: KeyedSubtree(
                  key: ValueKey(_etape),
                  child: _buildEtape(),
                ),
              ),

              // Erreur globale
              if (_erreur != null) ...[
                const SizedBox(height: 16),
                _ErreurBandeau(message: _erreur!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEtape() {
    switch (_etape) {
      case 1: return _EtapeEmail(loading: _loading, onSuivant: _envoyerCode);
      case 2: return _EtapeCode(email: _email, loading: _loading,
                  onSuivant: _verifierCode,
                  onRenvoyer: () => _envoyerCode(_email));
      case 3: return _EtapeNouveauMdp(loading: _loading, onValider: _changerMdp);
      case 4: return _EtapeSucces(onRetour: () => Navigator.pop(context));
      default: return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────
// ÉTAPE 1 — Saisir l'email
// ─────────────────────────────────────────────────────────
class _EtapeEmail extends StatefulWidget {
  final bool loading;
  final void Function(String email) onSuivant;
  const _EtapeEmail({required this.loading, required this.onSuivant});

  @override
  State<_EtapeEmail> createState() => _EtapeEmailState();
}

class _EtapeEmailState extends State<_EtapeEmail> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl    = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Titre(
            icone:    Icons.email_outlined,
            titre:    'Entrez votre email',
            sousTitre: 'Nous vous enverrons un code de vérification à 6 chiffres.',
          ),
          const SizedBox(height: 28),

          _ResetLabel('Adresse email'),
          const SizedBox(height: 6),
          _ResetField(
            controller: _ctrl,
            hint:       'votre@email.com',
            icone:      Icons.email_outlined,
            clavier:    TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),

          const SizedBox(height: 32),
          _ResetBouton(
            label:   'Envoyer le code',
            loading: widget.loading,
            onTap:   () {
              if (_formKey.currentState!.validate()) {
                widget.onSuivant(_ctrl.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ÉTAPE 2 — Saisir le code reçu par email
// ─────────────────────────────────────────────────────────
class _EtapeCode extends StatefulWidget {
  final String  email;
  final bool    loading;
  final void Function(String code) onSuivant;
  final VoidCallback onRenvoyer;

  const _EtapeCode({
    required this.email,
    required this.loading,
    required this.onSuivant,
    required this.onRenvoyer,
  });

  @override
  State<_EtapeCode> createState() => _EtapeCodeState();
}

class _EtapeCodeState extends State<_EtapeCode> {
  // 6 champs individuels pour la saisie du code
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _focus  = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final f in _focus) f.dispose();
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _onDigit(int index, String value) {
    if (value.isEmpty) {
      // Retour arrière
      if (index > 0) _focus[index - 1].requestFocus();
      return;
    }
    // Avancer au champ suivant
    if (index < 5) _focus[index + 1].requestFocus();

    // Si tous remplis → valider automatiquement
    if (_code.length == 6) widget.onSuivant(_code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Titre(
          icone:    Icons.sms_outlined,
          titre:    'Vérifiez votre boîte mail',
          sousTitre: 'Un code à 6 chiffres a été envoyé à\n${widget.email}',
        ),
        const SizedBox(height: 32),

        // Champs code
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            return Container(
              width: 44, height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextFormField(
                controller:   _ctrls[i],
                focusNode:    _focus[i],
                textAlign:    TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength:    1,
                style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText:  '',
                  filled:       true,
                  fillColor:    AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   const BorderSide(
                        color: AppColors.primaryPink, width: 2),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => _onDigit(i, v),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),
        _ResetBouton(
          label:   'Vérifier le code',
          loading: widget.loading,
          onTap:   () {
            if (_code.length == 6) widget.onSuivant(_code);
          },
        ),

        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: widget.loading ? null : widget.onRenvoyer,
            child: const Text(
              'Renvoyer le code',
              style: TextStyle(
                fontSize: 13,
                color:    AppColors.primaryPinkSoft,
                decoration:      TextDecoration.underline,
                decorationColor: AppColors.primaryPinkSoft,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// ÉTAPE 3 — Saisir le nouveau mot de passe
// ─────────────────────────────────────────────────────────
class _EtapeNouveauMdp extends StatefulWidget {
  final bool loading;
  final void Function(String mdp) onValider;
  const _EtapeNouveauMdp({required this.loading, required this.onValider});

  @override
  State<_EtapeNouveauMdp> createState() => _EtapeNouveauMdpState();
}

class _EtapeNouveauMdpState extends State<_EtapeNouveauMdp> {
  final _formKey   = GlobalKey<FormState>();
  final _mdpCtrl   = TextEditingController();
  final _mdp2Ctrl  = TextEditingController();
  bool  _visible   = false;

  @override
  void dispose() { _mdpCtrl.dispose(); _mdp2Ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Titre(
            icone:    Icons.lock_reset_rounded,
            titre:    'Nouveau mot de passe',
            sousTitre: 'Choisissez un mot de passe sécurisé d\'au moins 6 caractères.',
          ),
          const SizedBox(height: 28),

          _ResetLabel('Nouveau mot de passe'),
          const SizedBox(height: 6),
          _ResetField(
            controller: _mdpCtrl,
            hint:       '••••••••',
            icone:      Icons.lock_outline_rounded,
            obscure:    !_visible,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _visible = !_visible),
              child: Icon(
                _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: AppColors.textMuted,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requis';
              if (v.length < 6) return '6 caractères minimum';
              return null;
            },
          ),

          const SizedBox(height: 14),
          _ResetLabel('Confirmer le mot de passe'),
          const SizedBox(height: 6),
          _ResetField(
            controller: _mdp2Ctrl,
            hint:       '••••••••',
            icone:      Icons.lock_outline_rounded,
            obscure:    !_visible,
            validator: (v) {
              if (v != _mdpCtrl.text) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),

          const SizedBox(height: 32),
          _ResetBouton(
            label:   'Enregistrer le mot de passe',
            loading: widget.loading,
            onTap:   () {
              if (_formKey.currentState!.validate()) {
                widget.onValider(_mdpCtrl.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ÉTAPE 4 — Succès
// ─────────────────────────────────────────────────────────
class _EtapeSucces extends StatelessWidget {
  final VoidCallback onRetour;
  const _EtapeSucces({required this.onRetour});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color:  const Color(0x1525D366),
            shape:  BoxShape.circle,
            border: Border.all(color: const Color(0x4425D366), width: 2),
          ),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF25D366), size: 52),
        ),
        const SizedBox(height: 28),
        const Text(
          'Mot de passe réinitialisé !',
          style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Votre mot de passe a été mis à jour.\nVous pouvez maintenant vous connecter avec vos nouveaux identifiants.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _ResetBouton(
          label:   'Retour à la connexion',
          loading: false,
          onTap:   onRetour,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGETS LOCAUX PARTAGÉS
// ─────────────────────────────────────────────────────────

class _IndicateurEtapes extends StatelessWidget {
  final int etape;
  const _IndicateurEtapes({required this.etape});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final n      = i + 1;
        final actif  = n == etape;
        final fait   = n < etape;
        final color  = (actif || fait) ? AppColors.primaryPink : AppColors.divider;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color:        color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: 6),
          ]),
        );
      }),
    );
  }
}

class _Titre extends StatelessWidget {
  final IconData icone;
  final String   titre;
  final String   sousTitre;
  const _Titre({required this.icone, required this.titre, required this.sousTitre});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        AppColors.primaryPink.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icone, color: AppColors.primaryPink, size: 28),
        ),
        const SizedBox(height: 16),
        Text(titre,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(sousTitre,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
      ],
    );
  }
}

class _ResetLabel extends StatelessWidget {
  final String text;
  const _ResetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: AppColors.textSecondary));
}

class _ResetField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final IconData                   icone;
  final TextInputType              clavier;
  final bool                       obscure;
  final Widget?                    suffixIcon;
  final String? Function(String?)? validator;

  const _ResetField({
    required this.controller,
    required this.hint,
    required this.icone,
    this.clavier    = TextInputType.text,
    this.obscure    = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   controller,
    keyboardType: clavier,
    obscureText:  obscure,
    validator:    validator,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText:   hint,
      hintStyle:  const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icone, size: 18, color: AppColors.textMuted),
      suffixIcon: suffixIcon,
      filled:     true,
      fillColor:  AppColors.surface,
      errorStyle: const TextStyle(color: Color(0xFFFF5252), fontSize: 11),
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
        borderSide:   const BorderSide(
            color: AppColors.primaryPink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:   const BorderSide(color: Color(0xFFFF5252)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
  );
}

class _ResetBouton extends StatelessWidget {
  final String       label;
  final bool         loading;
  final VoidCallback onTap;
  const _ResetBouton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedContainer(
      duration:  const Duration(milliseconds: 200),
      width:     double.infinity,
      padding:   const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        gradient: loading
            ? null
            : const LinearGradient(
                colors: [Color(0xFFFF5DA8), Color(0xFFB68DFF)]),
        color:        loading ? AppColors.surfaceElevated : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading ? null : [
          BoxShadow(
            color:      AppColors.primaryPink.withOpacity(0.28),
            blurRadius: 18, offset: const Offset(0, 5),
          ),
        ],
      ),
      child: loading
          ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryPink)),
              SizedBox(width: 10),
              Text('Chargement…',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            ])
          : Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
    ),
  );
}

class _ErreurBandeau extends StatelessWidget {
  final String message;
  const _ErreurBandeau({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        const Color(0x22FF5252),
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: const Color(0x55FF5252)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12))),
    ]),
  );
}
