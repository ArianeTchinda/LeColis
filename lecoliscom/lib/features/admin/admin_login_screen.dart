// lib/features/admin/admin_login_screen.dart
//
// Accessible uniquement via l'URL : /lecolis-admin-2025
// Les utilisateurs normaux n'ont aucun lien vers cette page.
//
// Intégration dans main.dart / router :
//   GoRouter : path: '/${AdminSession.secretSlug}'
//   ou Navigator nommé : '/lecolis-admin-2025'

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/admin_models.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl   = TextEditingController();

  bool    _loading    = false;
  bool    _mdpVisible = false;
  String? _erreur;

  final AdminSession _session = AdminSession();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erreur = null; });

    final ok = await _session.connecter(
      _emailCtrl.text.trim(),
      _mdpCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      setState(() {
        _erreur  = 'Identifiants incorrects.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo / titre ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB68DFF).withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFFB68DFF),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Administration',
                  style: TextStyle(
                    fontSize:   28,
                    fontWeight: FontWeight.w800,
                    color:      AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'LeColis — Panneau de contrôle',
                  style: TextStyle(
                    fontSize: 13,
                    color:    AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Formulaire ──
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AdminLabel('Email administrateur'),
                      const SizedBox(height: 6),
                      _AdminField(
                        controller: _emailCtrl,
                        hint:       'admin@lecolis.cm',
                        icon:       Icons.email_outlined,
                        clavier:    TextInputType.emailAddress,
                        validator:  (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (!v.contains('@')) return 'Email invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _AdminLabel('Mot de passe'),
                      const SizedBox(height: 6),
                      _AdminField(
                        controller:  _mdpCtrl,
                        hint:        '••••••••',
                        icon:        Icons.lock_outline_rounded,
                        obscure:     !_mdpVisible,
                        suffixIcon:  GestureDetector(
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
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Erreur
                      if (_erreur != null)
                        Container(
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
                            Expanded(child: Text(_erreur!,
                                style: const TextStyle(
                                    color: Color(0xFFFF5252), fontSize: 12))),
                          ]),
                        ),

                      const SizedBox(height: 24),

                      // Bouton
                      GestureDetector(
                        onTap: _loading ? null : _connecter,
                        child: AnimatedContainer(
                          duration:    const Duration(milliseconds: 200),
                          width:       double.infinity,
                          padding:     const EdgeInsets.symmetric(vertical: 15),
                          decoration:  BoxDecoration(
                            gradient: _loading
                                ? null
                                : const LinearGradient(
                                    colors: [Color(0xFFB68DFF), Color(0xFF8A5BFF)]),
                            color:        _loading ? AppColors.surfaceElevated : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _loading ? null : [
                              BoxShadow(
                                color:      const Color(0xFFB68DFF).withOpacity(0.30),
                                blurRadius: 18,
                                offset:     const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _loading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFB68DFF))),
                                    SizedBox(width: 10),
                                    Text('Connexion…',
                                        style: TextStyle(
                                            color: AppColors.textMuted, fontSize: 14)),
                                  ])
                              : const Text(
                                  'Accéder au panneau',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:      Colors.white,
                                    fontSize:   15,
                                    fontWeight: FontWeight.w700,
                                  )),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  'Accès réservé. Toute tentative non autorisée est enregistrée.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color:    AppColors.textMuted.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets locaux ────────────────────────────────────────

class _AdminLabel extends StatelessWidget {
  final String text;
  const _AdminLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w500,
      color: AppColors.textSecondary));
}

class _AdminField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final IconData                   icon;
  final TextInputType              clavier;
  final bool                       obscure;
  final Widget?                    suffixIcon;
  final String? Function(String?)? validator;

  const _AdminField({
    required this.controller,
    required this.hint,
    required this.icon,
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
      hintText:    hint,
      hintStyle:   const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
          borderSide: const BorderSide(color: Color(0xFFB68DFF), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF5252))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
  );
}