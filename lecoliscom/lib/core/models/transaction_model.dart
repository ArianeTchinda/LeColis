
enum TransactionStatus { succes, enAttente, echec }

class TransactionModel {
  final String id;
  final String planNom;
  final double montant;
  final DateTime date;
  final TransactionStatus statut;
  final String methodePaiement; // ex: Orange Money, MOMO, Carte

  const TransactionModel({
    required this.id,
    required this.planNom,
    required this.montant,
    required this.date,
    required this.statut,
    required this.methodePaiement,
  });
}