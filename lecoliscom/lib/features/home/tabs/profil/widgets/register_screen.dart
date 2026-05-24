
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../../../core/constants/app_colors.dart';
import '/core/models/escort_model.dart';

class RegisterScreen extends StatefulWidget {
  final SessionManager session;
  final VoidCallback   onInscrit;

  const RegisterScreen({
    super.key,
    required this.session,
    required this.onInscrit,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _pseudoCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _mdpCtrl    = TextEditingController();
  final _mdp2Ctrl   = TextEditingController();

  bool    _mdpVisible = false;
  bool    _loading    = false;
  bool    _acceptCGU  = false;
  String? _erreur;

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _mdpCtrl.dispose();
    _mdp2Ctrl.dispose();
    super.dispose();
  }

  // ── Ouvre la dialog des CGU ───────────────────────────────
  Future<void> _afficherCGU() async {
    final accepte = await showModalBottomSheet<bool>(
      context:          context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:          (_) => const _DialogCGU(),
    );
    if (accepte == true) setState(() => _acceptCGU = true);
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptCGU) {
      setState(() => _erreur =
          'Vous devez accepter les conditions d\'utilisation pour continuer.');
      return;
    }

    setState(() { _loading = true; _erreur = null; });

    final ok = await widget.session.inscrire(
      pseudo:     _pseudoCtrl.text.trim(),
      email:      _emailCtrl.text.trim(),
      telephone:  '+237${_telCtrl.text.trim()}',
      motDePasse: _mdpCtrl.text.trim(),
    );

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _erreur  = widget.session.derniereErreur ?? 'Erreur inconnue.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pseudo
          _Label('Pseudo / Nom de scène'),
          const SizedBox(height: 6),
          _Field(
            controller: _pseudoCtrl,
            hint:       'Sofia_M',
            icon:       Icons.person_outline_rounded,
            validator:  (v) => (v == null || v.trim().length < 3)
                ? '3 caractères minimum' : null,
          ),
          const SizedBox(height: 14),

          // Email
          _Label('Adresse email'),
          const SizedBox(height: 6),
          _Field(
            controller: _emailCtrl,
            hint:       'votre@email.com',
            icon:       Icons.email_outlined,
            keyboard:   TextInputType.emailAddress,
            validator:  (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Téléphone
          _Label('Numéro de téléphone'),
          const SizedBox(height: 6),
          _Field(
            controller:  _telCtrl,
            hint:        '6XX XXX XXX',
            icon:        Icons.phone_outlined,
            keyboard:    TextInputType.phone,
            prefixText:  '+237 ',
            validator:   (v) {
              if (v == null || v.trim().isEmpty) return 'Numéro requis';
              if (v.trim().replaceAll(' ', '').length < 8)
                return 'Numéro invalide';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Mot de passe
          _Label('Mot de passe'),
          const SizedBox(height: 6),
          _Field(
            controller: _mdpCtrl,
            hint:       '••••••••',
            icon:       Icons.lock_outline_rounded,
            obscure:    !_mdpVisible,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _mdpVisible = !_mdpVisible),
              child: Icon(
                _mdpVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
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

          // Confirmation mdp
          _Label('Confirmer le mot de passe'),
          const SizedBox(height: 6),
          _Field(
            controller: _mdp2Ctrl,
            hint:       '••••••••',
            icon:       Icons.lock_outline_rounded,
            obscure:    !_mdpVisible,
            validator:  (v) {
              if (v != _mdpCtrl.text)
                return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Case CGU (cliquable pour ouvrir les CGU) ───────
          GestureDetector(
            onTap: () => setState(() => _acceptCGU = !_acceptCGU),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color:        _acceptCGU
                          ? AppColors.primaryPink : AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border:       Border.all(
                        color: _acceptCGU
                            ? AppColors.primaryPink : AppColors.divider,
                        width: 1.5,
                      ),
                    ),
                    child: _acceptCGU
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary,
                          height: 1.5),
                      children: [
                        const TextSpan(text: 'J\'ai lu et j\'accepte les '),
                        TextSpan(
                          text: 'conditions d\'utilisation',
                          style: const TextStyle(
                            color:           AppColors.primaryPinkSoft,
                            decoration:      TextDecoration.underline,
                            decorationColor: AppColors.primaryPinkSoft,
                            fontWeight:      FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _afficherCGU,
                        ),
                        const TextSpan(
                          text: ', dont la confirmation que j\'ai '
                                '18 ans ou plus.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (_erreur != null) ...[
            _ErreurWidget(message: _erreur!),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 8),

          _BoutonGradient(
            label:   'Créer mon compte',
            loading: _loading,
            onTap:   _inscrire,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// DIALOG CGU — BottomSheet scrollable
// ─────────────────────────────────────────────────────────
class _DialogCGU extends StatefulWidget {
  const _DialogCGU();

  @override
  State<_DialogCGU> createState() => _DialogCGUState();
}

class _DialogCGUState extends State<_DialogCGU> {
  final _scroll    = ScrollController();
  bool  _luJusquau = false; // activé quand on a scrollé jusqu'en bas

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.atEdge && _scroll.position.pixels > 0) {
        if (!_luJusquau) setState(() => _luJusquau = true);
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:      MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titre
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        AppColors.primaryPink.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gavel_rounded,
                    color: AppColors.primaryPink, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conditions d\'utilisation',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  Text('À lire attentivement avant de vous inscrire',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ]),
          ),

          const Divider(height: 1),

          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: const _ContenuCGU(),
            ),
          ),

          const Divider(height: 1),

          // Boutons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              children: [
                if (!_luJusquau)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 6),
                      const Text('Faites défiler jusqu\'en bas pour accepter',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ]),
                  ),

                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:        AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border:       Border.all(color: AppColors.divider),
                        ),
                        child: const Text('Refuser',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color:      AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _luJusquau
                          ? () => Navigator.pop(context, true)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _luJusquau
                              ? const LinearGradient(colors: [
                                  Color(0xFFFF5DA8), Color(0xFFB68DFF)])
                              : null,
                          color: _luJusquau
                              ? null : AppColors.divider,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'J\'accepte',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _luJusquau
                                ? Colors.white : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CONTENU DES CGU
// ─────────────────────────────────────────────────────────
class _ContenuCGU extends StatelessWidget {
  const _ContenuCGU();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _CGUSection(
          numero: '1',
          titre:  'Âge minimum obligatoire',
          contenu:
              'En vous inscrivant sur LeColis, vous certifiez avoir au moins 18 ans '
              '(ou l\'âge de la majorité légale dans votre pays si celui-ci est '
              'supérieur à 18 ans). Toute inscription frauduleuse d\'une personne '
              'mineure entraînera la suppression immédiate et définitive du compte, '
              'ainsi que le signalement aux autorités compétentes si nécessaire.',
        ),
        _CGUSection(
          numero: '2',
          titre:  'Nature expérimentale de la plateforme',
          contenu:
              'LeColis est une plateforme à titre expérimental. Elle est en cours '
              'de développement actif et peut comporter des bugs, des interruptions '
              'de service ou des modifications sans préavis. L\'utilisation se fait '
              'en connaissance de cause et à vos risques.',
        ),
        _CGUSection(
          numero: '3',
          titre:  'Responsabilité personnelle et sécurité',
          contenu:
              'Chaque utilisateur est seul responsable de sa sécurité personnelle, '
              'de ses rencontres et de ses interactions sur la plateforme. LeColis '
              'ne peut en aucun cas être tenu responsable des conséquences directes '
              'ou indirectes liées à une rencontre, une transaction ou un échange '
              'initié via la plateforme. Prenez toutes les précautions nécessaires '
              'et ne partagez jamais d\'informations sensibles avec des inconnus.',
        ),
        _CGUSection(
          numero: '4',
          titre:  'Faux comptes et usurpation d\'identité',
          contenu:
              'Toute création de faux compte, usurpation d\'identité ou utilisation '
              'de photos ne vous appartenant pas est strictement interdite. Les '
              'comptes identifiés comme frauduleux seront bannis définitivement sans '
              'préavis. Des signalements répétés d\'un compte entraîneront sa '
              'suppression par l\'administrateur sans possibilité de recours.',
        ),
        _CGUSection(
          numero: '5',
          titre:  'Politique de sanctions',
          contenu:
              'LeColis applique une politique de tolérance zéro envers :\n'
              '• Les comptes signalés à plusieurs reprises par la communauté\n'
              '• Les comportements abusifs, harcelants ou menaçants\n'
              '• Les contenus illégaux ou impliquant des mineurs\n'
              '• Le spam ou la publicité non autorisée\n\n'
              'Les sanctions peuvent aller de l\'avertissement au bannissement '
              'définitif, à la discrétion de l\'équipe d\'administration.',
        ),
        _CGUSection(
          numero: '6',
          titre:  'Contenu et publications',
          contenu:
              'Tout contenu publié sur LeColis doit respecter la législation en '
              'vigueur. Les publications contenant des images de mineurs, du contenu '
              'non consenti ou des informations fausses seront supprimées '
              'immédiatement. Vous êtes seul responsable du contenu que vous publiez.',
        ),
        _CGUSection(
          numero: '7',
          titre:  'Confidentialité des données',
          contenu:
              'Vos données personnelles (email, téléphone) sont utilisées '
              'uniquement pour le fonctionnement de la plateforme. Elles ne sont '
              'pas vendues à des tiers. Vos photos sont stockées de façon sécurisée '
              'et accessibles uniquement selon vos paramètres de visibilité.',
        ),
        _CGUSection(
          numero: '8',
          titre:  'Modification des conditions',
          contenu:
              'LeColis se réserve le droit de modifier ces conditions à tout moment. '
              'La continuation de l\'utilisation de la plateforme après modification '
              'vaut acceptation des nouvelles conditions.',
        ),
        SizedBox(height: 8),
        _CGUAvertissement(),
      ],
    );
  }
}

class _CGUSection extends StatelessWidget {
  final String numero;
  final String titre;
  final String contenu;
  const _CGUSection({
    required this.numero,
    required this.titre,
    required this.contenu,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 26, height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:  AppColors.primaryPink.withOpacity(0.12),
                shape:  BoxShape.circle,
              ),
              child: Text(numero,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: AppColors.primaryPink)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(titre,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(contenu,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary,
                    height: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _CGUAvertissement extends StatelessWidget {
  const _CGUAvertissement();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        const Color(0x22FFB800),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0x44FFB800)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB800), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'En cliquant sur "J\'accepte", vous confirmez avoir lu l\'intégralité '
              'de ces conditions, avoir au moins 18 ans, et vous engagez à respecter '
              'ces règles. Tout manquement peut entraîner la suppression de votre compte.',
              style: TextStyle(
                fontSize: 12, color: Color(0xFFFFB800), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGETS LOCAUX DU FORMULAIRE
// ─────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: AppColors.textSecondary));
}

class _Field extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final IconData                   icon;
  final TextInputType              keyboard;
  final bool                       obscure;
  final Widget?                    suffixIcon;
  final String?                    prefixText;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboard   = TextInputType.text,
    this.obscure    = false,
    this.suffixIcon,
    this.prefixText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   controller,
    keyboardType: keyboard,
    obscureText:  obscure,
    validator:    validator,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText:    hint,
      hintStyle:   const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixText:  prefixText,
      prefixStyle: const TextStyle(
          color: AppColors.textSecondary, fontSize: 14),
      prefixIcon:  Icon(icon, size: 18, color: AppColors.textMuted),
      suffixIcon:  suffixIcon,
      filled:      true,
      fillColor:   AppColors.surface,
      errorStyle:  const TextStyle(color: Color(0xFFFF5252), fontSize: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppColors.primaryPink, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF5252))),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 13),
    ),
  );
}

class _ErreurWidget extends StatelessWidget {
  final String message;
  const _ErreurWidget({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        const Color(0x22FF5252),
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: const Color(0x55FF5252)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded,
          color: Color(0xFFFF5252), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: const TextStyle(
              color: Color(0xFFFF5252), fontSize: 12))),
    ]),
  );
}

class _BoutonGradient extends StatelessWidget {
  final String label; final bool loading; final VoidCallback onTap;
  const _BoutonGradient({
    required this.label,
    required this.loading,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        gradient: loading ? null : const LinearGradient(
            colors: [Color(0xFFFF5DA8), Color(0xFFB68DFF)]),
        color:        loading ? AppColors.surfaceElevated : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading ? null : [BoxShadow(
          color:      AppColors.primaryPink.withOpacity(0.28),
          blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: loading
          ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryPink)),
              SizedBox(width: 10),
              Text('Création…', style: TextStyle(
                  color: AppColors.textMuted, fontSize: 14)),
            ])
          : Text(label, textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w700)),
    ),
  );
}
