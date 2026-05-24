// lib/features/home/tabs/profil/screens/login_screen.dart

import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '/core/models/escort_model.dart';
import 'mot_de_passe_oublie_screen.dart';

class LoginScreen extends StatefulWidget {
  final SessionManager session;
  const LoginScreen({super.key, required this.session});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl   = TextEditingController();

  bool    _loading    = false;
  bool    _mdpVisible = false;
  String? _erreur;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erreur = null; });

    final ok = await widget.session.connecter(
      _emailCtrl.text.trim(),
      _mdpCtrl.text.trim(),
    );

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _erreur  = widget.session.derniereErreur ?? 'Erreur inconnue.';
        _loading = false;
      });
    }
  }

  void _ouvrirMotDePasseOublie() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MotDePasseOublieScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthChampLabel(text: 'Adresse email'),
          const SizedBox(height: 6),
          AuthChamp(
            controller: _emailCtrl,
            hint:       'votre@email.com',
            icone:      Icons.email_outlined,
            clavier:    TextInputType.emailAddress,
            validateur: (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),

          const SizedBox(height: 16),

          AuthChampLabel(text: 'Mot de passe'),
          const SizedBox(height: 6),
          AuthChamp(
            controller: _mdpCtrl,
            hint:       '••••••••',
            icone:      Icons.lock_outline_rounded,
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
            validateur: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              if (v.length < 6) return '6 caractères minimum';
              return null;
            },
          ),

          const SizedBox(height: 10),

          if (_erreur != null) AuthErreur(message: _erreur!),

          const SizedBox(height: 24),

          AuthBouton(
            label:   'Se connecter',
            loading: _loading,
            onTap:   _connecter,
          ),

          const SizedBox(height: 14),

          // ── Mot de passe oublié (fonctionnel) ──────────────
          Center(
            child: GestureDetector(
              onTap: _ouvrirMotDePasseOublie,
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(
                  fontSize:        13,
                  color:           AppColors.primaryPinkSoft,
                  decoration:      TextDecoration.underline,
                  decorationColor: AppColors.primaryPinkSoft,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGETS PARTAGÉS
// ─────────────────────────────────────────────────────────

class AuthChampLabel extends StatelessWidget {
  final String text;
  const AuthChampLabel({required this.text, super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
  );
}

class AuthChamp extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final IconData                   icone;
  final TextInputType              clavier;
  final bool                       obscure;
  final Widget?                    suffixIcon;
  final String? Function(String?)? validateur;

  const AuthChamp({
    required this.controller,
    required this.hint,
    required this.icone,
    this.clavier    = TextInputType.text,
    this.obscure    = false,
    this.suffixIcon,
    this.validateur,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: clavier,
      obscureText:  obscure,
      validator:    validateur,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}

class AuthErreur extends StatelessWidget {
  final String message;
  const AuthErreur({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

class AuthBouton extends StatelessWidget {
  final String       label;
  final bool         loading;
  final VoidCallback onTap;

  const AuthBouton({
    required this.label,
    required this.loading,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                Text('Connexion…',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 14)),
              ])
            : Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                )),
      ),
    );
  }
}
