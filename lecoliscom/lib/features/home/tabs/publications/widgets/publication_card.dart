// lib/features/home/tabs/publications/widgets/publication_card.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/publication_model.dart';
import '../screens/publication_detail_screen.dart';

class PublicationCard extends StatefulWidget {
  final PublicationModel publication;
  final List<PublicationModel> allPublications;
  final VoidCallback? onTap;

  const PublicationCard({
    super.key,
    required this.publication,
    required this.allPublications,
    this.onTap,
  });

  @override
  State<PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard> {
  bool _hovered = false;

  void _openDetail() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PublicationDetailScreen(
          publication: widget.publication,
          allPublications: widget.allPublications,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pub = widget.publication;

    final content = _CardContent(
      publication: pub,
      hovered: _hovered,
    );

    if (kIsWeb) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _openDetail,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(0.0, _hovered ? -8.0 : 0.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: pub.planType.color.withOpacity(0.35),
                        blurRadius: 32,
                        spreadRadius: 2,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: content,
          ),
        ),
      );
    }

    // Mobile / iOS / Android
    return GestureDetector(
      onTap: _openDetail,
      child: content,
    );
  }
}

// ─────────────────────────────────────────────────────────
// Contenu visuel — image plein format + overlays
// ─────────────────────────────────────────────────────────
class _CardContent extends StatelessWidget {
  final PublicationModel publication;
  final bool hovered;

  const _CardContent({required this.publication, this.hovered = false});

  @override
  Widget build(BuildContext context) {
    final pub = publication;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // ── IMAGE PLEIN FORMAT (ratio portrait 3/4) ──
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Hero(
              tag: 'pub_hero_${pub.id}',
              child: Image.network(
                pub.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceElevated,
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: AppColors.textMuted,
                    size: 40,
                  ),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.surfaceElevated,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── DÉGRADÉ HAUT (pour lisibilité badges) ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC060610), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── DÉGRADÉ BAS (titre + footer) ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xF0060610), Color(0x00060610)],
                ),
              ),
            ),
          ),

          // ── OVERLAY HOVER (web) ──
          if (hovered)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: pub.planType.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // ── BADGE PLAN — haut gauche ──
          Positioned(
            top: 10, left: 10,
            child: _PlanBadge(planType: pub.planType),
          ),

          // ── CATÉGORIE — haut droite ──
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Text(
                pub.categorie,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // ── BADGE NB PHOTOS — bas droite (si plusieurs images) ──
          if (pub.imageUrls.length > 1)
            Positioned(
              bottom: 68, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        size: 10, color: Colors.white70),
                    const SizedBox(width: 3),
                    Text(
                      '${pub.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── TITRE ──
          Positioned(
            bottom: 42, left: 12, right: 12,
            child: Text(
              pub.titre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
                shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
              ),
            ),
          ),

          // ── FOOTER : avatar + pseudo + tarif ──
          Positioned(
            bottom: 10, left: 12, right: 12,
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: pub.planType.color, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      pub.escortImageProfil,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.person,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Pseudo + vérifié
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          pub.escortPseudo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (pub.estVerifie) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF5DB8FF), size: 11),
                      ],
                    ],
                  ),
                ),

                // Tarif
                if (pub.tarif != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pub.tarif!.toStringAsFixed(0)} F',
                      style: TextStyle(
                        color: pub.planType.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── OVERLAY INDISPONIBLE ──
          if (!pub.estDisponible)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'INDISPONIBLE',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
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
// Badge plan
// ─────────────────────────────────────────────────────────
class _PlanBadge extends StatelessWidget {
  final PlanType planType;
  const _PlanBadge({required this.planType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: planType.color.withOpacity(0.90),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: planType.color.withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (planType == PlanType.premium)
            const Icon(Icons.star_rounded, color: Colors.white, size: 10),
          if (planType == PlanType.premium) const SizedBox(width: 3),
          Text(
            planType.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}