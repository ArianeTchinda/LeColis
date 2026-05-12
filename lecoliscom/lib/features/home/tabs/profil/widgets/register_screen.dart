// lib/features/home/tabs/profil/screens/register_screen.dart

import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '/core/models/escort_model.dart';

class RegisterScreen extends StatefulWidget {
  final SessionManager session;
  final VoidCallback   onInscrit; // bascule vers login après succès

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

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptCGU) {
      setState(() => _erreur = 'Vous devez accepter les conditions d\'utilisation.');
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

    if (ok) {
      // Inscription réussie → le SessionManager notifie → dashboard s'affiche
    } else {
      setState(() {
        _erreur  = 'Une erreur est survenue. Réessayez.';
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
              if (v != _mdpCtrl.text) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // CGU
          GestureDetector(
            onTap: () => setState(() => _acceptCGU = !_acceptCGU),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:  22, height: 22,
                decoration: BoxDecoration(
                  color:        _acceptCGU
                      ? AppColors.primaryPink
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border:       Border.all(
                    color: _acceptCGU
                        ? AppColors.primaryPink
                        : AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: _acceptCGU
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'J\'accepte les conditions d\'utilisation',
                  style: TextStyle(
                    fontSize: 12,
                    color:    AppColors.textSecondary,
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 10),

          if (_erreur != null) ...[
            _ErreurWidget(message: _erreur!),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 8),

          // Bouton
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
// WIDGETS LOCAUX
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
      prefixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
        borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF5252))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
  );
}

class _ErreurWidget extends StatelessWidget {
  final String message;
  const _ErreurWidget({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0x22FF5252),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x55FF5252))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
        style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12))),
    ]),
  );
}

class _BoutonGradient extends StatelessWidget {
  final String label; final bool loading; final VoidCallback onTap;
  const _BoutonGradient({required this.label, required this.loading, required this.onTap});
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
        color: loading ? AppColors.surfaceElevated : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading ? null : [BoxShadow(
          color: AppColors.primaryPink.withOpacity(0.28),
          blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: loading
        ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primaryPink)),
            SizedBox(width: 10),
            Text('Création…', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ])
        : Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
    ),
  );
}