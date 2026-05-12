import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/transaction_model.dart'; // Vérifie bien le chemin de ton modèle

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      // CORRECTION ICI : Remplacement de .bottom(12) par .only(bottom: 12)
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Icône selon le statut
          _buildStatusIcon(),
          const SizedBox(width: 16),
          
          // Infos transaction
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Plan ${transaction.planNom}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  "${DateFormat('dd MMM yyyy à HH:mm').format(transaction.date)} • ${transaction.methodePaiement}",
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),

          // Montant et Statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${transaction.montant.toInt()} FCFA",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              _buildStatusBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    switch (transaction.statut) {
      case TransactionStatus.succes:
        icon = Icons.check_circle_outline_rounded;
        color = Colors.green;
        break;
      case TransactionStatus.enAttente:
        icon = Icons.access_time_rounded;
        color = Colors.orange;
        break;
      case TransactionStatus.echec:
        icon = Icons.error_outline_rounded;
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color color;
    switch (transaction.statut) {
      case TransactionStatus.succes:
        text = "Réussi";
        color = Colors.green;
        break;
      case TransactionStatus.enAttente:
        text = "En attente";
        color = Colors.orange;
        break;
      case TransactionStatus.echec:
        text = "Échoué";
        color = Colors.red;
        break;
    }
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}