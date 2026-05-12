// lib/features/home/tabs/profil/profil_tab.dart
//
// Routeur principal du tab Profil :
//  - Non connecté → _AuthView (login + register)
//  - Connecté     → ProfilDashboard

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '/core/models/escort_model.dart';
import 'widgets/login_screen.dart';
import 'widgets/register_screen.dart';
import 'screens/profil_dashboard_screen.dart';

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  final SessionManager _session = SessionManager();

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChange);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChange);
    super.dispose();
  }

  void _onSessionChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (_session.estConnecte) {
      return ProfilDashboard(
        escort:       _session.escort!,
        onDeconnexion: () => _session.deconnecter(),
      );
    }

    return _AuthView(session: _session);
  }
}

// ─────────────────────────────────────────────────────────
// VUE AUTH — bascule Login / Register
// ─────────────────────────────────────────────────────────
class _AuthView extends StatefulWidget {
  final SessionManager session;
  const _AuthView({required this.session});

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (context, _) {
        final isLogin = _tabCtrl.index == 0;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 0 : 20,
                      32,
                      isWide ? 0 : 20,
                      48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Icône + titre ──
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPink.withOpacity(0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primaryPink,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Espace Escort',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Connectez-vous ou créez votre compte',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Sélecteur Login / Inscription ──
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: TabBar(
                            controller: _tabCtrl,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: AppColors.primaryPink.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: AppColors.primaryPink.withOpacity(0.35),
                              ),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicatorPadding: const EdgeInsets.all(4),
                            labelColor: AppColors.primaryPink,
                            unselectedLabelColor: AppColors.textMuted,
                            labelStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            unselectedLabelStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w400),
                            tabs: const [
                              Tab(text: 'Connexion'),
                              Tab(text: 'Inscription'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Formulaire actif ──
                        if (isLogin)
                          LoginScreen(session: widget.session)
                        else
                          RegisterScreen(
                            session: widget.session,
                            onInscrit: () => _tabCtrl.animateTo(0),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}