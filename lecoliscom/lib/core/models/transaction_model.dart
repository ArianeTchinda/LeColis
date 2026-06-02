// lib/core/models/transaction_model.dart

import 'package:flutter/material.dart';

enum TransactionStatus { succes, enAttente, echec }

extension TransactionStatusExt on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.succes: return 'Réussi';
      case TransactionStatus.enAttente: return 'En attente';
      case TransactionStatus.echec: return 'Échoué';
    }
  }

  Color get couleur {
    switch (this) {
      case TransactionStatus.succes: return const Color(0xFF25D366);
      case TransactionStatus.enAttente: return const Color(0xFFFFB800);
      case TransactionStatus.echec: return const Color(0xFFFF5252);
    }
  }

  IconData get icone {
    switch (this) {
      case TransactionStatus.succes: return Icons.check_circle_rounded;
      case TransactionStatus.enAttente: return Icons.hourglass_top_rounded;
      case TransactionStatus.echec: return Icons.error_outline_rounded;
    }
  }
}

class TransactionModel {
  final String id;
  final String planNom;
  final double montant;
  final DateTime date;
  final TransactionStatus statut;
  final String methodePaiement;

  const TransactionModel({
    required this.id,
    required this.planNom,
    required this.montant,
    required this.date,
    required this.statut,
    required this.methodePaiement,
  });

  // 🔥 AJOUTÉ : fromJson
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      planNom: json['planNom'] ?? json['plan']?['nom'] ?? 'Inconnu',
      montant: (json['montant'] ?? 0).toDouble(),
      date: DateTime.parse(
          json['createdAt'] ?? json['date'] ?? DateTime.now().toIso8601String()),
      statut: _parseStatut(json['statut']),
      methodePaiement: json['methodePaiement'] ?? json['methode'] ?? 'TaraMoney',
    );
  }

  static TransactionStatus _parseStatut(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUCCES':
      case 'SUCCESS':
        return TransactionStatus.succes;
      case 'EN_ATTENTE':
      case 'ENATTENTE':
        return TransactionStatus.enAttente;
      case 'ECHEC':
      case 'FAILED':
        return TransactionStatus.echec;
      default:
        return TransactionStatus.enAttente;
    }
  }
}