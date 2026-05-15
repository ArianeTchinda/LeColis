// lib/core/models/transaction_model.dart

import 'package:flutter/material.dart';

enum TransactionStatus { succes, enAttente, echec }

extension TransactionStatusExt on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.succes:    return 'Réussi';
      case TransactionStatus.enAttente: return 'En attente';
      case TransactionStatus.echec:     return 'Échoué';
    }
  }

  Color get couleur {
    switch (this) {
      case TransactionStatus.succes:    return const Color(0xFF25D366);
      case TransactionStatus.enAttente: return const Color(0xFFFFB800);
      case TransactionStatus.echec:     return const Color(0xFFFF5252);
    }
  }

  IconData get icone {
    switch (this) {
      case TransactionStatus.succes:    return Icons.check_circle_rounded;
      case TransactionStatus.enAttente: return Icons.hourglass_top_rounded;
      case TransactionStatus.echec:     return Icons.error_outline_rounded;
    }
  }
}

class TransactionModel {
  final String            id;
  final String            planNom;
  final double            montant;
  final DateTime          date;
  final TransactionStatus statut;
  final String            methodePaiement;

  const TransactionModel({
    required this.id,
    required this.planNom,
    required this.montant,
    required this.date,
    required this.statut,
    required this.methodePaiement,
  });
}