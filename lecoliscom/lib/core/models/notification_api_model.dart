// lib/core/models/notification_api_model.dart

class NotificationApiModel {
  final String  id;
  final String  type;   // SYSTEME | ADMIN | ABONNEMENT | PUBLICATION
  final String  titre;
  final String  message;
  final bool    lue;
  final DateTime date;

  NotificationApiModel({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    required this.lue,
    required this.date,
  });

  factory NotificationApiModel.fromJson(Map<String, dynamic> j) =>
      NotificationApiModel(
        id:      j['id'],
        type:    j['type'] ?? 'SYSTEME',
        titre:   j['titre'],
        message: j['message'],
        lue:     j['lue'] ?? false,
        date:    DateTime.parse(j['createdAt']),
      );
}