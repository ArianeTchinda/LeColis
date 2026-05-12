import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/abonnement_model.dart';

class PlanCard extends StatelessWidget {
  final PlanAbonnement plan;
  final bool isActuel;
  final bool estConnecte;
  final VoidCallback onSelect;

  const PlanCard({
    super.key,
    required this.plan,
    this.isActuel = false,
    this.estConnecte = true,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.nom.toLowerCase() == 'premium';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActuel 
              ? plan.accentColor 
              : isPremium ? plan.accentColor.withOpacity(0.5) : AppColors.divider,
          width: (isPremium || isActuel) ? 2 : 1,
        ),
        boxShadow: isPremium ? [
          BoxShadow(
            color: plan.accentColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header coloré avec icône et badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: plan.accentColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(plan.icone, color: plan.accentColor, size: 28),
                if (isActuel)
                  _buildBadge("ACTIF", Colors.green)
                else if (isPremium)
                  _buildBadge("RECOMMANDÉ", plan.accentColor),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.nom,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.description,
                  style: const TextStyle(
                    fontSize: 13, 
                    color: AppColors.textSecondary, 
                    height: 1.4
                  ),
                ),
                const SizedBox(height: 20),
                
                // Prix avec formatage spécifique
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.prix == 0 ? "Gratuit" : "${plan.prix.toInt()} FCFA",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: plan.prix == 0 ? AppColors.textPrimary : plan.accentColor,
                      ),
                    ),
                    if (plan.prix > 0)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4, left: 4),
                        child: Text("/mois", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1),
                ),

                // Liste des avantages (mapping dynamique)
                ...plan.avantages.map((avantage) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 18, color: plan.accentColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          avantage, 
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)
                        )
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 30),

                // Bouton d'action avec correction BorderSide
                _buildActionButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color, 
          fontSize: 10, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 0.5
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (!estConnecte) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "Connectez-vous pour souscrire", 
            style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onSelect,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActuel ? Colors.transparent : plan.accentColor,
          foregroundColor: isActuel ? plan.accentColor : Colors.white,
          elevation: isActuel ? 0 : 2,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            // CORRECTION APPLIQUÉE ICI : BorderSide au lieu de Border.all
            side: isActuel 
                ? BorderSide(color: plan.accentColor, width: 1.5) 
                : BorderSide.none,
          ),
        ),
        child: Text(
          isActuel ? "RENOUVELER LE PLAN" : "CHOISIR CE PLAN",
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
    );
  }
}